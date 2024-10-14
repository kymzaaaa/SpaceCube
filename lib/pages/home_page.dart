import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/post_tile.dart';
import '../widgets/sidebar.dart';
import '../widgets/new_post.dart';
import '../services/ranking_service.dart'; // ランキングサービスをインポート
import '../services/following_service.dart'; // フォロー中の投稿サービスをインポート

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> followingUserIds = [];
  bool isLoading = true;
  User? currentUser = FirebaseAuth.instance.currentUser;

  final RankingService _rankingService = RankingService();
  final FollowingService _followingService = FollowingService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchFollowingUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchFollowingUsers() async {
    if (currentUser != null) {
      final followingSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('following')
          .get();

      setState(() {
        followingUserIds = followingSnapshot.docs.map((doc) => doc.id).toList();
        followingUserIds.add(currentUser!.uid); // 自分のユーザーIDを追加
        isLoading = false;
      });
    }
  }

  // 下に引っ張ってデータを更新するメソッド
  Future<void> _refreshData() async {
    await _fetchFollowingUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('タイムライン'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'フォロー中'),
            Tab(text: '今日'),
            Tab(text: '週'),
            Tab(text: '月'),
          ],
        ),
      ),
      drawer: Sidebar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: NewPost(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFollowingTimeline(),
                _buildRankingTimeline('day'),
                _buildRankingTimeline('week'),
                _buildRankingTimeline('month'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // フォロー中のユーザーの投稿を表示
  Widget _buildFollowingTimeline() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (followingUserIds.isEmpty) {
      return Center(child: Text("フォローしてみましょう！"));
    }

    if (followingUserIds.length <= 10) {
      return RefreshIndicator(
        onRefresh: _refreshData, // 下に引っ張ったときにデータを再読み込み
        child: StreamBuilder<QuerySnapshot>(
          stream: _followingService.getPostsForFollowing(followingUserIds),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text("投稿を取得できませんでした"));
            }

            final posts = snapshot.data?.docs ?? [];

            if (posts.isEmpty) {
              return Center(child: Text("フォロー中のユーザーの投稿がありません"));
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
        ),
      );
    } else {
      return RefreshIndicator(
        onRefresh: _refreshData, // データの再読み込み
        child: FutureBuilder<List<DocumentSnapshot>>(
          future: _followingService.fetchPostsForFollowing(followingUserIds),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text("投稿を取得できませんでした"));
            }

            final posts = snapshot.data ?? [];

            if (posts.isEmpty) {
              return Center(child: Text("フォロー中のユーザーの投稿がありません"));
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
        ),
      );
    }
  }

  // ランキングの投稿を表示
  Widget _buildRankingTimeline(String period) {
    return RefreshIndicator(
      onRefresh: _refreshData, // 下に引っ張ったときにデータを再読み込み
      child: StreamBuilder<QuerySnapshot>(
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
      ),
    );
  }
}
