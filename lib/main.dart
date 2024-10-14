import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuthをインポート
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();  // Firebase初期化のために必須
  await Firebase.initializeApp();  // Firebaseを初期化
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  User? currentUser;  // ログイン済みのユーザー情報

  @override
  void initState() {
    super.initState();
    _checkLoginState();  // ログイン状態の確認
  }

  // ログイン状態の確認
  void _checkLoginState() {
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      currentUser = user;  // ログイン済みのユーザー情報をセット
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light, // 通常のライトテーマ
        primaryColor: Colors.blue,    // アプリのプライマリカラー
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,  // ダークテーマ
        primaryColor: Colors.blueGrey, // ダークモードのプライマリカラー
        scaffoldBackgroundColor: Colors.black, // 背景を黒に設定
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white),  // 新しいプロパティ名で文字色を明るく設定
          bodyMedium: TextStyle(color: Colors.white), // bodyText2の代わり
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blueGrey, // AppBarの背景色
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20), // AppBarの文字色
        ),
      ),
      themeMode: ThemeMode.dark, // 強制的にダークテーマを適用

      // ログイン済みならホームページ、ログインしていないなら新規登録ページを表示
      home: currentUser == null ? RegisterPage() : HomePage(),
      routes: {
        '/login': (context) => LoginPage(),    // ログインページ
        '/register': (context) => RegisterPage(), // 新規登録ページ
        '/home': (context) => HomePage(), // ホームページ（タイムライン）
      },
    );
  }
}
