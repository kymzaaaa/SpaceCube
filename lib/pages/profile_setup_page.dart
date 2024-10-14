import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image/image.dart' as img;

class ProfileSetupPage extends StatefulWidget {
  final String userId;

  ProfileSetupPage({required this.userId});

  @override
  _ProfileSetupPageState createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController(); // ユーザーIDのコントローラー
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _portfolioUrlController = TextEditingController();
  final TextEditingController _bioController = TextEditingController(); // Bioのコントローラー
  String? _selectedBadge;
  String? _headerImageUrl; // ヘッダー画像のURL
  String? _profileImageUrl; // プロフィール画像のURL
  File? _headerImageFile; // ヘッダー画像のファイル
  File? _profileImageFile; // プロフィール画像のファイル
  final _formKey = GlobalKey<FormState>(); // フォームのキー

  List<String> badges = [];

  @override
  void initState() {
    super.initState();
    _fetchBadges(); // バッジの取得
  }

  // バッジのリストを取得する関数
  Future<void> _fetchBadges() async {
    QuerySnapshot<Map<String, dynamic>> badgeDocs = await FirebaseFirestore.instance.collection('badges').get();

    setState(() {
      badges = badgeDocs.docs.map((doc) => doc['name'] as String).toList();
    });
  }

  // ユーザー情報を更新する関数
  Future<void> _updateUserData() async {
    if (!_formKey.currentState!.validate()) return;

    await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
      'username': _usernameController.text,
      'userId': _userIdController.text, // ユーザーIDを保存
      'location': _locationController.text,
      'portfolioUrl': _portfolioUrlController.text,
      'Bio': _bioController.text,
      'badge': _selectedBadge,
      'headerImage': _headerImageUrl,
      'profileImageUrl': _profileImageUrl,
      'createdAt': Timestamp.now(), // 初回設定時に作成日を保存
    });

    Navigator.pushReplacementNamed(context, '/home');
  }

  // ヘッダー画像を変更するためのメソッド
  Future<void> _changeHeaderImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      _headerImageFile = await _compressImage(image.path);

      setState(() {});

      final Reference storageRef = FirebaseStorage.instance.ref().child('headers/${widget.userId}');
      await storageRef.putFile(_headerImageFile!);

      _headerImageUrl = await storageRef.getDownloadURL();
    }
  }

  // プロフィール画像を変更するためのメソッド
  Future<void> _changeProfileImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      _profileImageFile = await _compressImage(image.path);

      setState(() {});

      final Reference storageRef = FirebaseStorage.instance.ref().child('profiles/${widget.userId}');
      await storageRef.putFile(_profileImageFile!);

      _profileImageUrl = await storageRef.getDownloadURL();
    }
  }

  // 画像を圧縮するメソッド
  Future<File> _compressImage(String imagePath) async {
    final img.Image originalImage = img.decodeImage(File(imagePath).readAsBytesSync())!;
    final img.Image resizedImage = img.copyResize(originalImage, width: 800);
    final List<int> jpeg = img.encodeJpg(resizedImage, quality: 85);

    final File compressedImage = File(imagePath)..writeAsBytesSync(jpeg);
    return compressedImage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('プロフィール設定'),
        actions: [
          TextButton(
            onPressed: _updateUserData,
            child: Text('保存', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _changeHeaderImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    image: _headerImageFile != null
                        ? DecorationImage(image: FileImage(_headerImageFile!), fit: BoxFit.cover)
                        : (_headerImageUrl != null
                            ? DecorationImage(image: NetworkImage(_headerImageUrl!), fit: BoxFit.cover)
                            : null),
                    color: Colors.grey[300],
                  ),
                  child: Center(
                    child: Text('ヘッダー画像をタップして変更', style: TextStyle(color: Colors.black54)),
                  ),
                ),
              ),
              SizedBox(height: 16),
              GestureDetector(
                onTap: _changeProfileImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _profileImageFile != null
                      ? FileImage(_profileImageFile!)
                      : (_profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : AssetImage('assets/images/default.png') as ImageProvider),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _userIdController,
                decoration: InputDecoration(labelText: 'ユーザーID'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'ユーザーIDを入力してください';
                  }
                  final RegExp idRegExp = RegExp(r'^[a-zA-Z0-9]+$');
                  if (!idRegExp.hasMatch(value)) {
                    return 'ユーザーIDは半角英数字のみ使用できます';
                  }
                  return null;
                },
              ),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'ユーザー名'),
              ),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(labelText: '場所'),
              ),
              TextField(
                controller: _portfolioUrlController,
                decoration: InputDecoration(labelText: 'ポートフォリオURL'),
              ),
              TextField(
                controller: _bioController,
                decoration: InputDecoration(labelText: 'Bio'),
              ),
              SizedBox(height: 16),
              DropdownButton<String>(
                value: _selectedBadge,
                hint: Text('バッジを選択'),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedBadge = newValue;
                  });
                },
                items: badges.map<DropdownMenuItem<String>>((String badge) {
                  return DropdownMenuItem<String>(
                    value: badge,
                    child: Text(badge),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
