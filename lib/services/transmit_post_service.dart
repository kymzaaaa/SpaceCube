import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TransmitPostService {
  // Transmit機能を実装するメソッド
  Future<void> transmitPost(String originalPostId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final postRef = FirebaseFirestore.instance.collection('posts').doc(originalPostId);
    final postSnapshot = await postRef.get();

    if (!postSnapshot.exists) return;

    final originalPost = postSnapshot.data() as Map<String, dynamic>;

    // Transmitを保存するためのフィールド
    final transmitData = {
      'transmitterId': user.uid, // TransmitしたユーザーのID
      'transmitTimestamp': Timestamp.now(), // Transmitのタイムスタンプ
      'originalPostId': originalPostId, // 元のポストID
      'originalPostText': originalPost['text'], // 元のポストのテキスト
      'originalPostUserId': originalPost['uid'], // 元のポストのユーザーID
      'originalPostImageUrl': originalPost['imageUrl'], // 元のポストの画像URL（あれば）
    };

    // FirestoreにTransmitのデータを保存
    await FirebaseFirestore.instance
        .collection('transmits')
        .add(transmitData)
        .then((docRef) {
      print("Transmit成功: ${docRef.id}");
    }).catchError((error) {
      print("Transmit失敗: $error");
    });
  }
}
