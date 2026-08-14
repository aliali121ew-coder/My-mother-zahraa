import 'package:flutter/material.dart';

import '../../../../core/services/audio_player_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class AudioTrackItem {
  AudioTrackItem({
    required this.title,
    required this.reciterName,
    required this.coverUrl,
    required this.usageCount,
    required this.audioUrl,
    this.isPlaying = false,
  });

  final String title;
  final String reciterName;
  final String coverUrl;
  final String usageCount;
  final String audioUrl;
  bool isPlaying;
}

/// BottomSheet انزلاقي فاخر لاختيار ومعاينة الصوتيات واللطميات بملفات صوت حقيقية مسموعة MP3
class AudioSelectionBottomSheet extends StatefulWidget {
  const AudioSelectionBottomSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AudioSelectionBottomSheet(),
    );
  }

  @override
  State<AudioSelectionBottomSheet> createState() => _AudioSelectionBottomSheetState();
}

class _AudioSelectionBottomSheetState extends State<AudioSelectionBottomSheet> {
  int _selectedCategoryIndex = 0;
  final _searchController = TextEditingController();

  final List<String> _categories = [
    'عناصر قد تعجبك',
    'الرائجة 🔥',
    'العناصر المحفوظة',
  ];

  final List<AudioTrackItem> _tracks = [
    AudioTrackItem(
      title: 'كفيلي شوف',
      reciterName: 'محمد باقر الخاقاني',
      coverUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=200&q=80',
      usageCount: '٣.٨ ألف مقطع',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    ),
    AudioTrackItem(
      title: 'عادتك الإحسان',
      reciterName: 'محمد باقر الخاقاني',
      coverUrl: 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?auto=format&fit=crop&w=200&q=80',
      usageCount: '٧.٨ ألف مقطع',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    ),
    AudioTrackItem(
      title: 'يهالعالم',
      reciterName: 'محمد باقر الخاقاني',
      coverUrl: 'https://images.unsplash.com/photo-1511632765486-a01980e01a18?auto=format&fit=crop&w=200&q=80',
      usageCount: '١.٣ ألف مقطع',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    ),
    AudioTrackItem(
      title: 'يابو فاضل (الفاطمية)',
      reciterName: 'باسم الكربلائي',
      coverUrl: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=200&q=80',
      usageCount: '١٤.٥ ألف مقطع',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
    ),
    AudioTrackItem(
      title: 'يا زوار أمنا الزهراء',
      reciterName: 'عمار الكناني',
      coverUrl: 'https://images.unsplash.com/photo-1541888946425-d0fbb186a5b7?auto=format&fit=crop&w=200&q=80',
      usageCount: '٩.٢ ألف مقطع',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
    ),
    AudioTrackItem(
      title: 'قصيدة الزهراء والساقي',
      reciterName: 'قحطان البديري',
      coverUrl: 'https://images.unsplash.com/photo-1532629345422-7515f3d16bb6?auto=format&fit=crop&w=200&q=80',
      usageCount: '٥.٦ ألف مقطع',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    RealAudioPlayerService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Color(0xFF121417),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 12),
            width: 40,
            height: 4.5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Search Bar & Import Button (مطابق للصورة 3)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: Colors.white54, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white, fontSize: 13.5, fontFamily: AppTheme.fontFamily),
                            decoration: const InputDecoration(
                              hintText: 'بحث عن صوت أو رادود...',
                              hintStyle: TextStyle(color: Colors.white38, fontSize: 13, fontFamily: AppTheme.fontFamily),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.music_note_rounded, color: AppColors.gold, size: 18),
                      SizedBox(width: 4),
                      Text(
                        'استيراد',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Categories Tabs Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(_categories.length, (idx) {
                final selected = idx == _selectedCategoryIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategoryIndex = idx;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _categories[idx],
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: selected ? Colors.black : Colors.white70,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 14),

          // Audio Tracks List with Real MP3 Audio Stream Player
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _tracks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final track = _tracks[index];
                return InkWell(
                  onTap: () {
                    RealAudioPlayerService.instance.stop();
                    Navigator.of(context).pop('${track.reciterName} — ${track.title}');
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        // Cover Thumbnail (شعار الموكب الرسمي)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppColors.greenAbyss,
                                child: const Icon(Icons.mosque_rounded, color: AppColors.gold),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Title & Reciter Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${track.reciterName} • ${track.usageCount}',
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 11.5,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Real Audio Play/Pause Button (تشغيل الصوت الحقيقي المسموع)
                        IconButton(
                          icon: Icon(
                            track.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                            color: track.isPlaying ? AppColors.goldBright : Colors.white70,
                            size: 32,
                          ),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            await RealAudioPlayerService.instance.playOrToggle(
                              track.audioUrl,
                              onStateChanged: (playing) {
                                setState(() {
                                  for (var t in _tracks) {
                                    if (t != track) t.isPlaying = false;
                                  }
                                  track.isPlaying = playing;
                                });
                              },
                            );

                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  track.isPlaying
                                      ? '🔊 جاري تشغيل صوتية: (${track.title})'
                                      : '⏸️ تم إيقاف الصوت',
                                  style: const TextStyle(fontFamily: AppTheme.fontFamily),
                                ),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 4),

                        // Save bookmark icon
                        IconButton(
                          icon: const Icon(Icons.bookmark_border_rounded, color: Colors.white54, size: 22),
                          onPressed: () {},
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
    );
  }
}
