import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // メールアドレスでのログイン処理
  Future<void> _loginWithEmail() async {
    try {
      await _auth.signInWithEmailAndPassword(
          email: emailController.text, password: passwordController.text);
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      print(e);
    }
  }

  // Googleサインインでのログイン処理
  Future<void> _loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        scopes: ['email', 'profile'],
      ).signIn();

      if (googleUser == null) {
        // ユーザーがサインインをキャンセルした場合
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebaseでサインイン
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Firestoreでユーザーが存在するかを確認
      final User? user = userCredential.user;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();

      if (userDoc.exists) {
        // ユーザーがFirestoreに存在する場合のみログイン成功
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Firestoreにユーザーが存在しない場合はログアウトする
        await _auth.signOut();
        await GoogleSignIn().signOut(); // Googleからもサインアウト
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('このGoogleアカウントは未登録です。新規登録を行ってください。'),
        ));
      }
    } catch (e) {
      print('Googleサインインエラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Googleサインインに失敗しました。もう一度お試しください。'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ログイン')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'メールアドレス'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'パスワード'),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: _loginWithEmail,
              child: Text('メールでログイン'),
            ),
            ElevatedButton(
              onPressed: _loginWithGoogle,
              child: Text('Googleでログイン'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: Text('新規登録はこちら'),
            ),
          ],
        ),
      ),
    );
  }
}
