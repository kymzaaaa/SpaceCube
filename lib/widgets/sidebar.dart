import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  // グループのアイコンをリストで保持
  final List<String> joinedGroupIcons = [
    'assets/group1.png',  // アイコンのパス (仮)
    'assets/group2.png',
    'assets/group3.png',
  ];

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

          // グループ作成ボタン
          ListTile(
            leading: Icon(Icons.add),
            title: Text('グループ作成'),
            onTap: () {
              _createGroup(context);  // グループ作成機能の呼び出し
            },
          ),

          Divider(),

          // 参加済みグループのアイコンリストを表示
          Expanded(
            child: ListView.builder(
              itemCount: joinedGroupIcons.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: AssetImage(joinedGroupIcons[index]),
                    radius: 20,
                  ),
                  title: Text('Group ${index + 1}'),  // 仮のグループ名
                  onTap: () {
                    // グループ選択時の処理
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // グループ作成時の処理 (モックアップ)
  void _createGroup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('グループ作成'),
          content: TextField(
            decoration: InputDecoration(hintText: 'グループ名を入力'),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('作成'),
              onPressed: () {
                Navigator.of(context).pop();
                // グループ作成ロジックをここに追加
              },
            ),
          ],
        );
      },
    );
  }
}
