import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/sidebar.dart';  // サイドバーをインポート

class EmailVerificationPage extends StatefulWidget {
  final User user;
  const EmailVerificationPage({required this.user});

  @override
  _EmailVerificationPageState createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool isVerified = false;

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
  }

  Future<void> _checkEmailVerification() async {
    if (!widget.user.emailVerified) {
      Future.delayed(Duration(seconds: 5), () async {
        await widget.user.reload();
        setState(() {
          isVerified = widget.user.emailVerified;
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

  Future<void> _manualCheck() async {
    await widget.user.reload();
    setState(() {
      isVerified = widget.user.emailVerified;
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
    if (!isVerified) {
      return Scaffold(
        appBar: AppBar(title: Text('メール認証が必要です')),
        drawer: Sidebar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('メールアドレスがまだ確認されていません。'),
              ElevatedButton(
                onPressed: () async {
                  await widget.user.sendEmailVerification();
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
      drawer: Sidebar(),
      body: Center(
        child: Text('ようこそ！メールが認証されました。'),
      ),
    );
  }
}
