import 'package:cloud_firestore/cloud_firestore.dart';

class CoverCategoryModel {
  final String docId;
  final Map<String, String> names;
  final DateTime createdAt;

  CoverCategoryModel({
    required this.docId,
    required this.names,
    required this.createdAt,
  });

  factory CoverCategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CoverCategoryModel(
      docId: doc.id,
      names: Map<String, String>.from(data['names'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

class CoverImage {
  final String docId;
  final String imageUrl;

  CoverImage({required this.docId, required this.imageUrl});
}
