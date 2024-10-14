import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/post_tile.dart';
import 'edit_profile_page.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  final String? userId;

  ProfilePage({this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  DocumentSnapshot<Map<String, dynamic>>? userData;
  bool isSelf = false;
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    String userId = widget.userId ?? currentUser!.uid;
    isSelf = (userId == currentUser!.uid);

    DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      if (mounted) {
        setState(() {
          userData = userDoc;
        });

        if (!isSelf) {
          _checkIfFollowing();
        }
      }
    }
  }

  Future<void> _checkIfFollowing() async {
    final followersRef = FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('followers');
    final doc = await followersRef.doc(currentUser!.uid).get();
    setState(() {
      isFollowing = doc.exists;
    });
  }

  Future<void> _ensureDocumentExists(DocumentReference ref) async {
    final docSnapshot = await ref.get();
    if (!docSnapshot.exists) {
      await ref.set({});
    }
  }

  Future<void> _toggleFollow() async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);
    final followersRef = userRef.collection('followers').doc(currentUser!.uid);
    final followingRef = FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).collection('following').doc(widget.userId);

    try {
      if (isFollowing) {
        await followersRef.delete();
        await followingRef.delete();

        await userRef.update({
          'followersCount': FieldValue.increment(-1),
        });
        await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
          'followingCount': FieldValue.increment(-1),
        });
      } else {
        await _ensureDocumentExists(userRef);
        await followersRef.set({});
        await followingRef.set({});

        await userRef.update({
          'followersCount': FieldValue.increment(1),
        });
        await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
          'followingCount': FieldValue.increment(1),
        });
      }

      setState(() {
        isFollowing = !isFollowing;
      });
    } catch (e) {
      print('Error updating follow status: $e');
    }
  }

  Future<void> _updateProfileAfterEdit() async {
    await _fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return Scaffold(
        appBar: AppBar(title: Text('プロフィール')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    Map<String, dynamic>? data = userData!.data();
    String? headerImage = data?['headerImage'];
    String? profileImage = data?['profileImageUrl'];
    String? username = data?['username'];
    String? userId = data?['userId'];
    int? followersCount = data?['followersCount'] ?? 0;
    int? followingCount = data?['followingCount'] ?? 0;
    String? location = data?['location'];
    String? portfolioUrl = data?['portfolioUrl'];
    String? bio = data?['Bio'];  // 変更部分: Bio を取得
    List<String>? badges = List<String>.from(data?['badges'] ?? []);
    Timestamp? createdAt = data?['createdAt'];

    return Scaffold(
      appBar: AppBar(
        title: Text('SpaceCube'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            headerImage != null
                ? Image.network(headerImage, height: 150, width: double.infinity, fit: BoxFit.cover)
                : Container(height: 120, color: Colors.grey),

            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: profileImage != null
                        ? NetworkImage(profileImage)
                        : AssetImage('assets/images/default.png') as ImageProvider,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                username ?? 'ユーザー名が設定されていません',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isSelf)
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditProfilePage(userId: currentUser!.uid),
                                    ),
                                  ).then((_) => _updateProfileAfterEdit());
                                },
                              ),
                          ],
                        ),
                        Text('@${userId ?? 'ID未設定'}', style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 5),
                        Text('follow: $followingCount follower: $followersCount'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (!isSelf)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton(
                  onPressed: _toggleFollow,
                  child: Text(isFollowing ? 'フォローを解除' : 'フォローする'),
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (bio != null) Text('Bio: $bio', style: TextStyle(fontSize: 16)),  // Bioに変更
                  if (location != null) Text('Location: $location', style: TextStyle(fontSize: 16)),
                  if (portfolioUrl != null) Text('URL: $portfolioUrl', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),

            SizedBox(height: 5),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Badges:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  badges.isNotEmpty
                      ? Wrap(
                          spacing: 10.0,
                          runSpacing: 10.0,
                          children: badges.map((badge) => Chip(label: Text(badge))).toList(),
                        )
                      : Text('バッジがありません'),
                ],
              ),
            ),

            SizedBox(height: 6),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your post:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .where('uid', isEqualTo: widget.userId ?? currentUser!.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Text('エラーが発生しました: ${snapshot.error}');
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Text('過去の投稿がありません');
                      }

                      final posts = snapshot.data!.docs;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          var post = posts[index].data() as Map<String, dynamic>;

                          return PostTile(
                            uid: post['uid'],
                            text: post['text'] ?? '',
                            imageUrl: post['imageUrl'],
                            likes: post['likes'] ?? 0,
                            timestamp: post['timestamp'] ?? Timestamp.now(),
                            postId: posts[index].id,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
