import 'package:cloud_firestore/cloud_firestore.dart';

class BukBukCategoryModel {
  final Map<String, String> names;
  final DateTime createdAt;
  final String docId;

  BukBukCategoryModel({
    required this.names,
    required this.createdAt,
    required this.docId,
  });

  factory BukBukCategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return BukBukCategoryModel(
      names: Map<String, String>.from(data['names'] ?? {}),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      docId: doc.id,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'names': names,
      'created_at': createdAt,
    };
  }
}
