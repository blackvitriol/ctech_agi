import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VideoFullscreenPage extends StatelessWidget {
  final String title;
  final RTCVideoRenderer renderer;
  final bool isActive;

  const VideoFullscreenPage({
    super.key,
    required this.title,
    required this.renderer,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AspectRatio(
              aspectRatio: constraints.maxWidth / constraints.maxHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: isActive
                    ? RTCVideoView(
                        renderer,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                      )
                    : Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Text(
                            'No Video',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}
