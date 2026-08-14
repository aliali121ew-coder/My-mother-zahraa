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
        .onError((_, __) => state.value ?? []);
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

  Future<void> deleteStory(String storyId) async {
    await _repo.removeStory(storyId);
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
        .box(AppConfig.boxSettings)
        .put('story_viewed_$storyId', '1');
  }
}

class StoriesRepository extends SupabaseRepository {
  static const _localKey = 'stories_list';

  Future<List<StoryModel>> loadStories() async {
    if (!isLive) return _loadLocal();

    try {
      final rows = await db
          .from('story_categories')
          .select(
            'id, name, cover_url, '
            'stories!stories_category_id_story_categories_id_fkey(id, image_url, thumb_url, created_at)',
          )
          .order('position', ascending: false);

      final result = <StoryModel>[];
      final viewed = await _viewedSet();

      for (final cat in rows) {
        final items = (cat['stories'] as List?)?.cast<Map>() ?? const [];
        final storyItems =
            items
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
                .toList()
              ..sort((a, b) => a.imageUrl.compareTo(b.imageUrl));

        if (storyItems.isEmpty) continue;

        result.add(StoryModel(
          id: cat['id'].toString(),
          title: cat['name']?.toString() ?? '',
          coverUrl:
              cat['cover_url']?.toString().isNotEmpty == true
                  ? cat['cover_url'] as String
                  : storyItems.first.imageUrl,
          items: storyItems,
          isViewed: storyItems.every((i) => viewed.contains(i.id)),
        ));
      }

      await _storeLocal(result);
      return result;
    } catch (e) {
      final local = _loadLocal();
      if (local.isEmpty) rethrow;
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
      if (thumbUrl != null) 'thumb_url': thumbUrl,
    });
  }

  Future<void> removeStory(String storyId) =>
      db.from('stories').delete().eq('id', storyId);

  Future<Set<String>> _viewedSet() async {
    final box = HiveService.instance.box(AppConfig.boxSettings);
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
