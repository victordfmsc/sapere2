class PublicPost {
  String? coverImage;
  String? newCover;
  String? pdfUrl;
  String? description;
  String? publishTime;
  String? dairyName;
  String? type;
  String? language;
  String? postId;
  int? totalLikes;
  List<dynamic>? likeByMe;
  List<dynamic>? saveByMeByMe;
  int? totalComments;
  List<Comment>? comments;
  UserPublicPost? creator;

  PublicPost({
    this.coverImage,
    this.newCover,
    this.pdfUrl,
    this.description,
    this.publishTime,
    this.dairyName,
    this.type,
    this.language,
    this.postId,
    this.totalLikes,
    this.likeByMe,
    this.saveByMeByMe,
    this.totalComments,
    this.comments,
    this.creator,
  });

  Map<String, dynamic> toMap() {
    final String? cover = newCover ?? coverImage;
    return {
      'coverImage': cover,
      'newCover': cover,
      'pdfUrl': pdfUrl,
      'description': description,
      'publishTime': publishTime,
      'dairyName': dairyName,
      'type': type,
      'language': language,
      'postId': postId,
      'totalLikes': totalLikes ?? 0,
      'likeByMe': likeByMe ?? [],
      'saveByMeByMe': saveByMeByMe ?? [],
      'totalComments': totalComments ?? 0,
      'comments': comments?.map((comment) => comment.toMap()).toList(),
      'creator': creator?.toMap(),
    };
  }

  PublicPost.fromMap(Map<String, dynamic> map)
    : coverImage = map['newCover'] ?? map['coverImage'],
      newCover = map['newCover'] ?? map['coverImage'],
      pdfUrl = map['pdfUrl'],
      description = map['description'],
      publishTime = map['publishTime'],
      dairyName = map['dairyName'],
      type = map['type'],
      language = map['language'],
      postId = map['postId'],
      totalLikes = map['totalLikes'],
      likeByMe = map['likeByMe'],
      saveByMeByMe = map['saveByMeByMe'],
      totalComments = map['totalComments'],
      comments =
          (map['comments'] as List?)
              ?.map((comment) => Comment.fromMap(comment))
              .toList(),
      creator =
          map['creator'] != null
              ? UserPublicPost.fromMap(map['creator'])
              : null;
}

class UserPublicPost {
  String? name;
  String? imageUrl;
  String? uid;

  UserPublicPost({this.name, this.imageUrl, this.uid});

  Map<String, dynamic> toMap() {
    return {'name': name, 'imageUrl': imageUrl, 'uid': uid};
  }

  UserPublicPost.fromMap(Map<String, dynamic> map)
    : name = map['name'],
      imageUrl = map['imageUrl'],
      uid = map['uid'];
}

class Comment {
  String? uid;
  String? username;
  String? commenterImageUrl;
  String? commentText;
  String? publishTime;

  Comment({
    this.uid,
    this.username,
    this.commenterImageUrl,
    this.commentText,
    this.publishTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'commenterImageUrl': commenterImageUrl,
      'commentText': commentText,
      'publishTime': publishTime,
    };
  }

  Comment.fromMap(Map<String, dynamic> map)
    : uid = map['uid'],
      username = map['username'],
      commenterImageUrl = map['commenterImageUrl'],
      commentText = map['commentText'],
      publishTime = map['publishTime'];
}
