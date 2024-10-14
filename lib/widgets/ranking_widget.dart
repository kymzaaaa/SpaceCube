import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ranking_service.dart'; // ランキングサービスをインポート
import '../widgets/post_tile.dart'; // ポストウィジェットをインポート

class RankingWidget extends StatelessWidget {
  final String period;

  RankingWidget({required this.period});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController( // DefaultTabController を追加
      length: 3, // タブの数を指定
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: '今日'),
              Tab(text: '週'),
              Tab(text: '月'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildRankingList('day'), // 日のランキングを表示
                _buildRankingList('week'), // 週のランキングを表示
                _buildRankingList('month'), // 月のランキングを表示
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingList(String period) {
    final RankingService _rankingService = RankingService();

    return StreamBuilder<QuerySnapshot>(
      stream: _rankingService.getRankingPosts(period),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data!.docs;

        if (posts.isEmpty) {
          return Center(child: Text("ランキングデータがありません"));
        }

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            var post = posts[index].data() as Map<String, dynamic>;
            return PostTile(
              uid: post['uid'],
              text: post['text'],
              imageUrl: post['imageUrl'],
              likes: post['likes'],
              timestamp: post['timestamp'],
              postId: posts[index].id,
            );
          },
        );
      },
    );
  }
}
