// StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
//   stream:
//       FirebaseFirestore.instance
//           .collection(sapereCollection)
//           .doc(widget.post.postId)
//           .snapshots(),
//   builder: (context, snap) {
//     if (snap.connectionState == ConnectionState.waiting ||
//         !snap.hasData) {
//       return audioGeneratingBanner();
//     }
//
//     final data = snap.data!.data();
//     final String? url = (data?['bukbukUrl'] as String?)?.trim();
//
//     final bool hasUrl = url != null && url.isNotEmpty;
//     return hasUrl ? const SizedBox() : audioGeneratingBanner();
//   },
// ),