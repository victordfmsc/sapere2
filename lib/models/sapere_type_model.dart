import 'package:cloud_firestore/cloud_firestore.dart';

class BukBukTypeModel {
  final String id;
  final int order;
  final Timestamp createdAt;
  final Map<String, String> names;
  final Map<String, String> prompts;
  final Map<String, String> descriptions;
  final String photoUrl;
  final bool isProOnly;
  final bool userapp;

  BukBukTypeModel({
    required this.id,
    required this.order,
    required this.createdAt,
    required this.names,
    required this.prompts,
    required this.descriptions,
    required this.photoUrl,
    required this.isProOnly,
    required this.userapp,
  });

  factory BukBukTypeModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return BukBukTypeModel(
      id: data['docId'] ?? '',
      order: data['order'] ?? 0,
      createdAt: data['created_at'] ?? Timestamp.now(),
      names: Map<String, String>.from(data['names'] ?? {}),
      prompts: Map<String, String>.from(data['prompts'] ?? {}),
      descriptions: Map<String, String>.from(data['descriptions'] ?? {}),
      photoUrl: data['photoUrl'] ?? '',
      isProOnly: data['isProOnly'] ?? false,
      userapp: data['userapp'] ?? false,
    );
  }
}
