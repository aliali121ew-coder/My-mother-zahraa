import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/data/supabase_repository.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/post_model.dart';

// ─────────────────────────────────────────────────────────────────
// المزوّد الجذري: يحمّل خلاصة المنشورات من Supabase مباشرة، ويستمر
// بالتزويد المحلي أثناء عدم الاتصال (صندوق `posts` في Hive).
// ─────────────────────────────────────────────────────────────────
final postsProvider =
    AsyncNotifierProvider<PostsNotifier, List<PostModel>>(PostsNotifier.new);

class PostsNotifier extends AsyncNotifier<List<PostModel>> {
  PostsRepository get _repo => PostsRepository();

  @override
  Future<List<PostModel>> build() => _repo.loadFeed();

  Future<void> refresh() async {
    final list = await _repo.loadFeed().onError((_, __) => state.value ?? []);
    state = AsyncData(list);
  }

  /// تحميل التعليقات لمنشور محدد (تُجلب عند فتح ورقة التعليقات)
  Future<List<CommentModel>> loadComments(String postId) =>
      _repo.loadComments(postId);

  /// نشر منشور جديد — يتحقق RLS من صلاحية can_publish() تلقائيًا.
  Future<PostModel?> addPost({
    required List<String> imageUrls,
    required String caption,
    String? location,
    required String yearTag,
    String? audioTrackTitle,
  }) async {
    final post = await _repo.createPost(
      imageUrls: imageUrls,
      caption: caption,
      location: location,
      yearTag: yearTag,
      audioTrackTitle: audioTrackTitle,
    );
    await refresh();
    return post;
  }

  Future<void> toggleLike(String postId, bool currentlyLiked) async {
    await _repo.toggleLike(postId, currentlyLiked);
    await refresh();
  }

  Future<void> toggleSave(String postId, bool currentlySaved) async {
    await _repo.toggleSave(postId, currentlySaved);
    await refresh();
  }

  Future<CommentModel?> addComment(
      String postId, String text, String userName) async {
    final c = await _repo.addComment(postId, text);
    await refresh();
    return c;
  }

  Future<void> deletePost(String postId) async {
    await _repo.softDeletePost(postId);
    await refresh();
  }
}

/// مستودع المنشورات الفعلي — جدولا `posts` و`post_images` وجداول التفاعلات.
class PostsRepository extends SupabaseRepository {
  // ─────────────────────────────────────────────────────────────
  // تحميل الخلاصة (شبكة ← تخزين، والارتداد للمخزن عند قطع الاتصال)
  // ─────────────────────────────────────────────────────────────
  Future<List<PostModel>> loadFeed() async {
    if (!isLive) return _loadLocalFeed();

    final authRepo = AuthRepository();
    final uid = authRepo.user?.id;
    final isAnonymous = authRepo.isAnonymous;

    try {
      // جلب المنشورات غير المحذوفة مع صورها وبيانات ناشريها
      final postsRows = await db
          .from('posts')
          .select(
            '*, images:post_images(image_url, thumb_url, position), '
            'profiles!posts_author_id_profiles_id_fkey(full_name, avatar_url)',
          )
          .order('created_at', ascending: false);

      final posts = List<Map<String, dynamic>>.from(postsRows);

      Set<String> liked = {};
      Set<String> saved = {};
      if (uid != null && !isAnonymous) {
        try {
          final likes =
              await db.from('post_likes').select('post_id').eq('user_id', uid);
          liked = likes.map((r) => r['post_id'].toString()).toSet();
          final saves =
              await db.from('post_saves').select('post_id').eq('user_id', uid);
          saved = saves.map((r) => r['post_id'].toString()).toSet();
        } on PostgrestException {
          // RLS قد يرفض مؤقتًا — نتابع بلا حالة شخصية
        }
      }

      final postIds = posts.map((p) => p['id'].toString()).toList();

      Map<String, int> likeCounts = {};
      Map<String, int> commentCounts = {};
      if (postIds.isNotEmpty) {
        try {
          final lc = await db
              .from('post_likes')
              .select('post_id')
              .filter('post_id', 'in', postIds);
          for (final r in lc) {
            final id = r['post_id'].toString();
            likeCounts[id] = (likeCounts[id] ?? 0) + 1;
          }
          final cc = await db
              .from('post_comments')
              .select('post_id')
              .filter('post_id', 'in', postIds);
          for (final r in cc) {
            final id = r['post_id'].toString();
            commentCounts[id] = (commentCounts[id] ?? 0) + 1;
          }
        } on PostgrestException {
          // نتابع مع أصفار
        }
      }

      final result = posts
          .map((p) => _postFromRow(p, likeCounts, commentCounts, liked, saved))
          .toList();

      // التخزين المحلي حتى تعمل الخلاصة دون اتصال
      await _storeLocalFeed(result);
      return result;
    } catch (e) {
      final local = _loadLocalFeed();
      if (local.isEmpty) rethrow;
      return local;
    }
  }

  PostModel _postFromRow(
    Map<String, dynamic> p,
    Map<String, int> likeCounts,
    Map<String, int> commentCounts,
    Set<String> liked,
    Set<String> saved,
  ) {
    final id = p['id'].toString();
    final imagesRaw = (p['images'] as List?)?.cast<Map>() ?? const [];
    final images = imagesRaw
        .map((im) => im['image_url']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    final profile = (p['profiles'] as Map?) ?? const {};
    return PostModel(
      id: id,
      publisherName:
          (profile['full_name'] as String?)?.trim().isNotEmpty == true
              ? profile['full_name'] as String
              : 'موكب أمنا الزهراء (ع)',
      publisherAvatar:
          (profile['avatar_url'] as String?)?.toString().trim().isNotEmpty == true
              ? profile['avatar_url'] as String
              : 'assets/images/logo.png',
      isVerified: false,
      location: null, // عمود الموقع غير موجود في جدول posts بالمخطط الفعلي
      images: images,
      caption: (p['caption'] as String?)?.trim().isNotEmpty == true
          ? p['caption'] as String
          : '',
      likesCount: likeCounts[id] ?? 0,
      commentsCount: commentCounts[id] ?? 0,
      isLiked: liked.contains(id),
      isSaved: saved.contains(id),
      createdAt:
          DateTime.tryParse(p['created_at']?.toString() ?? '') ?? DateTime.now(),
      yearTag: (p['year']?.toString()) ?? '',
    );
  }

  // ─────────────────────────────────────────────────────────────
  // التعليقات (تُحمّل عند فتح ورقة التعليقات)
  // ─────────────────────────────────────────────────────────────
  Future<List<CommentModel>> loadComments(String postId) async {
    final rows = await db
        .from('post_comments')
        .select('*, profiles!post_comments_user_id_profiles_id_fkey(full_name, avatar_url)')
        .eq('post_id', postId)
        .order('created_at', ascending: false);

    final comments = <CommentModel>[];
    for (final r in rows) {
      final profile = (r['profiles'] as Map?) ?? const {};
      comments.add(CommentModel(
        id: r['id'].toString(),
        userName:
            (profile['full_name'] as String?)?.trim().isNotEmpty == true
                ? profile['full_name'] as String
                : 'زائر كريم',
        userAvatar:
            (profile['avatar_url'] as String?)?.toString().trim().isNotEmpty ==
                    true
                ? profile['avatar_url'] as String
                : 'assets/images/logo.png',
        text: r['body']?.toString() ?? '',
        createdAt:
            DateTime.tryParse(r['created_at']?.toString() ?? '') ??
            DateTime.now(),
      ));
    }
    return comments;
  }

  // ─────────────────────────────────────────────────────────────
  // إنشاء منشور (RLS يشترط can_publish: admin أو publisher)
  // ─────────────────────────────────────────────────────────────
  Future<PostModel> createPost({
    required List<String> imageUrls,
    required String caption,
    String? location,
    required String yearTag,
    String? audioTrackTitle,
  }) async {
    final authRepo = AuthRepository();
    final uid = authRepo.user?.id;
    if (uid == null) {
      throw Exception('يجب تسجيل الدخول أولًا لنشر تغطية');
    }

    final row = await db.from('posts').insert({
      'author_id': uid,
      'caption': caption,
      if (yearTag.isNotEmpty)
        'year': int.tryParse(yearTag) ?? DateTime.now().year,
    }).select().single();

    final postId = row['id'].toString();
    for (var i = 0; i < imageUrls.length; i++) {
      await db.from('post_images').insert({
        'post_id': postId,
        'image_url': imageUrls[i],
        'position': i,
      });
    }

    return _postFromRow(
      {
        ...Map<String, dynamic>.from(row),
        'images': imageUrls.map((u) => {'image_url': u}).toList(),
      },
      {},
      {},
      const {},
      const {},
    );
  }

  // ─────────────────────────────────────────────────────────────
  // الإعجاب / الحفظ / التعليق
  // ─────────────────────────────────────────────────────────────
  Future<void> toggleLike(String postId, bool currentlyLiked) async {
    final uid = db.auth.currentUser?.id;
    if (uid == null) return;

    if (currentlyLiked) {
      await db
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', uid);
    } else {
      await db.from('post_likes').insert({
        'post_id': postId,
        'user_id': uid,
      }).maybeSingle();
    }
  }

  Future<void> toggleSave(String postId, bool currentlySaved) async {
    final uid = db.auth.currentUser?.id;
    if (uid == null) return;

    if (currentlySaved) {
      await db
          .from('post_saves')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', uid);
    } else {
      await db.from('post_saves').insert({
        'post_id': postId,
        'user_id': uid,
      }).maybeSingle();
    }
  }

  /// تعليق جديد — RLS يشترط حسابًا معتمدًا (is_approved) وليس جلسة مجهولة
  Future<CommentModel?> addComment(String postId, String text) async {
    if (text.trim().isEmpty) return null;
    final uid = db.auth.currentUser?.id;
    if (uid == null) return null;

    final row = await db.from('post_comments').insert({
      'post_id': postId,
      'user_id': uid,
      'body': text.trim(),
    }).select().single();

    // جلب اسم الناشر وصورته من ملف المستخدم الحالي — الدفق المرجعي
    // `post_comments_user_id_profiles_id_fkey` لا يُرجع علاقة `profiles`
    // تلقائيًا بعد insert فلا نعتمد عليه هنا.
    String userName = 'زائر كريم';
    String userAvatar = 'assets/images/logo.png';
    try {
      final pRow = await db
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', uid)
          .maybeSingle();
      if (pRow != null) {
        userName = (pRow['full_name'] as String?)?.trim().isNotEmpty == true
            ? pRow['full_name'] as String
            : 'زائر كريم';
        userAvatar =
            (pRow['avatar_url'] as String?)?.toString().trim().isNotEmpty == true
                ? pRow['avatar_url'] as String
                : 'assets/images/logo.png';
      }
    } catch (_) {}

    return CommentModel(
      id: row['id'].toString(),
      userName: userName,
      userAvatar: userAvatar,
      text: row['body']?.toString() ?? text.trim(),
      createdAt: DateTime.now(),
    );
  }

  /// حذف ناعم للمنشور — RLS يشترط can_publish()
  Future<void> softDeletePost(String postId) async => db
      .from('posts')
      .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
      .eq('id', postId);

  // ─────────────────────────────────────────────────────────────
  // التخزين المحلي — حتى تفتح الخلاصة دون اتصال
  // ─────────────────────────────────────────────────────────────
  Future<void> _storeLocalFeed(List<PostModel> feed) async {
    try {
      final rows = feed.map((p) {
        return <String, dynamic>{
          'id': p.id,
          'publisher_name': p.publisherName,
          'publisher_avatar': p.publisherAvatar,
          'is_verified': p.isVerified,
          if (p.location != null) 'location': p.location,
          'images': p.images,
          'caption': p.caption,
          'likes_count': p.likesCount,
          'comments_count': p.commentsCount,
          'is_liked': p.isLiked,
          'is_saved': p.isSaved,
          'created_at': p.createdAt.toIso8601String(),
          'year_tag': p.yearTag,
        };
      }).toList();
      await cache.replaceAll(
        AppConfig.boxPosts,
        rows,
        (m) => m['id'].toString(),
      );
    } catch (_) {
      // فشل التخزين المحلي لا يعطّل الخلاصة
    }
  }

  List<PostModel> _loadLocalFeed() {
    final rows = cache.readAll(AppConfig.boxPosts);
    return rows.map(_postFromLocalRow).toList();
  }

  PostModel _postFromLocalRow(Map<String, dynamic> r) => PostModel(
        id: r['id'].toString(),
        publisherName: r['publisher_name']?.toString() ?? 'موكب أمنا الزهراء (ع)',
        publisherAvatar:
            r['publisher_avatar']?.toString() ?? 'assets/images/logo.png',
        isVerified: r['is_verified'] == true,
        location: r['location']?.toString(),
        images: (r['images'] as List?)
                ?.map((e) => e.toString())
                .where((s) => s.isNotEmpty)
                .toList() ??
            const [],
        caption: r['caption']?.toString() ?? '',
        likesCount: r['likes_count'] is int ? r['likes_count'] as int : 0,
        commentsCount:
            r['comments_count'] is int ? r['comments_count'] as int : 0,
        isLiked: r['is_liked'] == true,
        isSaved: r['is_saved'] == true,
        createdAt:
            DateTime.tryParse(r['created_at']?.toString() ?? '') ??
            DateTime.now(),
        yearTag: r['year_tag']?.toString() ?? '',
      );
}
