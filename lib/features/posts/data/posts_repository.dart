import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/data/supabase_repository.dart';
import '../../../shared/models/enums.dart';
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
    final list = await _repo
        .loadFeed()
        .onError((error, stackTrace) => state.value ?? []);
    state = AsyncData(list);
  }


  /// نشر منشور جديد — يدعم الوضع السحابي والمحلي بسلاسة فورية.
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
    // تحديث تفاؤلي فوري في الذاكرة لتظهر التغطية مباشرة في رأس الصفحة
    final currentList = state.value ?? [];
    state = AsyncData([post, ...currentList.where((p) => p.id != post.id)]);
    return post;
  }

  Future<void> toggleLike(String postId, bool currentlyLiked) async {
    // 1. تحديث تفاؤلي فوري في الذاكرة لتستجيب الواجهة فوراً بلمسة واحدة
    final currentList = state.value ?? [];
    state = AsyncData(currentList.map((p) {
      if (p.id == postId) {
        final newLiked = !currentlyLiked;
        final newCount = newLiked
            ? p.likesCount + 1
            : (p.likesCount > 0 ? p.likesCount - 1 : 0);
        return p.copyWith(isLiked: newLiked, likesCount: newCount);
      }
      return p;
    }).toList());

    try {
      await _repo.toggleLike(postId, currentlyLiked);
    } catch (_) {}
  }

  Future<void> toggleSave(String postId, bool currentlySaved) async {
    final currentList = state.value ?? [];
    state = AsyncData(currentList.map((p) {
      if (p.id == postId) {
        return p.copyWith(isSaved: !currentlySaved);
      }
      return p;
    }).toList());

    try {
      await _repo.toggleSave(postId, currentlySaved);
    } catch (_) {}
  }

  /// تحميل التعليقات لمنشور محدد وتحديث حالة المنشور بها فوراً
  Future<List<CommentModel>> loadComments(String postId) async {
    final serverComments = await _repo.loadComments(postId);
    final currentList = state.value ?? [];
    state = AsyncData(currentList.map((p) {
      if (p.id == postId) {
        // دمج التعليقات المحلية مع تعليقات السيرفر لتفادي مسح أي تعليق
        final existingIds = serverComments.map((c) => c.id).toSet();
        final localOnly =
            p.comments.where((c) => !existingIds.contains(c.id)).toList();
        final combined = [...localOnly, ...serverComments];
        return p.copyWith(
          comments: combined,
          commentsCount: combined.length,
        );
      }
      return p;
    }).toList());
    return serverComments;
  }

  Future<CommentModel?> addComment(
      String postId, String text, String userName) async {
    final c = await _repo.addComment(postId, text, userName);
    if (c != null) {
      final currentList = state.value ?? [];
      state = AsyncData(currentList.map((p) {
        if (p.id == postId) {
          final updated = [c, ...p.comments];
          return p.copyWith(
            comments: updated,
            commentsCount: updated.length,
          );
        }
        return p;
      }).toList());
    }
    return c;
  }

  Future<void> updatePost({
    required String postId,
    required List<String> imageUrls,
    required String caption,
    String? location,
    required String yearTag,
    String? audioTrackTitle,
  }) async {
    final currentList = state.value ?? [];
    state = AsyncData(currentList.map((p) {
      if (p.id == postId) {
        return p.copyWith(
          images: imageUrls,
          caption: caption,
          location: location,
          yearTag: yearTag,
          audioTrackTitle: audioTrackTitle,
        );
      }
      return p;
    }).toList());

    await _repo.updatePost(
      postId: postId,
      imageUrls: imageUrls,
      caption: caption,
      location: location,
      yearTag: yearTag,
      audioTrackTitle: audioTrackTitle,
    );
    await refresh();
  }

  Future<void> deletePost(String postId) async {
    final currentList = state.value ?? [];
    state = AsyncData(currentList.where((p) => p.id != postId).toList());
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
      // جلب المنشورات غير المحذوفة مع صورها
      final postsRows = await db
          .from('posts')
          .select('*, images:post_images(image_url, thumb_url, position)')
          .order('created_at', ascending: false);

      final posts = List<Map<String, dynamic>>.from(postsRows);

      // جلب بيانات الناشرين لربط الأسماء والصور
      Map<String, Map<String, dynamic>> authorProfiles = {};
      final authorIds = posts
          .map((p) => p['author_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      if (authorIds.isNotEmpty) {
        try {
          final pRows = await db
              .from('profiles')
              .select('id, full_name, avatar_url')
              .filter('id', 'in', authorIds);
          for (final p in pRows) {
            authorProfiles[p['id'].toString()] = Map<String, dynamic>.from(p);
          }
        } catch (_) {}
      }

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
          .map((p) => _postFromRow(p, likeCounts, commentCounts, liked, saved, authorProfiles))
          .toList();

      await _storeLocalFeed(result);
      return result;
    } catch (e) {
      final local = _loadLocalFeed();
      return local;
    }
  }

  PostModel _postFromRow(
    Map<String, dynamic> p,
    Map<String, int> likeCounts,
    Map<String, int> commentCounts,
    Set<String> liked,
    Set<String> saved,
    Map<String, Map<String, dynamic>> authorProfiles,
  ) {
    final id = p['id'].toString();
    final authorId = p['author_id']?.toString() ?? '';
    final profile = authorProfiles[authorId] ?? (p['profiles'] as Map?) ?? const {};
    final imagesRaw = (p['images'] as List?)?.cast<Map>() ?? const [];
    final images = imagesRaw
        .map((im) => im['image_url']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
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
      isVerified: profile['role'] == 'admin',
      location: null,
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
    try {
      final rows = await db
          .from('post_comments')
          .select('id, post_id, user_id, body, created_at')
          .eq('post_id', postId)
          .order('created_at', ascending: false);

      final commentsRows = List<Map<String, dynamic>>.from(rows);
      final userIds = commentsRows
          .map((r) => r['user_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      Map<String, Map<String, dynamic>> userProfiles = {};
      if (userIds.isNotEmpty) {
        try {
          final pRows = await db
              .from('profiles')
              .select('id, full_name, avatar_url')
              .filter('id', 'in', userIds);
          for (final p in pRows) {
            userProfiles[p['id'].toString()] = Map<String, dynamic>.from(p);
          }
        } catch (_) {}
      }

      final comments = <CommentModel>[];
      for (final r in commentsRows) {
        final uid = r['user_id']?.toString() ?? '';
        final profile = userProfiles[uid] ?? const {};
        comments.add(CommentModel(
          id: r['id'].toString(),
          userName: (profile['full_name'] as String?)?.trim().isNotEmpty == true
              ? profile['full_name'] as String
              : 'خادم الحسين (ع)',
          userAvatar: (profile['avatar_url'] as String?)?.toString().trim().isNotEmpty == true
              ? profile['avatar_url'] as String
              : 'assets/images/logo.png',
          text: r['body']?.toString() ?? '',
          createdAt: DateTime.tryParse(r['created_at']?.toString() ?? '') ?? DateTime.now(),
        ));
      }
      return comments;
    } catch (_) {
      return [];
    }
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
    final now = DateTime.now();
    final authRepo = AuthRepository();
    final user = authRepo.user;
    final uid = user?.id;

    // اسم وصورة الناشر وحالة التوثيق
    String publisherName = 'موكب أمنا الزهراء (ع)';
    String publisherAvatar = 'assets/images/logo.png';
    bool isVerified = false;
    try {
      final profile = await authRepo.fetchMyProfile();
      if (profile != null && profile.fullName.isNotEmpty) {
        publisherName = profile.fullName;
        if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
          publisherAvatar = profile.avatarUrl!;
        }
        isVerified = profile.role == UserRole.admin;
      }
    } catch (_) {}

    // محاولة الإرسال لـ Supabase إن كان الاتصال والمصادقة متاحين
    if (isLive && uid != null) {
      try {
        final row = await db.from('posts').insert({
          'author_id': uid,
          'caption': caption,
          if (yearTag.isNotEmpty)
            'year': int.tryParse(yearTag) ?? now.year,
        }).select().single();

        final postId = row['id'].toString();
        for (var i = 0; i < imageUrls.length; i++) {
          await db.from('post_images').insert({
            'post_id': postId,
            'image_url': imageUrls[i],
            'position': i,
          });
        }

        final post = PostModel(
          id: postId,
          publisherName: publisherName,
          publisherAvatar: publisherAvatar,
          isVerified: isVerified,
          location: location,
          images: imageUrls,
          caption: caption,
          likesCount: 0,
          commentsCount: 0,
          isLiked: false,
          isSaved: false,
          createdAt: now,
          yearTag: yearTag.isNotEmpty ? yearTag : now.year.toString(),
          audioTrackTitle: audioTrackTitle,
        );

        final currentLocal = _loadLocalFeed();
        await _storeLocalFeed([post, ...currentLocal.where((p) => p.id != post.id)]);
        return post;
      } catch (_) {
        // في حال وجود خلل بالشبكة أو صلاحيات RLS نواصل النشر المحلي
      }
    }

    // النشر المحلي الآمن لضمان نجاح النشر في كافة الظروف
    final localPost = PostModel(
      id: 'local_post_${now.millisecondsSinceEpoch}',
      publisherName: publisherName,
      publisherAvatar: publisherAvatar,
      isVerified: isVerified,
      location: location,
      images: imageUrls,
      caption: caption,
      likesCount: 0,
      commentsCount: 0,
      isLiked: false,
      isSaved: false,
      createdAt: now,
      yearTag: yearTag.isNotEmpty ? yearTag : now.year.toString(),
      audioTrackTitle: audioTrackTitle,
    );

    final currentLocal = _loadLocalFeed();
    await _storeLocalFeed([localPost, ...currentLocal]);
    return localPost;
  }

  // ─────────────────────────────────────────────────────────────
  // الإعجاب / الحفظ / التعليق
  // ─────────────────────────────────────────────────────────────
  Future<void> toggleLike(String postId, bool currentlyLiked) async {
    final uid = db.auth.currentUser?.id;
    if (uid == null || !isLive) return;

    try {
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
    } catch (_) {}
  }

  Future<void> toggleSave(String postId, bool currentlySaved) async {
    final uid = db.auth.currentUser?.id;
    if (uid == null || !isLive) return;

    try {
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
    } catch (_) {}
  }

  /// تعليق جديد — يدعم الوضع السحابي والمحلي والتجريبي بسلاسة
  Future<CommentModel?> addComment(String postId, String text, [String? senderName]) async {
    if (text.trim().isEmpty) return null;
    final uid = db.auth.currentUser?.id;
    if (uid == null || !isLive) {
      return CommentModel(
        id: 'local_c_${DateTime.now().millisecondsSinceEpoch}',
        userName: senderName ?? 'زائر كريم',
        userAvatar: 'assets/images/logo.png',
        text: text.trim(),
        createdAt: DateTime.now(),
      );
    }

    try {
      final row = await db.from('post_comments').insert({
        'post_id': postId,
        'user_id': uid,
        'body': text.trim(),
      }).select().single();

      String userName = senderName ?? 'زائر كريم';
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
              : userName;
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
    } catch (_) {
      return CommentModel(
        id: 'local_c_${DateTime.now().millisecondsSinceEpoch}',
        userName: senderName ?? 'زائر كريم',
        userAvatar: 'assets/images/logo.png',
        text: text.trim(),
        createdAt: DateTime.now(),
      );
    }
  }

  /// تعديل المنشور الشامل
  Future<void> updatePost({
    required String postId,
    required List<String> imageUrls,
    required String caption,
    String? location,
    required String yearTag,
    String? audioTrackTitle,
  }) async {
    try {
      if (isLive) {
        await db.from('posts').update({
          'caption': caption,
          if (yearTag.isNotEmpty)
            'year': int.tryParse(yearTag) ?? DateTime.now().year,
        }).eq('id', postId);

        if (imageUrls.isNotEmpty) {
          try {
            await db.from('post_images').delete().eq('post_id', postId);
            for (var i = 0; i < imageUrls.length; i++) {
              await db.from('post_images').insert({
                'post_id': postId,
                'image_url': imageUrls[i],
                'position': i,
              });
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  /// حذف ناعم للمنشور — RLS يشترط can_publish()
  Future<void> softDeletePost(String postId) async {
    try {
      if (isLive) {
        await db
            .from('posts')
            .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', postId);
      }
    } catch (_) {}
  }

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
