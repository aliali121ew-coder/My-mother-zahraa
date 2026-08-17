import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/audio_selection_bottom_sheet.dart';
import 'widgets/location_selection_sheet.dart';
import '../data/posts_repository.dart';
import '../domain/post_model.dart';

/// مسار إضافة وتعديل المنشورات الشامل على طريقة الإنستغرام الحقيقي (الصور، الموسيقى، الوصف، الموقع)
class CreatePostFlowPage extends ConsumerStatefulWidget {
  const CreatePostFlowPage({
    super.key,
    this.existingPost,
  });

  final PostModel? existingPost;

  static void navigate(BuildContext context, {PostModel? existingPost}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreatePostFlowPage(existingPost: existingPost),
      ),
    );
  }

  @override
  ConsumerState<CreatePostFlowPage> createState() => _CreatePostFlowPageState();
}

class _CreatePostFlowPageState extends ConsumerState<CreatePostFlowPage> {
  int _currentStep = 0; // 0: المعرض, 1: الفلاتر واللطميات, 2: التفاصيل والنشر
  bool _isPublishing = false;
  int _currentPreviewIndex = 0;

  // قائمة الصور الافتراضية للمعرض
  final List<String> _galleryImages = [
    'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1511632765486-a01980e01a18?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1541888946425-d0fbb186a5b7?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1532629345422-7515f3d16bb6?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1509099836639-18ba1795216d?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?auto=format&fit=crop&w=800&q=80',
  ];

  // الصور المختارة للنشر أو التعديل (تدعم حتى 10 صور)
  late List<String> _selectedImages;

  String _selectedFilterName = 'طبيعي';
  ColorFilter? _selectedColorFilter;
  String? _selectedAudioTrack;
  late final TextEditingController _captionController;
  late final TextEditingController _locationController;
  String _selectedYearTag = '2026';

  final List<_ImageFilterOption> _filters = [
    _ImageFilterOption(name: 'طبيعي', filter: null),
    _ImageFilterOption(
      name: 'كربلائي 🕌',
      filter: const ColorFilter.mode(Color(0x33D4AF37), BlendMode.colorBurn),
    ),
    _ImageFilterOption(
      name: 'فاطمي 🌸',
      filter: const ColorFilter.mode(Color(0x22E0A96D), BlendMode.softLight),
    ),
    _ImageFilterOption(
      name: 'أبيض وأسود 🖤',
      filter: const ColorFilter.matrix(<double>[
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0, 0, 0, 1, 0,
      ]),
    ),
    _ImageFilterOption(
      name: 'دافئ 🔥',
      filter: const ColorFilter.mode(Color(0x33FF9800), BlendMode.overlay),
    ),
    _ImageFilterOption(
      name: 'درامي 🎬',
      filter: const ColorFilter.mode(Color(0x441A3C40), BlendMode.darken),
    ),
  ];

  final List<String> _audioTracks = [
    'باسم الكربلائي — يابو فاضل (قصيدة فاطمية)',
    'عمار الكناني — يا زوار (خدمة العزاء)',
    'قحطان البديري — قصيدة أمنا الزهراء (ع)',
    'مرتضى حرب — ريحانة الباري',
    'محمد باقر خاقاني — عزاء الفاطمية',
    'حيدر البثالي — خدمة موكب الزهراء',
    'بدون صوت خلفي',
  ];

  final List<String> _suggestedLocations = [
    'كربلاء المقدسة — بين الحرمين الشريفين',
    'كربلاء المقدسة — شارع السدرة (مقر الموكب)',
    'كربلاء المقدسة — صحن العقيلة زينب (ع)',
    'النجف الأشرف — شارع الرسول (ص)',
    'الكاظمية المقدسة — باب المراد',
    'سامراء المقدسة — العتبة العسكرية',
    'بابل — مرقد الشريفة بنت الحسن (ع)',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingPost != null) {
      final p = widget.existingPost!;
      _selectedImages = p.images.isNotEmpty
          ? List<String>.from(p.images)
          : [_galleryImages.first];
      _selectedAudioTrack = p.audioTrackTitle ?? _audioTracks.first;
      _captionController = TextEditingController(text: p.caption);
      _locationController = TextEditingController(text: p.location ?? '');
      _selectedYearTag = p.yearTag.isNotEmpty ? p.yearTag : '2026';
    } else {
      _selectedImages = [_galleryImages.first];
      _selectedAudioTrack = _audioTracks.first;
      _captionController = TextEditingController();
      _locationController =
          TextEditingController(text: 'كربلاء المقدسة — شارع السدرة');
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار صورة واحدة على الأقل')),
      );
      return;
    }
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    } else {
      _publishPost();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  void _toggleImageSelection(String img) {
    setState(() {
      if (_selectedImages.contains(img)) {
        if (_selectedImages.length > 1) {
          _selectedImages.remove(img);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يجب إبقاء صورة واحدة على الأقل')),
          );
        }
      } else {
        if (_selectedImages.length >= 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('الحد الأقصى هو 10 صور للمنشور الواحد 📸')),
          );
        } else {
          _selectedImages.add(img);
        }
      }
    });
  }

  Future<void> _pickFromDeviceGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage(limit: 10);
      if (pickedFiles.isNotEmpty) {
        setState(() {
          final paths = pickedFiles.take(10).map((f) => f.path).toList();
          _selectedImages = paths;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('تم اختيار ${_selectedImages.length} صور من الهاتف ✨'),
              backgroundColor: AppColors.greenDeep,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر الوصول إلى معرض الصور')),
        );
      }
    }
  }

  Future<void> _publishPost() async {
    if (_isPublishing) return;
    setState(() => _isPublishing = true);

    final messenger = ScaffoldMessenger.of(context);
    final isEditing = widget.existingPost != null;

    try {
      if (isEditing) {
        await ref.read(postsProvider.notifier).updatePost(
              postId: widget.existingPost!.id,
              imageUrls: _selectedImages,
              caption: _captionController.text.trim(),
              location: _locationController.text.trim().isNotEmpty
                  ? _locationController.text.trim()
                  : null,
              yearTag: _selectedYearTag,
              audioTrackTitle: (_selectedAudioTrack == null ||
                      _selectedAudioTrack == 'بدون صوت خلفي')
                  ? null
                  : _selectedAudioTrack,
            );

        if (!mounted) return;
        Navigator.of(context).pop();

        messenger.showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تم تحديث وتعديل المنشور بالكامل بنجاح 🖤✨',
                    style: TextStyle(fontFamily: AppTheme.fontFamily),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.greenDeep,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      } else {
        final newPost = await ref.read(postsProvider.notifier).addPost(
              imageUrls: _selectedImages,
              caption: _captionController.text.trim().isEmpty
                  ? 'تغطية حسينية مصورة من مجالس ومشاريع موكب أمنا الزهراء (ع) 🖤✨'
                  : _captionController.text.trim(),
              location: _locationController.text.trim().isEmpty
                  ? 'كربلاء المقدسة — بين الحرمين الشريفين'
                  : _locationController.text.trim(),
              yearTag: _selectedYearTag,
              audioTrackTitle: (_selectedAudioTrack == null ||
                      _selectedAudioTrack == 'بدون صوت خلفي')
                  ? null
                  : _selectedAudioTrack,
            );

        if (!mounted) return;
        Navigator.of(context).pop();

        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    newPost != null
                        ? 'تم نشر التغطية (${_selectedImages.length} صور) بنجاح 🖤✨'
                        : 'تم نشر التغطية ✓',
                    style: const TextStyle(fontFamily: AppTheme.fontFamily),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.greenDeep,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'تعذر حفظ التعديلات — تحقق من الاتصال'
                : 'تعذر نشر التغطية — تحقق من الاتصال ثم أعد المحاولة',
            style: const TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.existingPost != null;

    return Scaffold(
      backgroundColor: isDark ? AppColors.greenDeepest : Colors.black,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.greenDeepest : Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            _currentStep == 0
                ? Icons.close_rounded
                : Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: _previousStep,
        ),
        title: Text(
          isEditing
              ? (_currentStep == 0
                  ? 'تعديل الصور (${_selectedImages.length}/10)'
                  : (_currentStep == 1
                      ? 'تعديل الفلاتر والموسيقى'
                      : 'حفظ التعديلات'))
              : (_currentStep == 0
                  ? 'منشور جديد (${_selectedImages.length}/10 صور)'
                  : (_currentStep == 1 ? 'التعديل واللطميات' : 'تفاصيل النشر')),
          style: const TextStyle(
            fontFamily: AppTheme.displayFamily,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.goldBright,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _nextStep,
            child: Text(
              _currentStep == 2 ? (isEditing ? 'حفظ' : 'نشر') : 'التالي',
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.gold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Progress Bar Indicator
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 3,
                    color: _currentStep >= 0 ? AppColors.gold : Colors.white24,
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 3,
                    color: _currentStep >= 1 ? AppColors.gold : Colors.white24,
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 3,
                    color: _currentStep >= 2 ? AppColors.gold : Colors.white24,
                  ),
                ),
              ],
            ),

            // Main Step Views
            Expanded(
              child: IndexedStack(
                index: _currentStep,
                children: [
                  _buildGalleryStep(isDark),
                  _buildFilterAndAudioStep(isDark),
                  _buildDetailsStep(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP 1: Gallery Image Selection (المعاينة المعرضية حتى 10 صور)
  // -------------------------------------------------------------
  Widget _buildGalleryStep(bool isDark) {
    return Column(
      children: [
        // Main Big Image Preview / Carousel
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.38,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                itemCount: _selectedImages.length,
                onPageChanged: (i) => setState(() => _currentPreviewIndex = i),
                itemBuilder: (context, idx) {
                  final img = _selectedImages[idx];
                  return _buildSingleImage(img);
                },
              ),
              if (_selectedImages.length > 1)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentPreviewIndex + 1}/${_selectedImages.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Gallery Grid Header with Device Picker Button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isDark ? Colors.black26 : Colors.grey.shade900,
          child: Row(
            children: [
              Text(
                'اختر حتى 10 صور (${_selectedImages.length}/10)',
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _pickFromDeviceGallery,
                icon: const Icon(Icons.add_photo_alternate_rounded,
                    size: 16, color: Colors.white),
                label: const Text(
                  'من الهاتف',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldDark,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Gallery Grid View
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: _galleryImages.length,
            itemBuilder: (context, index) {
              final img = _galleryImages[index];
              final isSelected = _selectedImages.contains(img);
              final selectionIndex = _selectedImages.indexOf(img);

              return GestureDetector(
                onTap: () => _toggleImageSelection(img),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildSingleImage(img),
                    if (isSelected)
                      Container(
                        color: Colors.black45,
                        child: Center(
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.gold,
                            ),
                            child: Center(
                              child: Text(
                                '${selectionIndex + 1}',
                                style: const TextStyle(
                                  color: AppColors.greenAbyss,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // STEP 2: Filters & Audio Selection
  // -------------------------------------------------------------
  Widget _buildFilterAndAudioStep(bool isDark) {
    return Column(
      children: [
        // Image Preview with Applied Filter
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
            ),
            child: Stack(
              children: [
                PageView.builder(
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, idx) {
                    final img = _selectedImages[idx];
                    return _selectedColorFilter != null
                        ? ColorFiltered(
                            colorFilter: _selectedColorFilter!,
                            child: _buildSingleImage(img),
                          )
                        : _buildSingleImage(img);
                  },
                ),
                if (_selectedImages.length > 1)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_selectedImages.length} صور',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Audio Track Selector Button
        GestureDetector(
          onTap: () async {
            final track = await AudioSelectionBottomSheet.show(context);
            if (track != null) {
              setState(() {
                _selectedAudioTrack = track;
              });
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black38 : Colors.grey.shade900,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.music_note_rounded,
                    color: AppColors.gold, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedAudioTrack != null
                        ? 'اللطمية المختارة: $_selectedAudioTrack'
                        : 'إضافة صوتية / قصيدة حسينية...',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _selectedAudioTrack != null
                          ? AppColors.goldBright
                          : Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.white70, size: 22),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Filter Options List
        SizedBox(
          height: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  'اختيار الفلتر البصري:',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12.5,
                    color: Colors.white70,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final item = _filters[index];
                    final selected = item.name == _selectedFilterName;
                    final previewImg = _selectedImages.first;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFilterName = item.name;
                          _selectedColorFilter = item.filter;
                        });
                      },
                      child: Container(
                        width: 75,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                selected ? AppColors.gold : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: item.filter != null
                                    ? ColorFiltered(
                                        colorFilter: item.filter!,
                                        child: _buildSingleImage(previewImg),
                                      )
                                    : _buildSingleImage(previewImg),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.name,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 10,
                                color: selected
                                    ? AppColors.goldBright
                                    : Colors.white70,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // -------------------------------------------------------------
  // STEP 3: Final Details & Caption (كتابة الشرح والتفاصيل والنشر)
  // -------------------------------------------------------------
  Widget _buildDetailsStep(bool isDark) {
    final isEditing = widget.existingPost != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Multi-Image Preview Horizontal Row
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 80,
                        height: 90,
                        child: _selectedColorFilter != null
                            ? ColorFiltered(
                                colorFilter: _selectedColorFilter!,
                                child: _buildSingleImage(_selectedImages[i]),
                              )
                            : _buildSingleImage(_selectedImages[i]),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          // Caption Field
          TextField(
            controller: _captionController,
            maxLines: 4,
            style: const TextStyle(
                color: Colors.white, fontFamily: AppTheme.fontFamily),
            decoration: InputDecoration(
              hintText: 'اكتب شرح التغطية أو نص المجلس هنا...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const Divider(color: Colors.white24, height: 30),

          // Audio Selected Summary
          if (_selectedAudioTrack != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  const Icon(Icons.music_note_rounded, color: AppColors.gold),
              title: const Text(
                'اللطمية المرفقة',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontFamily: AppTheme.fontFamily),
              ),
              subtitle: Text(
                _selectedAudioTrack!,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.fontFamily),
              ),
            ),

          const SizedBox(height: 10),

          // Location Selection Field
          GestureDetector(
            onTap: () async {
              final loc = await LocationSelectionSheet.show(context);
              if (loc != null) {
                setState(() {
                  _locationController.text = loc;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      color: AppColors.gold, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _locationController.text.isNotEmpty
                          ? _locationController.text
                          : 'حدد موقعاً والتغطية الحسينية...',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13.5,
                        color: _locationController.text.isNotEmpty
                            ? Colors.white
                            : Colors.white38,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white54, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _suggestedLocations.map((loc) {
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: ActionChip(
                    avatar: const Icon(Icons.place_rounded,
                        size: 14, color: AppColors.gold),
                    label: Text(loc),
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    labelStyle: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _locationController.text = loc;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Year Tag Dropdown
          const Text(
            'سنة التوثيق الحسينية',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontFamily: AppTheme.fontFamily),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedYearTag,
            dropdownColor:
                isDark ? AppColors.greenDeepest : Colors.grey.shade900,
            style: const TextStyle(
                color: Colors.white, fontFamily: AppTheme.fontFamily),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            items: ['2026', '2025', '2024', '2023']
                .map((y) => DropdownMenuItem(
                      value: y,
                      child: Text(y),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => _selectedYearTag = v);
              }
            },
          ),

          const SizedBox(height: 30),

          // Publish / Save Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _publishPost,
              icon: Icon(isEditing
                  ? Icons.check_circle_rounded
                  : Icons.publish_rounded),
              label: Text(
                isEditing
                    ? 'حفظ التعديلات (${_selectedImages.length} صور)'
                    : 'نشر التغطية الآن (${_selectedImages.length} صور)',
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.greenAbyss,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleImage(String url) {
    if (!url.startsWith('http://') &&
        !url.startsWith('https://') &&
        !url.startsWith('assets/')) {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          cacheWidth: 800,
          cacheHeight: 800,
        );
      }
    }
    if (url.startsWith('assets/')) {
      return Image.asset(url, fit: BoxFit.cover);
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      cacheWidth: 800,
      cacheHeight: 800,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey.shade900,
        child: const Icon(Icons.image, color: AppColors.gold, size: 40),
      ),
    );
  }
}

class _ImageFilterOption {
  _ImageFilterOption({required this.name, required this.filter});
  final String name;
  final ColorFilter? filter;
}
