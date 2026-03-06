import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/models/public_post.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../providers/user_provider.dart';
import 'widgets/comment_field.dart';
import 'widgets/comment_widget.dart';

class CommentScreen extends StatefulWidget {
  final List<dynamic> comments;
  final String postId;

  const CommentScreen({
    super.key,
    required this.comments,
    required this.postId, // Add postId parameter
  });

  @override
  _CommentScreenState createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<void> _addComment(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (_commentController.text.isNotEmpty) {
      final comment = Comment(
        uid: _firebaseAuth.currentUser?.uid,
        username: userProvider.user?.userName.toString(),
        commenterImageUrl: userProvider.user?.profileImage.toString(),
        commentText: _commentController.text,
        publishTime: DateTime.now().toIso8601String(),
      );

      final postDoc = _firestore.collection('community').doc(widget.postId);

      await postDoc.update({
        'comments': FieldValue.arrayUnion([comment.toMap()])
      });

      setState(() {
        widget.comments.add(comment);
      });

      _commentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    print(widget.postId);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textColor,
        title: Text(
          'comments'.tr,
          style: TextStyle(color: AppColors.textColor),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.comments.isEmpty
                ? Center(
                    child: Text(
                    'noCommentsYet'.tr,
                    style: TextStyle(color: AppColors.textColor),
                  ))
                : ListView.builder(
                    itemCount: widget.comments.length,
                    itemBuilder: (context, index) {
                      final comment = widget.comments[index];
                      return CommentWidget(
                        username: comment.username.toString(),
                        timestamp: comment.publishTime.toString(),
                        comment: comment.commentText.toString(),
                        image: comment.commenterImageUrl.toString(),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomSheet: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 18.0),
          child: QuestionTextField(
            focusNode: focusNode,
            controller: _commentController,
            onPressed: () {
              FocusScope.of(context).unfocus();

              if (_commentController.text.isNotEmpty) {
                _addComment(context);
              }
            },
          ),
        ),
      ),
    );
  }
}
