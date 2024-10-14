import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_setup_page.dart';  // プロフィールページをインポート

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();

  // メールとパスワードでの新規登録処理
  Future<void> _register() async {
    try {
      // Firebase Authentication でアカウントを作成
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      User? user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'username': usernameController.text,
          'email': user.email,
          'createdAt': Timestamp.now(),
        });

        // メール確認を送信
        if (!user.emailVerified) {
          await user.sendEmailVerification();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('確認メールが送信されました。メールを確認してください。'),
            ));
          }
        }

        // プロフィール登録ページに遷移
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileSetupPage(userId: user.uid), // プロフィール登録ページに遷移
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('アカウント作成に失敗しました: $e'),
        ));
      }
    }
  }

  // Googleでの新規登録処理
  Future<void> _registerWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // ユーザーがサインインをキャンセルした場合
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Firestoreにユーザーが既に登録されているか確認
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          // Firestoreに新規ユーザーとして登録
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'username': user.displayName ?? 'Unknown', // Googleから取得した名前
            'email': user.email,
            'createdAt': Timestamp.now(),
          });
        }

        // プロフィール登録ページに遷移
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileSetupPage(userId: user.uid), // プロフィール登録ページに遷移
            ),
          );
        }
      }
    } catch (e) {
      print('Google登録エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Googleでのアカウント作成に失敗しました: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新規登録')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'ユーザー名'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'メールアドレス'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'パスワード'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              child: const Text('アカウント作成'),
            ),
            ElevatedButton(
              onPressed: _registerWithGoogle,
              child: const Text('Googleで登録'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // ログイン画面に戻る
              },
              child: const Text('ログイン画面に戻る'),
            ),
          ],
        ),
      ),
    );
  }
}
