import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class BukBukPost {
  final String? postId;
  final String? coverImage;
  final String? newCover;
  final String? sapereUrl;
  final String? sapereId;
  final String? sapereCategoryId;
  final String? language;
  final List<String>? description;
  final Timestamp? publishTime;
  final String? uId;
  final String? sapereName;
  final String? type;
  final Map<String, String>? sapereTypeNames;
  final Map<String, String>? sapereCategoryNames;
  final bool? isTypeBuy;
  final bool? isDownloadPurchased;
  final ShippingModel? shippingModel;
  final String? gamificationSubject;
  final int? gamificationEpisode;
  final String? languageCode;

  BukBukPost({
    this.postId,
    this.coverImage,
    this.newCover,
    this.sapereUrl,
    this.sapereId,
    this.sapereCategoryId,
    this.language,
    this.description,
    this.publishTime,
    this.uId,
    this.sapereName,
    this.sapereCategoryNames,
    this.type,
    this.sapereTypeNames,
    this.isTypeBuy,
    this.isDownloadPurchased,
    this.shippingModel,
    this.gamificationSubject,
    this.gamificationEpisode,
    this.languageCode,
  });
  factory BukBukPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final String? cover = data['newCover'] ?? data['coverImage'];
    return BukBukPost(
      postId: doc.id,
      coverImage: cover,
      newCover: cover,
      sapereUrl: data['bukbukUrl'],
      sapereId: data['bukbukId'],
      sapereCategoryId: data['bukbukCategoryId'],
      language: data['language'],
      description: List<String>.from(data['description'] ?? []),
      publishTime: data['publishTime'],
      uId: data['uId'],
      sapereName: data['bukbukName'],
      type: data['type'],
      sapereTypeNames: Map<String, String>.from(data['bukbukTypeNames'] ?? {}),
      sapereCategoryNames: Map<String, String>.from(
        data['bukbukCategoryNames'] ?? {},
      ),
      isTypeBuy: data['isTypeBuy'],
      isDownloadPurchased: data['isDownloadPurchased'],
      shippingModel:
          data['shippingModel'] != null
              ? ShippingModel.fromMap(
                Map<String, dynamic>.from(data['shippingModel']),
              )
              : null,
      gamificationSubject: data['gamificationSubject'],
      gamificationEpisode: data['gamificationEpisode'],
      languageCode: data['languageCode'],
    );
  }

  BukBukPost copyWith({
    String? postId,
    String? coverImage,
    String? newCover,
    String? language,
    String? sapereUrl,
    String? sapereId,
    String? sapereCategoryId,
    List<String>? description,
    Timestamp? publishTime,
    String? uId,
    String? sapereName,
    Map<String, String>? sapereCategoryNames,
    String? type,
    Map<String, String>? sapereTypeNames,
    bool? isTypeBuy,
    bool? isDownloadPurchased,
    ShippingModel? shippingModel,
    String? gamificationSubject,
    int? gamificationEpisode,
  }) {
    return BukBukPost(
      postId: postId ?? this.postId,
      coverImage: coverImage ?? newCover ?? this.coverImage,
      newCover: newCover ?? coverImage ?? this.newCover,
      sapereUrl: sapereUrl ?? this.sapereUrl,
      language: language ?? this.language,
      sapereId: sapereId ?? this.sapereId,
      sapereCategoryId: sapereCategoryId ?? this.sapereCategoryId,
      description: description ?? this.description,
      publishTime: publishTime ?? this.publishTime,
      uId: uId ?? this.uId,
      sapereName: sapereName ?? this.sapereName,
      sapereCategoryNames: sapereCategoryNames ?? this.sapereCategoryNames,
      type: type ?? this.type,
      sapereTypeNames: sapereTypeNames ?? this.sapereTypeNames,
      isTypeBuy: isTypeBuy ?? this.isTypeBuy,
      isDownloadPurchased: isDownloadPurchased ?? this.isDownloadPurchased,
      shippingModel: shippingModel ?? this.shippingModel,
      gamificationSubject: gamificationSubject ?? this.gamificationSubject,
      gamificationEpisode: gamificationEpisode ?? this.gamificationEpisode,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  @override
  String toString() {
    return 'Post(postId: $postId, coverImage: $coverImage, newCover: $newCover, bukbukUrl: $sapereUrl,language: $language, bukbukId: $sapereId, bukbukCategoryId: $sapereCategoryId, description: $description, publishTime: $publishTime, uId: $uId, bukbukName: $sapereName, type: $type, bukbukTypeNames: $sapereTypeNames, bukbukCategoryNames: $sapereCategoryNames, isTypeBuy: $isTypeBuy, isDownloadPurchased: $isDownloadPurchased, shippingModel: $shippingModel, gamificationSubject: $gamificationSubject, gamificationEpisode: $gamificationEpisode, languageCode: $languageCode)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BukBukPost &&
        other.postId == postId &&
        other.coverImage == coverImage &&
        other.newCover == newCover &&
        other.language == language &&
        other.sapereUrl == sapereUrl &&
        other.sapereId == sapereId &&
        other.sapereCategoryId == sapereCategoryId &&
        listEquals(other.description, description) &&
        other.publishTime == publishTime &&
        other.uId == uId &&
        other.sapereName == sapereName &&
        other.sapereCategoryNames == sapereCategoryNames &&
        other.type == type &&
        other.sapereTypeNames == sapereTypeNames &&
        other.isTypeBuy == isTypeBuy &&
        other.isDownloadPurchased == isDownloadPurchased &&
        other.shippingModel == shippingModel &&
        other.gamificationSubject == gamificationSubject &&
        other.gamificationEpisode == gamificationEpisode &&
        other.languageCode == languageCode;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      postId,
      coverImage,
      newCover,
      sapereUrl,
      language,
      sapereId,
      sapereCategoryId,
      description,
      publishTime,
      uId,
      sapereName,
      sapereCategoryNames,
      type,
      sapereTypeNames,
      isTypeBuy,
      isDownloadPurchased,
      shippingModel,
      gamificationSubject,
      gamificationEpisode,
      languageCode,
    ]);
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'coverImage': coverImage ?? newCover,
      'newCover': newCover ?? coverImage,
      'bukbukUrl': sapereUrl,
      'language': language,
      'bukbukId': sapereId,
      'bukbukCategoryId': sapereCategoryId,
      'description': description,
      'publishTime': publishTime,
      'uId': uId,
      'bukbukName': sapereName,
      'bukbukCategoryNames': sapereCategoryNames,
      'type': type,
      'bukbukTypeNames': sapereTypeNames,
      'isTypeBuy': isTypeBuy,
      'isDownloadPurchased': isDownloadPurchased,
      'shippingModel': shippingModel?.toMap(),
      'gamificationSubject': gamificationSubject,
      'gamificationEpisode': gamificationEpisode,
      'languageCode': languageCode,
    };
  }

  factory BukBukPost.fromMap(Map<String, dynamic> map) {
    final String? cover = map['newCover'] ?? map['coverImage'];
    return BukBukPost(
      postId: map['postId'],
      coverImage: cover,
      newCover: cover,
      sapereUrl: map['bukbukUrl'],
      language: map['language'],
      sapereId: map['bukbukId'],
      sapereCategoryId: map['bukbukCategoryId'],
      description:
          map['description'] != null
              ? List<String>.from(map['description'])
              : null,
      publishTime: map['publishTime'],
      uId: map['uId'],
      sapereName: map['bukbukName'],
      sapereCategoryNames:
          map['bukbukCategoryNames'] != null
              ? Map<String, String>.from(map['bukbukCategoryNames'])
              : null,
      type: map['type'],
      sapereTypeNames:
          map['bukbukTypeNames'] != null
              ? Map<String, String>.from(map['bukbukTypeNames'])
              : null,
      isTypeBuy: map['isTypeBuy'],
      isDownloadPurchased: map['isDownloadPurchased'],
      shippingModel:
          map['shippingModel'] != null
              ? ShippingModel.fromMap(
                Map<String, dynamic>.from(map['shippingModel']),
              )
              : null,
      gamificationSubject: map['gamificationSubject'],
      gamificationEpisode: map['gamificationEpisode'],
      languageCode: map['languageCode'],
    );
  }

  String toJson() => json.encode(toMap());

  factory BukBukPost.fromJson(String source) =>
      BukBukPost.fromMap(json.decode(source));
}

class ShippingModel {
  final String? bookId;
  final String? fullName;
  final String? shippingAddress;
  final String? streetNumber;
  final String? floorNumber;
  final String? city;
  final String? uId;
  final String? postUid;
  final String? postalCode;
  final String? phoneNumber;
  final String? email;

  ShippingModel({
    this.bookId,
    this.fullName,
    this.shippingAddress,
    this.streetNumber,
    this.floorNumber,
    this.city,
    this.uId,
    this.postUid,
    this.postalCode,
    this.phoneNumber,
    this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'fullName': fullName,
      'shippingAddress': shippingAddress,
      'streetNumber': streetNumber,
      'floorNumber': floorNumber,
      'city': city,
      'uId': uId,
      'postUid': postUid,
      'postalCode': postalCode,
      'phoneNumber': phoneNumber,
      'email': email,
    };
  }

  factory ShippingModel.fromMap(Map<String, dynamic> map) {
    return ShippingModel(
      bookId: map['bookId'],
      fullName: map['fullName'],
      shippingAddress: map['shippingAddress'],
      streetNumber: map['streetNumber'],
      floorNumber: map['floorNumber'],
      city: map['city'],
      uId: map['uId'],
      postUid: map['postUid'],
      postalCode: map['postalCode'],
      phoneNumber: map['phoneNumber'],
      email: map['email'],
    );
  }

  String toJson() => json.encode(toMap());

  factory ShippingModel.fromJson(String source) =>
      ShippingModel.fromMap(json.decode(source));
}
