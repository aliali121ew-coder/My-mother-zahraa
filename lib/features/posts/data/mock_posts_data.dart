import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/post_model.dart';

final storiesProvider = StateNotifierProvider<StoriesNotifier, List<StoryModel>>((ref) {
  return StoriesNotifier();
});

class StoriesNotifier extends StateNotifier<List<StoryModel>> {
  StoriesNotifier() : super(_initialStories);

  static final List<StoryModel> _initialStories = [
    StoryModel(
      id: 'st_1',
      title: 'جدول العزاء',
      coverUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=400&q=80',
      items: [
        const StoryItemModel(
          id: 'sti_1_1',
          imageUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=800&q=80',
          caption: 'برنامج مجالس أسبوع الزهراء (عليها السلام) — كربلاء المقدسة',
        ),
        const StoryItemModel(
          id: 'sti_1_2',
          imageUrl: 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?auto=format&fit=crop&w=800&q=80',
          caption: 'مشاركة الخطباء والشعراء في المجلس السنوي',
        ),
      ],
    ),
    StoryModel(
      id: 'st_2',
      title: 'خدمة الزوار',
      coverUrl: 'https://images.unsplash.com/photo-1511632765486-a01980e01a18?auto=format&fit=crop&w=400&q=80',
      items: [
        const StoryItemModel(
          id: 'sti_2_1',
          imageUrl: 'https://images.unsplash.com/photo-1511632765486-a01980e01a18?auto=format&fit=crop&w=800&q=80',
          caption: 'تجهيز الوجبات اليومية للزائرين الكرام',
        ),
      ],
    ),
    StoryModel(
      id: 'st_3',
      title: 'أرشيف 1445',
      coverUrl: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=400&q=80',
      items: [
        const StoryItemModel(
          id: 'sti_3_1',
          imageUrl: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=800&q=80',
          caption: 'جانب من المسيرة الفاطمية السنوية عام 1445 هـ',
        ),
      ],
    ),
    StoryModel(
      id: 'st_4',
      title: 'أعمال البناء',
      coverUrl: 'https://images.unsplash.com/photo-1541888946425-d0fbb186a5b7?auto=format&fit=crop&w=400&q=80',
      items: [
        const StoryItemModel(
          id: 'sti_4_1',
          imageUrl: 'https://images.unsplash.com/photo-1541888946425-d0fbb186a5b7?auto=format&fit=crop&w=800&q=80',
          caption: 'مراحل صب وإكمال الهيكل الخرساني للموكب',
        ),
      ],
    ),
    StoryModel(
      id: 'st_5',
      title: 'تواصل وتبرع',
      coverUrl: 'https://images.unsplash.com/photo-1532629345422-7515f3d16bb6?auto=format&fit=crop&w=400&q=80',
      items: [
        const StoryItemModel(
          id: 'sti_5_1',
          imageUrl: 'https://images.unsplash.com/photo-1532629345422-7515f3d16bb6?auto=format&fit=crop&w=800&q=80',
          caption: 'طرق المساهمة والتبرع لدعم مشاريع الموكب',
        ),
      ],
    ),
  ];

  void markAsViewed(String storyId) {
    state = [
      for (final s in state)
        if (s.id == storyId) s.copyWith(isViewed: true) else s
    ];
  }
}

final postsProvider = StateNotifierProvider<PostsNotifier, List<PostModel>>((ref) {
  return PostsNotifier();
});

class PostsNotifier extends StateNotifier<List<PostModel>> {
  PostsNotifier() : super(_initialPosts);

  static final List<PostModel> _initialPosts = [
    PostModel(
      id: 'post_1',
      publisherName: 'موكب أمنا الزهراء (ع)',
      publisherAvatar: 'assets/images/logo.png',
      isVerified: true,
      location: 'كربلاء المقدسة — شارع السدرة',
      images: [
        'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1000&q=80',
        'https://images.unsplash.com/photo-1511632765486-a01980e01a18?auto=format&fit=crop&w=1000&q=80',
        'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?auto=format&fit=crop&w=1000&q=80',
      ],
      caption: 'تغطية مصورة لمجلس العزاء السنوي بذكرى استشهاد الصديقة الطاهرة فاطمة الزهراء (عليها السلام). نسأل الله القبول والرضا من جميع الخدام والمساهمين 🖤✨\n#موكب_أمنا_الزهراء #كربلاء_المقدسة #الأيام_الفاطمية',
      likesCount: 248,
      commentsCount: 19,
      isLiked: true,
      isSaved: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      yearTag: '2026',
      comments: [
        CommentModel(
          id: 'c_1',
          userName: 'حسنين محمد',
          userAvatar: 'https://i.pravatar.cc/150?img=11',
          text: 'عظم الله لكم الأجر والثواب، جزاكم الله خير الجزاء خادم الزهراء 🤲',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          likesCount: 12,
          isLiked: true,
        ),
        CommentModel(
          id: 'c_2',
          userName: 'حيدر عباس',
          userAvatar: 'https://i.pravatar.cc/150?img=33',
          text: 'مأجورين وموفقين لكل خير إن شاء الله',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          likesCount: 5,
        ),
      ],
    ),
    PostModel(
      id: 'post_2',
      publisherName: 'موكب أمنا الزهراء (ع)',
      publisherAvatar: 'assets/images/logo.png',
      isVerified: true,
      location: 'موقع مشروع بناية الموكب السكني',
      images: [
        'https://images.unsplash.com/photo-1541888946425-d0fbb186a5b7?auto=format&fit=crop&w=1000&q=80',
        'https://images.unsplash.com/photo-1504307651254-35680f356dfd?auto=format&fit=crop&w=1000&q=80',
      ],
      caption: 'بفضل الله وبدعم المشتركين والمساهمين الكرام، تم إكمال صب السقف الثالث لمشروع البناية الخدمية للموكب. شكر خاص لكل يد ساهمت ودعمت المشروع 🏗️🏢\n#مشاريع_الموكب #إعمار #خدمة_الزوار',
      likesCount: 189,
      commentsCount: 8,
      isLiked: false,
      isSaved: false,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      yearTag: '2026',
      comments: [
        CommentModel(
          id: 'c_3',
          userName: 'السيد الجابري',
          userAvatar: 'https://i.pravatar.cc/150?img=60',
          text: 'ما شاء الله تبارك الله، جهود مباركة وقيمة حشركم الله مع أهل البيت',
          createdAt: DateTime.now().subtract(const Duration(hours: 20)),
          likesCount: 8,
        ),
      ],
    ),
    PostModel(
      id: 'post_3',
      publisherName: 'موكب أمنا الزهراء (ع)',
      publisherAvatar: 'assets/images/logo.png',
      isVerified: true,
      location: 'أرشيف الزيارة الأربعينية',
      images: [
        'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=1000&q=80',
        'https://images.unsplash.com/photo-1532629345422-7515f3d16bb6?auto=format&fit=crop&w=1000&q=80',
      ],
      caption: 'من ذاكرة الخدمة الفاطمية المباركة في زيارة الأربعين لعام 2025. صور توثق لحظات البذل والعطاء لخدام الزهراء (ع) 🚩🍵\n#أرشيف_2025 #الزيارة_الأربعينية #خدمة_الحسين',
      likesCount: 312,
      commentsCount: 27,
      isLiked: true,
      isSaved: true,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
      yearTag: '2025',
      comments: [
        CommentModel(
          id: 'c_4',
          userName: 'علي الكربلائي',
          userAvatar: 'https://i.pravatar.cc/150?img=12',
          text: 'أجمل أيام الخدمة، رزقنا الله وإياكم العود والتوفيق كل عام 🤲',
          createdAt: DateTime.now().subtract(const Duration(days: 119)),
          likesCount: 15,
        ),
      ],
    ),
  ];

  void toggleLike(String postId) {
    state = [
      for (final p in state)
        if (p.id == postId)
          p.copyWith(
            isLiked: !p.isLiked,
            likesCount: p.isLiked ? p.likesCount - 1 : p.likesCount + 1,
          )
        else
          p
    ];
  }

  void toggleSave(String postId) {
    state = [
      for (final p in state)
        if (p.id == postId) p.copyWith(isSaved: !p.isSaved) else p
    ];
  }

  void addComment(String postId, String commentText, String userName) {
    final newComment = CommentModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userName: userName,
      userAvatar: 'https://i.pravatar.cc/150?img=68',
      text: commentText,
      createdAt: DateTime.now(),
    );

    state = [
      for (final p in state)
        if (p.id == postId)
          p.copyWith(
            commentsCount: p.commentsCount + 1,
            comments: [newComment, ...p.comments],
          )
        else
          p
    ];
  }

  void addPost(PostModel newPost) {
    state = [newPost, ...state];
  }
}
