import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';  // image_picker パッケージ
import 'dart:io';  // File を扱うためにインポート
import 'package:firebase_storage/firebase_storage.dart';  // Firebase Storage

class NewPost extends StatefulWidget {
  @override
  _NewPostState createState() => _NewPostState();
}

class _NewPostState extends State<NewPost> {
  final TextEditingController _textController = TextEditingController();
  final int _maxCharacters = 140; // 140文字の制限
  final int _maxLines = 10; // 最大10行の制限
  String? currentUserUID;  // UIDの保存
  File? _imageFile; // 選択された画像ファイル
  final ImagePicker _picker = ImagePicker(); // 画像選択のためのインスタンス
  String? errorMessage; // エラーメッセージを保持する変数

  @override
  void initState() {
    super.initState();
    _fetchUserUID();  // FirebaseAuthからユーザーのUIDを取得
  }

  // FirebaseAuthから現在のユーザーのUIDを取得
  Future<void> _fetchUserUID() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentUserUID = user.uid;  // FirebaseAuthのUIDを取得して設定
      });
    }
  }

  // 画像を選択するメソッド
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);  // 選択された画像ファイルをセット
      });
    }
  }

  // 画像をFirebase Storageにアップロードするメソッド
  Future<String?> _uploadImageToStorage() async {
    if (_imageFile == null) return null;

    try {
      // 画像をFirebase Storageにアップロード
      String fileName = 'posts/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(_imageFile!);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();  // アップロードされた画像のURLを取得
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Firestoreに投稿を追加する関数
  Future<void> _createPost() async {
    if (_textController.text.isEmpty ||
        _textController.text.length > _maxCharacters ||
        _countLines(_textController.text) > _maxLines ||
        currentUserUID == null) {
      return; // エラーがある場合は投稿しない
    }

    String? imageUrl = await _uploadImageToStorage();  // 画像をアップロードし、URLを取得

    // Firestoreにデータを保存。null 値のフィールドには空の文字列を入れてエラーを回避
    await FirebaseFirestore.instance.collection('posts').add({
      'uid': currentUserUID,  // 投稿者のUIDを保存
      'text': _textController.text.isNotEmpty ? _textController.text : '',  // null の場合に空文字にする
      'imageUrl': imageUrl,  // 画像がない場合にはnullをそのまま保存
      'likes': 0,
      'timestamp': Timestamp.now(),
    });

    // 投稿後にテキストフィールドと画像をクリア
    _textController.clear();
    setState(() {
      _imageFile = null;
      errorMessage = null; // エラーメッセージをクリア
    });
  }

  // テキスト内の改行数を数えて最大行数に制限
  int _countLines(String text) {
    int lines = '\n'.allMatches(text).length + 1; // 改行を数える
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // 左揃え
      children: [
        currentUserUID == null
            ? CircularProgressIndicator()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start, // 左揃え
                children: [
                  // エラーメッセージの表示
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red), // エラーメッセージは赤色で表示
                      ),
                    ),
                  // 投稿用のテキストフィールド
                  TextField(
                    controller: _textController,
                    minLines: 1, // 初期は1行
                    maxLines: _maxLines, // 最大10行までの制限
                    maxLength: _maxCharacters, // 最大文字数の制限
                    onChanged: (text) {
                      setState(() {
                        if (_countLines(text) > _maxLines) {
                          errorMessage = '最大10行までです'; // 行数が制限を超えた場合のエラーメッセージ
                        } else if (text.length > _maxCharacters) {
                          errorMessage = '140文字までです'; // 文字数が制限を超えた場合のエラーメッセージ
                        } else {
                          errorMessage = null; // 問題なければエラーメッセージをクリア
                        }
                      });
                    },
                    decoration: InputDecoration(
                      hintText: '宇宙きてる？',
                      isDense: true, // コンパクトな見た目にする
                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10), // パディングを調整
                      counterText: '', // 文字カウントの表示を非表示にする
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 画像選択ボタンと投稿ボタンとカウンターを横に並べる
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // ボタンとカウンターの間隔を調整
                    children: [
                      // 画像を選択
                      ElevatedButton(
                        onPressed: _pickImage,
                        child: const Text('画像を選択'),
                      ),
                      // 投稿ボタン
                      ElevatedButton(
                        onPressed: currentUserUID == null || errorMessage != null
                            ? null
                            : _createPost,  // エラーがある場合は投稿ボタンを無効化
                        child: const Text('投稿'),
                      ),
                      // 文字数カウンター
                      Text(
                        '${_textController.text.length}/$_maxCharacters',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 選択された画像のプレビュー
                  if (_imageFile != null)
                    Container(
                      width: 150,
                      height: 150,
                      child: Image.file(_imageFile!, fit: BoxFit.cover),
                    ),
                ],
              ),
      ],
    );
  }
}
