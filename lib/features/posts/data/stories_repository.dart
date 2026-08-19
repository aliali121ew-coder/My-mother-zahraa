import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/data/supabase_repository.dart';
import '../../../core/storage/hive_service.dart';
import '../domain/post_model.dart';

// ─────────────────────────────────────────────────────────────────
// مزوّد الستوريز الحقيقي — تُجمع من جدول `stories` حقيقيًا حسب
// قسمها في `story_categories`، والارتداد للمخزن المحلي عند قطع الاتصال.
// ─────────────────────────────────────────────────────────────────
final storiesProvider =
    AsyncNotifierProvider<StoriesNotifier, List<StoryModel>>(
      StoriesNotifier.new,
    );

class StoriesNotifier extends AsyncNotifier<List<StoryModel>> {
  StoriesRepository get _repo => StoriesRepository();

  @override
  Future<List<StoryModel>> build() => _repo.loadStories();

  Future<void> refresh() async {
    final list = await _repo
        .loadStories()
        .onError((error, stackTrace) => state.value ?? []);
    state = AsyncData(list);
  }

  /// إضافة ستوري جديدة إلى قسم معين (RLS يشترط can_publish)
  Future<void> addStory({
    required String categoryId,
    required String imageUrl,
    String? thumbUrl,
  }) async {
    await _repo.insertStory(categoryId, imageUrl, thumbUrl);
    await refresh();
  }

  /// نشر قصة فورية من صورة مختارة (على طريقة الإنستغرام)
  Future<void> publishNewStory({
    required String imageUrl,
    required String publisherName,
    String? caption,
  }) async {
    await _repo.publishUserStory(
      imageUrl: imageUrl,
      publisherName: publisherName,
      caption: caption,
    );
    await refresh();
  }

  Future<void> deleteStory(String storyId) async {
    await _repo.removeStory(storyId);
    await refresh();
  }

  Future<void> deleteStoryItem(String storyId, String itemId) async {
    await _repo.removeStoryItem(storyId, itemId);
    await refresh();
  }

  /// مسح كافة الستوريات المخزنة محلياً وسحابياً لإعادة الاختبار
  Future<void> clearAllStories() async {
    await _repo.clearAllStories();
    await refresh();
  }

  /// تعليم ستوري بأنها عُرضت — تُحفظ محليًا (ليست حالة مشتركة)
  void markAsViewed(String storyId) {
    if (state is AsyncData<List<StoryModel>>) {
      final list = List<StoryModel>.from(state.value!);
      state = AsyncData([
        for (final s in list)
          if (s.id == storyId) s.copyWith(isViewed: true) else s,
      ]);
    }
    HiveService.instance
        .settings
        .put('story_viewed_$storyId', '1');
  }
}

class StoriesRepository extends SupabaseRepository {

  Future<List<StoryModel>> loadStories() async {
    if (!isLive) return _loadLocal();

    try {
      // 1. جلب التصنيفات
      final catRows = await db
          .from('story_categories')
          .select('id, name, cover_url')
          .order('position', ascending: false);

      final categories = List<Map<String, dynamic>>.from(catRows);
      final result = <StoryModel>[];
      final viewed = await _viewedSet();

      if (categories.isNotEmpty) {
        // 2. جلب الستوريات
        try {
          final storyRows = await db
              .from('stories')
              .select('id, category_id, image_url, thumb_url, created_at')
              .order('created_at', ascending: true);

          final storiesList = List<Map<String, dynamic>>.from(storyRows);

          for (final cat in categories) {
            final catId = cat['id'].toString();
            final items = storiesList.where((s) => s['category_id']?.toString() == catId);
            final storyItems = items
                .map((m) {
                  final url = m['image_url']?.toString() ?? '';
                  if (url.isEmpty) return null;
                  return StoryItemModel(
                    id: m['id'].toString(),
                    imageUrl: url,
                    caption: null,
                    durationSeconds: 5,
                  );
                })
                .whereType<StoryItemModel>()
                .toList();

            if (storyItems.isEmpty) continue;

            result.add(StoryModel(
              id: catId,
              title: cat['name']?.toString() ?? '',
              coverUrl: cat['cover_url']?.toString().isNotEmpty == true
                  ? cat['cover_url'] as String
                  : storyItems.first.imageUrl,
              items: storyItems,
              isViewed: storyItems.every((i) => viewed.contains(i.id)),
            ));
          }
        } catch (_) {
          // إذا تعذر جلب جدول stories نتابع
        }
      }

      await _storeLocal(result);
      return result;
    } catch (e) {
      final local = _loadLocal();
      return local;
    }
  }

  Future<void> insertStory(
    String categoryId,
    String imageUrl,
    String? thumbUrl,
  ) async {
    await db.from('stories').insert({
      'category_id': categoryId,
      'image_url': imageUrl,
      'thumb_url': ?thumbUrl,
    });
  }

  Future<void> publishUserStory({
    required String imageUrl,
    required String publisherName,
    String? caption,
  }) async {
    final currentList = _loadLocal();
    final now = DateTime.now().millisecondsSinceEpoch;
    final storyItem = StoryItemModel(
      id: 'item_$now',
      imageUrl: imageUrl,
      caption: caption,
      durationSeconds: 6,
    );

    // البحث عما إذا كان هناك قصة موحدة للمستخدم أو الموكب لإضافة الشريحة بداخلها
    final existingIndex = currentList.indexWhere(
      (s) =>
          s.id == 'my_story' ||
          s.title == 'قصتك' ||
          s.title == 'قصتي' ||
          s.title == 'موكب أمنا الزهراء (ع)' ||
          s.title.trim().toLowerCase() == publisherName.trim().toLowerCase(),
    );

    List<StoryModel> updatedList;
    if (existingIndex != -1) {
      final existingStory = currentList[existingIndex];
      final updatedStory = existingStory.copyWith(
        id: 'my_story',
        title: 'قصتك',
        coverUrl: imageUrl, // تحديث الغلاف بآخر صورة أضيفت
        items: [...existingStory.items, storyItem],
        isViewed: false, // إعادة تفعيل الإطار الملون
      );
      final remaining = List<StoryModel>.from(currentList)
        ..removeAt(existingIndex);
      // وضع قصة المستخدم دائماً في البداية
      updatedList = [updatedStory, ...remaining];
    } else {
      final storyId = 'my_story';
      final newStory = StoryModel(
        id: storyId,
        title: 'قصتك',
        coverUrl: imageUrl,
        items: [storyItem],
        isViewed: false,
      );
      updatedList = [newStory, ...currentList];
    }

    // الحفظ المحلي المباشر لضمان الظهور الفوري في الواجهة
    await _storeLocal(updatedList);

    // إذا كان الاتصال متاحاً، نحاول الحفظ في Supabase
    if (isLive) {
      try {
        // البحث عن تصنيف موجود أو إنشاء تصنيف باسم الناشر
        final cats = await db
            .from('story_categories')
            .select('id')
            .eq('name', publisherName)
            .limit(1);

        String catId;
        if (cats.isNotEmpty) {
          catId = cats.first['id'].toString();
        } else {
          final ins = await db
              .from('story_categories')
              .insert({'name': publisherName, 'cover_url': imageUrl})
              .select('id')
              .single();
          catId = ins['id'].toString();
        }

        await insertStory(catId, imageUrl, null);
      } catch (_) {
        // إذا فشل الاتصال بالسيرفر تبقى القصة محفوظة محلياً
      }
    }
  }

  Future<void> removeStory(String storyId) =>
      db.from('stories').delete().eq('id', storyId);

  Future<void> removeStoryItem(String storyId, String itemId) async {
    final currentList = _loadLocal();
    final storyIdx = currentList.indexWhere((s) => s.id == storyId);
    if (storyIdx != -1) {
      final story = currentList[storyIdx];
      final updatedItems = story.items.where((i) => i.id != itemId).toList();
      if (updatedItems.isEmpty) {
        currentList.removeAt(storyIdx);
      } else {
        currentList[storyIdx] = story.copyWith(
          items: updatedItems,
          coverUrl: updatedItems.last.imageUrl,
        );
      }
      await _storeLocal(currentList);
    }
  }

  Future<void> clearAllStories() async {
    try {
      await HiveService.instance.box(AppConfig.boxStories).clear();
      final box = HiveService.instance.settings;
      final keys = box.keys.where((k) => k.toString().startsWith('story_viewed_')).toList();
      for (final k in keys) {
        await box.delete(k);
      }
    } catch (_) {}
  }

  Future<Set<String>> _viewedSet() async {
    final box = HiveService.instance.settings;
    final keys = box.keys.map((k) => k.toString()).toList();
    return keys
        .where((k) => k.startsWith('story_viewed_'))
        .map((k) => k.replaceFirst('story_viewed_', ''))
        .toSet();
  }

  Future<void> _storeLocal(List<StoryModel> stories) async {
    try {
      final rows =
          stories
              .map((s) {
                final r = <String, dynamic>{
                  'id': s.id,
                  'title': s.title,
                  'cover_url': s.coverUrl,
                  'items': s.items.map((i) {
                    return {
                      'id': i.id,
                      'image_url': i.imageUrl,
                      if (i.caption != null) 'caption': i.caption,
                      'duration_seconds': i.durationSeconds,
                    };
                  }).toList(),
                  'is_viewed': s.isViewed,
                };
                return jsonSafe(r);
              })
              .toList();
      await HiveService.instance.replaceAll(
        AppConfig.boxStories,
        rows,
        (m) => m['id'].toString(),
      );
    } catch (_) {}
  }

  List<StoryModel> _loadLocal() {
    final rows = HiveService.instance.readAll(AppConfig.boxStories);
    return rows.map(_storyFromLocalRow).where((s) => s.items.isNotEmpty).toList();
  }

  StoryModel _storyFromLocalRow(Map<String, dynamic> r) => StoryModel(
        id: r['id'].toString(),
        title: r['title']?.toString() ?? '',
        coverUrl: r['cover_url']?.toString() ?? '',
        isViewed: r['is_viewed'] == true,
        items:
            (r['items'] as List?)
                ?.map((im) => StoryItemModel(
                  id: im['id'].toString(),
                  imageUrl: im['image_url']?.toString() ?? '',
                  caption: im['caption']?.toString(),
                  durationSeconds: im['duration_seconds'] is int
                      ? im['duration_seconds'] as int
                      : 5,
                ))
                .toList() ??
            const [],
      );
}
