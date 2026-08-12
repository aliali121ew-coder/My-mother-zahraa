import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class LocationDistanceItem {
  LocationDistanceItem({
    required this.name,
    required this.distance,
    this.subtitle,
  });

  final String name;
  final String distance;
  final String? subtitle;
}

/// شاشة اختيار الموقع "حدد موقعاً" المطابقة لصورة الإنستغرام الحقيقي الرابعة
class LocationSelectionSheet extends StatefulWidget {
  const LocationSelectionSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LocationSelectionSheet(),
    );
  }

  @override
  State<LocationSelectionSheet> createState() => _LocationSelectionSheetState();
}

class _LocationSelectionSheetState extends State<LocationSelectionSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<LocationDistanceItem> _allLocations = [
    LocationDistanceItem(
      name: 'كربلاء المقدسة — بين الحرمين الشريفين',
      distance: '٠.٤ كم',
      subtitle: 'Karbala, Iraq',
    ),
    LocationDistanceItem(
      name: 'كربلاء المقدسة — شارع السدرة (مقر الموكب)',
      distance: '١.٢ كم',
      subtitle: 'Karbala, Iraq',
    ),
    LocationDistanceItem(
      name: 'كربلاء المقدسة — صحن العقيلة زينب (ع)',
      distance: '١.٨ كم',
      subtitle: 'Karbala, Iraq',
    ),
    LocationDistanceItem(
      name: 'بابل مدينة القاسم المقدسة',
      distance: '٨.٨ كم',
      subtitle: 'Babil, Hashimiya, Iraq',
    ),
    LocationDistanceItem(
      name: 'الهاشمية بابل',
      distance: '٠.٥ كم',
      subtitle: 'Hashimiya, Babil, Iraq',
    ),
    LocationDistanceItem(
      name: 'النجف الأشرف — شارع الرسول (ص)',
      distance: '٢٤.٥ كم',
      subtitle: 'Al Najaf, Iraq',
    ),
    LocationDistanceItem(
      name: 'الكاظمية المقدسة — باب المراد',
      distance: '٣١.٨ كم',
      subtitle: 'Kadhimiya, Baghdad, Iraq',
    ),
    LocationDistanceItem(
      name: 'سامراء المقدسة — العتبة العسكرية',
      distance: '٧٥.٠ كم',
      subtitle: 'Samarra, Iraq',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredLocations = _allLocations.where((loc) {
      if (_searchQuery.isEmpty) return true;
      return loc.name.contains(_searchQuery) ||
          (loc.subtitle != null && loc.subtitle!.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF101317),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (مطابق للصورة 4)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Expanded(
                  child: Text(
                    'حدد موقعاً',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.displayFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.gold, size: 22),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Subtitle Explanatory Text
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'اختيار موقع للإشارة إليه',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'يمكن للأشخاص، الذين تشارك معهم هذا المحتوى، الاطلاع على الموقع الذي أشرت إليه ومشاهدة هذا المحتوى على الخريطة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    color: Colors.white54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Colors.white54, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() => _searchQuery = val.trim());
                      },
                      style: const TextStyle(color: Colors.white, fontSize: 13.5, fontFamily: AppTheme.fontFamily),
                      decoration: const InputDecoration(
                        hintText: 'بحث عن موقع...',
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

          const SizedBox(height: 16),

          // Locations List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filteredLocations.length,
              separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 20),
              itemBuilder: (context, index) {
                final loc = filteredLocations[index];
                return InkWell(
                  onTap: () {
                    Navigator.of(context).pop(loc.name);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.name,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              loc.distance,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 12,
                                color: AppColors.goldBright,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (loc.subtitle != null) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '• ${loc.subtitle}',
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 11.5,
                                    color: Colors.white38,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
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
