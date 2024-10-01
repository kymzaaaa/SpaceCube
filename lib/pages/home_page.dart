import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/sidebar.dart'; // サイドバーをインポート

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;
  bool isVerified = false;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    _checkEmailVerification();  // メール認証状態をチェック
  }

  // メール認証状態を定期的に確認
  Future<void> _checkEmailVerification() async {
    if (user != null && !user!.emailVerified) {
      Future.delayed(Duration(seconds: 5), () async {
        await user!.reload();
        user = _auth.currentUser;

        setState(() {
          isVerified = user!.emailVerified;
        });

        if (isVerified) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('メールが認証されました！'),
          ));
        } else {
          _checkEmailVerification();
        }
      });
    }
  }

  // 手動で更新ボタンを押して確認
  Future<void> _manualCheck() async {
    await user!.reload();
    user = _auth.currentUser;

    setState(() {
      isVerified = user!.emailVerified;
    });

    if (isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('メールが認証されました！'),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('まだメールが認証されていません。'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user != null && !isVerified) {
      return Scaffold(
        appBar: AppBar(title: Text('メール認証が必要です')),
        drawer: Sidebar(), // サイドバーを追加
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('メールアドレスがまだ確認されていません。'),
              ElevatedButton(
                onPressed: () async {
                  await user!.sendEmailVerification();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('確認メールを再送信しました。'),
                  ));
                },
                child: Text('確認メールを再送信'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _manualCheck,
                child: Text('手動で更新'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('ホームページ')),
      drawer: Sidebar(), // 認証後にもサイドバーを表示
      body: Center(
        child: Text('ようこそ！メールが認証されました。'),
      ),
    );
  }
}
