import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LikeButtonWidget extends StatefulWidget {
  final String postId;

  LikeButtonWidget({
    required Key key,
    required this.postId,
  }) : super(key: key);

  @override
  _LikeButtonWidgetState createState() => _LikeButtonWidgetState();
}

class _LikeButtonWidgetState extends State<LikeButtonWidget> {
  bool isLiked = false;
  int likeCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLikeStatus(); // Firestoreからデータを取得
  }

  // Firestoreからいいね数を取得する処理
  Future<void> _fetchLikeStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // ユーザーが未ログインの場合は何もしない

    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);

    try {
      final postSnapshot = await postRef.get();
      if (postSnapshot.exists) {
        final data = postSnapshot.data() as Map<String, dynamic>;

        // Firestoreからlikesの数を取得
        final currentLikeCount = data['likes'] ?? 0; // `likes`がない場合は0を使用

        // likedByフィールドがリストかどうかを確認し、違う場合は空リストを使う
        final likedBy = (data['likedBy'] is List)
            ? List<String>.from(data['likedBy']) // リストとしてキャスト
            : <String>[]; // リストでない場合は空リストにフォールバック

        // 既にいいねされているかどうかを確認
        final userLiked = likedBy.contains(user.uid);

        // 取得したデータを画面に反映
        if (mounted) {
          setState(() {
            likeCount = currentLikeCount;
            isLiked = userLiked;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('エラーが発生しました: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // いいねボタンを押した時の処理
  Future<void> _likePost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // ユーザーが未ログインの場合は何もしない

    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final postSnapshot = await transaction.get(postRef);
        if (!postSnapshot.exists) return;

        final data = postSnapshot.data() as Map<String, dynamic>;
        final currentLikeCount = data['likes'] ?? 0; // `likes`がない場合は0を使用

        // likedByフィールドがリストかどうかを確認し、違う場合は空リストを使う
        final likedBy = (data['likedBy'] is List)
            ? List<String>.from(data['likedBy'])
            : <String>[]; // リストでない場合は空リストにフォールバック

        // いいねをトグル（切り替え）する
        if (isLiked) {
          // いいねを取り消す
          transaction.update(postRef, {
            'likes': FieldValue.increment(-1),
            'likedBy': FieldValue.arrayRemove([user.uid]), // リストからユーザーIDを削除
          });
          setState(() {
            isLiked = false;
            likeCount = currentLikeCount - 1;
          });
        } else {
          // いいねを追加
          transaction.update(postRef, {
            'likes': FieldValue.increment(1),
            'likedBy': FieldValue.arrayUnion([user.uid]), // リストにユーザーIDを追加
          });
          setState(() {
            isLiked = true;
            likeCount = currentLikeCount + 1;
          });
        }
      });
    } catch (e) {
      print('エラーが発生しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Row(
      children: [
        IconButton(
          icon: Icon(
            Icons.thumb_up,
            color: isLiked ? Colors.red : Colors.grey, // いいね済みの場合は赤く表示
          ),
          onPressed: _likePost, // いいねボタンを押す処理
        ),
        Text('Likes: $likeCount'),
      ],
    );
  }
}
