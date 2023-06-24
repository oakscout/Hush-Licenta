import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:untitled/utils.dart';

class AnimationPage extends StatefulWidget {
  final String animationType;

  AnimationPage({required this.animationType});

  @override
  _AnimationPageState createState() => _AnimationPageState();
}


class _AnimationPageState extends State<AnimationPage> {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;

  void initializeVideoPlayer(String videoPath) {
    _controller = VideoPlayerController.asset(videoPath)
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
          _controller.play();
        });
      });
  }

  @override
  void initState() {
    super.initState();
    String animationType = widget.animationType;

    String videoPath;
    if (animationType == 'animation1') {
      videoPath = 'assets/videos/muschi.mp4';
    } else if (animationType == 'animation2') {
      videoPath = 'assets/videos/nor.mp4';
    } else {
      videoPath = 'assets/videos/balon.mp4';
    }

    initializeVideoPlayer(videoPath);
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String? savedText = Provider.of<TextProvider>(context).savedText;

    return Scaffold(
      backgroundColor: Color(0xFF8EA4CD),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: EdgeInsets.only(top: 0.0),
            child: Expanded(
              flex: 1,
              child: Container(
                padding: EdgeInsets.only(top: 80.0),
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 80.0,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: EdgeInsets.only(bottom: 80.0),
              alignment: Alignment.center,
              child: _isVideoInitialized
                  ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
                  : Container(),
            ),
          ),
        ],
      ),
    );
  }
}
