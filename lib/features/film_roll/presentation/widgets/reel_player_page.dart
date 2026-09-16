import 'dart:async';

import 'package:chaerok/shared/widgets/chaerok_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// 릴스(mp4) 전체화면 재생 페이지. 카드 인라인 재생 대신 탭 시 여기로
/// 진입한다(리스트 스크롤 중 여러 컨트롤러가 동시에 떠 있는 것을 피하기 위함).
class ReelPlayerPage extends StatefulWidget {
  const ReelPlayerPage({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  State<ReelPlayerPage> createState() => _ReelPlayerPageState();
}

class _ReelPlayerPageState extends State<ReelPlayerPage> {
  late final VideoPlayerController _controller;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    unawaited(_initializeAndPlay());
  }

  Future<void> _initializeAndPlay() async {
    await _controller.initialize();
    if (!mounted) return;
    setState(() => _isReady = true);
    await _controller.setLooping(true);
    await _controller.play();
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: _isReady
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : const ChaerokLoadingIndicator(color: Colors.white),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => unawaited(Navigator.of(context).maybePop()),
              ),
            ),
            if (_isReady)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: IconButton(
                    icon: Icon(
                      _controller.value.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                      color: Colors.white,
                      size: 48,
                    ),
                    onPressed: () {
                      setState(() {
                        unawaited(
                          _controller.value.isPlaying
                              ? _controller.pause()
                              : _controller.play(),
                        );
                      });
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
