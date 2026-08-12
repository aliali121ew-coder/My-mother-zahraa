import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/audio_selection_bottom_sheet.dart';
import 'widgets/location_selection_sheet.dart';
import '../data/mock_posts_data.dart';
import '../domain/post_model.dart';

/// مسار إضافة المنشور والتغطية الجديدة على طريقة الإنستغرام الحقيقي (سلس وسريع بدون توقف)
class CreatePostFlowPage extends ConsumerStatefulWidget {
  const CreatePostFlowPage({super.key});

  static void navigate(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CreatePostFlowPage(),
      ),
    );
  }

  @override
  ConsumerState<CreatePostFlowPage> createState() => _CreatePostFlowPageState();
}

class _CreatePostFlowPageState extends ConsumerState<CreatePostFlowPage> {
  int _currentStep = 0; // 0: المعرض, 1: الفلاتر واللطميات, 2: التفاصيل والنشر

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

  late String _selectedImage;
  String _selectedFilterName = 'طبيعي';
  ColorFilter? _selectedColorFilter;
  String? _selectedAudioTrack;
  final _captionController = TextEditingController();
  final _locationController = TextEditingController(text: 'كربلاء المقدسة — شارع السدرة');
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
        0,      0,      0,      1, 0,
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
    _selectedImage = _galleryImages.first;
    _selectedAudioTrack = _audioTracks.first;
  }

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _nextStep() {
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

  void _publishPost() {
    final caption = _captionController.text.trim();
    final location = _locationController.text.trim();
    final audioTitle = (_selectedAudioTrack == null || _selectedAudioTrack == 'بدون صوت خلفي')
        ? null
        : _selectedAudioTrack;

    final newPost = PostModel(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      publisherName: 'موكب أمنا الزهراء (ع)',
      publisherAvatar: 'assets/images/logo.png',
      isVerified: true,
      location: location.isEmpty ? 'كربلاء المقدسة — بين الحرمين الشريفين' : location,
      images: [_selectedImage],
      caption: caption.isEmpty
          ? 'تغطية حسينية مصورة من مجالس ومشاريع موكب أمنا الزهراء (ع) 🖤✨'
          : caption,
      likesCount: 1,
      commentsCount: 0,
      isLiked: true,
      isSaved: false,
      createdAt: DateTime.now(),
      yearTag: _selectedYearTag,
      audioTrackTitle: audioTitle,
    );

    ref.read(postsProvider.notifier).addPost(newPost);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'تم نشر التغطية بنجاح 🖤✨ ${audioTitle != null ? "($audioTitle)" : ""}',
                style: const TextStyle(fontFamily: AppTheme.fontFamily),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.greenDeep,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.greenDeepest : Colors.black,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.greenDeepest : Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            _currentStep == 0 ? Icons.close_rounded : Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: _previousStep,
        ),
        title: Text(
          _currentStep == 0
              ? 'منشور جديد (المعرض)'
              : (_currentStep == 1 ? 'التعديل واللطميات' : 'تفاصيل النشر'),
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
              _currentStep == 2 ? 'نشر' : 'التالي',
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
  // STEP 1: Gallery Image Selection (المعاينة المعرضية الكبيرة والشبكة)
  // -------------------------------------------------------------
  Widget _buildGalleryStep(bool isDark) {
    return Column(
      children: [
        // Main Big Image Preview
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.38,
          width: double.infinity,
          child: Image.network(
            _selectedImage,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey.shade900,
              child: const Icon(Icons.image, color: AppColors.gold, size: 50),
            ),
          ),
        ),

        // Gallery Grid Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: isDark ? Colors.black26 : Colors.grey.shade900,
          child: const Row(
            children: [
              Text(
                'صور المعرض الحديثة',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Spacer(),
              Icon(Icons.photo_library_rounded, color: AppColors.gold, size: 20),
            ],
          ),
        ),

        // Gallery Grid View with Fast Safe Load
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
              final isSelected = img == _selectedImage;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedImage = img;
                  });
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      img,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade800,
                        child: const Icon(Icons.photo, color: Colors.white38, size: 20),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        color: Colors.black45,
                        child: const Center(
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.gold,
                            size: 26,
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
  // STEP 2: Filters & Audio Selection (الفلاتر واللطميات الحسينية)
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
            child: _selectedColorFilter != null
                ? ColorFiltered(
                    colorFilter: _selectedColorFilter!,
                    child: Image.network(_selectedImage, fit: BoxFit.cover),
                  )
                : Image.network(_selectedImage, fit: BoxFit.cover),
          ),
        ),

        // Audio Track Selector Button (ينزلق الشيت السفلي الفاخر مثل الإنستغرام 3)
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
                const Icon(Icons.music_note_rounded, color: AppColors.gold, size: 22),
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
                      color: _selectedAudioTrack != null ? AppColors.goldBright : Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 22),
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
                            color: selected ? AppColors.gold : Colors.transparent,
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
                                        child: Image.network(_selectedImage, fit: BoxFit.cover),
                                      )
                                    : Image.network(_selectedImage, fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.name,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 10,
                                color: selected ? AppColors.goldBright : Colors.white70,
                                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Preview Card & Caption
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: _selectedColorFilter != null
                      ? ColorFiltered(
                          colorFilter: _selectedColorFilter!,
                          child: Image.network(_selectedImage, fit: BoxFit.cover),
                        )
                      : Image.network(_selectedImage, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: _captionController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white, fontFamily: AppTheme.fontFamily),
                  decoration: const InputDecoration(
                    hintText: 'اكتب شرح التغطية أو نص المجلس هنا...',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),

          const Divider(color: Colors.white24, height: 30),

          // Audio Selected Summary
          if (_selectedAudioTrack != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.music_note_rounded, color: AppColors.gold),
              title: const Text(
                'اللطمية المرفقة',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: AppTheme.fontFamily),
              ),
              subtitle: Text(
                _selectedAudioTrack!,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: AppTheme.fontFamily),
              ),
            ),

          const SizedBox(height: 10),

          // Location Selection Field (ينزلق الشيت السفلي الفاخر مثل الإنستغرام 4)
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
                  const Icon(Icons.location_on_outlined, color: AppColors.gold, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _locationController.text.isNotEmpty
                          ? _locationController.text
                          : 'حدد موقعاً والتغطية الحسينية...',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13.5,
                        color: _locationController.text.isNotEmpty ? Colors.white : Colors.white38,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 16),
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
                    avatar: const Icon(Icons.place_rounded, size: 14, color: AppColors.gold),
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
            style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: AppTheme.fontFamily),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedYearTag,
            dropdownColor: isDark ? AppColors.greenDeepest : Colors.grey.shade900,
            style: const TextStyle(color: Colors.white, fontFamily: AppTheme.fontFamily),
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

          // Publish Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _publishPost,
              icon: const Icon(Icons.publish_rounded),
              label: const Text(
                'مشاركة التغطية الآن',
                style: TextStyle(
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
}

class _ImageFilterOption {
  _ImageFilterOption({required this.name, required this.filter});
  final String name;
  final ColorFilter? filter;
}
