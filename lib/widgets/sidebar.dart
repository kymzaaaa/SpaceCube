import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';  // FirebaseAuthをインポート
import '../pages/profile_page.dart';  // プロフィールページをインポート
import '../pages/login_page.dart';  // ログインページをインポート

class Sidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // サイドバーのヘッダー部分
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blueGrey,
            ),
            child: Text(
              'Pineapple and Friends',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          
          // プロフィールボタン
          ListTile(
            leading: Icon(Icons.person),
            title: Text('プロフィール'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => ProfilePage())
              );  // プロフィールページに遷移
            },
          ),

          Divider(),

          // グループ機能の削除に伴い、Firestoreやグループ表示部分も削除

          // ログアウトボタンを追加
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('ログアウト'),
            onTap: () async {
              // ログアウト処理
              await FirebaseAuth.instance.signOut();
              
              // ログインページに戻る
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => LoginPage())
              );
            },
          ),
        ],
      ),
    );
  }
}
