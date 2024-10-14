import 'package:cloud_firestore/cloud_firestore.dart';

class RankingService {
  // ランキングの投稿を取得する
  Stream<QuerySnapshot> getRankingPosts(String period) {
    DateTime now = DateTime.now();
    Timestamp startTime;

    if (period == 'day') {
      startTime = Timestamp.fromDate(DateTime(now.year, now.month, now.day));
    } else if (period == 'week') {
      startTime = Timestamp.fromDate(now.subtract(Duration(days: 7)));
    } else {
      startTime = Timestamp.fromDate(now.subtract(Duration(days: 30)));
    }

    // 最大30ポストまで表示するように制限を変更
    return FirebaseFirestore.instance
        .collection('posts')
        .where('timestamp', isGreaterThanOrEqualTo: startTime)
        .orderBy('likes', descending: true)
        .limit(30) // ここで制限を30ポストに設定
        .snapshots();
  }
}
