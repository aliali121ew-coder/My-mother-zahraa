import 'package:flutter/foundation.dart';

@immutable
class PostModel {
  const PostModel({
    required this.id,
    required this.publisherName,
    required this.publisherAvatar,
    this.isVerified = true,
    this.location,
    required this.images,
    required this.caption,
    required this.likesCount,
    required this.commentsCount,
    this.isLiked = false,
    this.isSaved = false,
    required this.createdAt,
    required this.yearTag,
    this.comments = const [],
    this.audioTrackTitle,
  });

  final String id;
  final String publisherName;
  final String publisherAvatar;
  final bool isVerified;
  final String? location;
  final List<String> images;
  final String caption;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final bool isSaved;
  final DateTime createdAt;
  final String yearTag;
  final List<CommentModel> comments;
  final String? audioTrackTitle;

  PostModel copyWith({
    String? id,
    String? publisherName,
    String? publisherAvatar,
    bool? isVerified,
    String? location,
    List<String>? images,
    String? caption,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    bool? isSaved,
    DateTime? createdAt,
    String? yearTag,
    List<CommentModel>? comments,
    String? audioTrackTitle,
  }) {
    return PostModel(
      id: id ?? this.id,
      publisherName: publisherName ?? this.publisherName,
      publisherAvatar: publisherAvatar ?? this.publisherAvatar,
      isVerified: isVerified ?? this.isVerified,
      location: location ?? this.location,
      images: images ?? this.images,
      caption: caption ?? this.caption,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      createdAt: createdAt ?? this.createdAt,
      yearTag: yearTag ?? this.yearTag,
      comments: comments ?? this.comments,
      audioTrackTitle: audioTrackTitle ?? this.audioTrackTitle,
    );
  }
}

@immutable
class StoryModel {
  const StoryModel({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.items,
    this.isViewed = false,
  });

  final String id;
  final String title;
  final String coverUrl;
  final List<StoryItemModel> items;
  final bool isViewed;

  StoryModel copyWith({
    String? id,
    String? title,
    String? coverUrl,
    List<StoryItemModel>? items,
    bool? isViewed,
  }) {
    return StoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      items: items ?? this.items,
      isViewed: isViewed ?? this.isViewed,
    );
  }
}

@immutable
class StoryItemModel {
  const StoryItemModel({
    required this.id,
    required this.imageUrl,
    this.caption,
    this.durationSeconds = 5,
  });

  final String id;
  final String imageUrl;
  final String? caption;
  final int durationSeconds;
}

@immutable
class CommentModel {
  const CommentModel({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.text,
    required this.createdAt,
    this.likesCount = 0,
    this.isLiked = false,
  });

  final String id;
  final String userName;
  final String userAvatar;
  final String text;
  final DateTime createdAt;
  final int likesCount;
  final bool isLiked;

  CommentModel copyWith({
    String? id,
    String? userName,
    String? userAvatar,
    String? text,
    DateTime? createdAt,
    int? likesCount,
    bool? isLiked,
  }) {
    return CommentModel(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
