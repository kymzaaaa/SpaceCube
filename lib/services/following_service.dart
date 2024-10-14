import 'package:cloud_firestore/cloud_firestore.dart';

class FollowingService {
  // フォローしているユーザーの投稿を取得する（10人以下の場合）
  Stream<QuerySnapshot> getPostsForFollowing(List<String> userIds) {
    return FirebaseFirestore.instance
        .collection('posts')
        .where('uid', whereIn: userIds)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // フォローしているユーザーの投稿を取得する（10人を超える場合、分割して取得）
  Future<List<DocumentSnapshot>> fetchPostsForFollowing(List<String> followingUserIds) async {
    List<DocumentSnapshot> allPosts = [];

    for (int i = 0; i < followingUserIds.length; i += 10) {
      List<String> batch = followingUserIds.sublist(i, i + 10 > followingUserIds.length ? followingUserIds.length : i + 10);

      QuerySnapshot batchSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('uid', whereIn: batch)
          .orderBy('timestamp', descending: true)
          .get();

      allPosts.addAll(batchSnapshot.docs);
    }

    return allPosts;
  }
}
