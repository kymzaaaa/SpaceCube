import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import '../pages/post_detail_page.dart';
import '../pages/profile_page.dart'; // ProfilePageをインポート
import 'like_button_widget.dart';

class PostTile extends StatefulWidget {
  final String uid;
  final String text;
  final String? imageUrl;
  final int likes;
  final Timestamp timestamp;
  final String postId;

  PostTile({
    required this.uid,
    required this.text,
    this.imageUrl,
    required this.likes,
    required this.timestamp,
    required this.postId,
  });

  @override
  _PostTileState createState() => _PostTileState();
}

class _PostTileState extends State<PostTile> {
  String? username;
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      if (userDoc.exists) {
        if (mounted) {
          setState(() {
            username = userDoc['username'];
            profileImageUrl = userDoc['profileImageUrl'];
          });
        }
      } else {
        if (mounted) {
          setState(() {
            username = 'Unknown';
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
      if (mounted) {
        setState(() {
          username = 'Error';
        });
      }
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri _url = Uri.parse(url);
    if (await canLaunchUrl(_url)) {
      await launchUrl(_url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final urlPattern = RegExp(r'(https?:\/\/[^\s]+)');
    final match = urlPattern.firstMatch(widget.text);
    String? url = match != null ? match.group(0) : null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailPage(
              uid: widget.uid,
              text: widget.text,
              imageUrl: widget.imageUrl,
              likes: widget.likes,
              timestamp: widget.timestamp,
              postId: widget.postId,
              username: username,
              profileImageUrl: profileImageUrl,
            ),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.all(3),
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      // プロフィールページへ移動
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfilePage(userId: widget.uid),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: profileImageUrl != null
                          ? NetworkImage(profileImageUrl!)
                          : AssetImage('assets/images/default.png') as ImageProvider,
                    ),
                  ),
                  SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      // プロフィールページへ移動
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfilePage(userId: widget.uid),
                        ),
                      );
                    },
                    child: username == null
                        ? CircularProgressIndicator()
                        : Text(username!, style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              SizedBox(height: 5),
              if (url != null)
                Text.rich(
                  TextSpan(
                    text: widget.text.substring(0, match!.start),
                    children: [
                      TextSpan(
                        text: url,
                        style: TextStyle(color: Colors.blue),
                        recognizer: TapGestureRecognizer()..onTap = () {
                          _launchURL(url);
                        },
                      ),
                      TextSpan(
                        text: widget.text.substring(match.end),
                      ),
                    ],
                  ),
                )
              else
                Text(widget.text),
              if (widget.imageUrl != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Image.network(widget.imageUrl!),
                ),
              if (url != null)
                GestureDetector(
                  onTap: () => _launchURL(url!),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: AnyLinkPreview(
                      displayDirection: UIDirection.uiDirectionHorizontal,
                      link: url,
                      errorBody: 'Could not fetch preview data',
                      errorTitle: 'Invalid URL',
                      showMultimedia: true,
                      bodyMaxLines: 5,
                      bodyTextOverflow: TextOverflow.ellipsis,
                      titleStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      bodyStyle: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  LikeButtonWidget(
                    key: UniqueKey(), // UniqueKeyを使用していいねボタンの状態を分離
                    postId: widget.postId,
                  ),
                  Text(
                    '${widget.timestamp.toDate()}',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
