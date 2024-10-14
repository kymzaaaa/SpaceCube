import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/like_button_widget.dart';  // LikeButtonWidgetをインポート

class PostDetailPage extends StatelessWidget {
  final String uid;
  final String text;
  final String? imageUrl;
  final int likes;  // likesプロパティを追加
  final Timestamp timestamp;
  final String postId;
  final String? username;
  final String? profileImageUrl;

  PostDetailPage({
    required this.uid,
    required this.text,
    this.imageUrl,
    required this.likes,  // likesを追加
    required this.timestamp,
    required this.postId,
    this.username,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ポスト詳細'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: profileImageUrl != null
                      ? NetworkImage(profileImageUrl!)
                      : AssetImage('assets/images/default.png') as ImageProvider,
                ),
                SizedBox(width: 10),
                Text(
                  username ?? 'Unknown',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(text, style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            if (imageUrl != null)
              Image.network(imageUrl!),
            SizedBox(height: 20),
            // いいねボタンとタイムスタンプを同じ行に配置
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                LikeButtonWidget(
                  key: UniqueKey(), // ユニークなキー
                  postId: postId,    // postIdを渡す
                ),
                Text(
                  '${timestamp.toDate()}',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
