import 'dart:io';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';

class VideoService {
  VideoPlayerController? _videoController;
  bool isRecording = false;
  File? _videoPath;

  VideoPlayerController? get videoController => _videoController;
  File? get videoPath => _videoPath;

  Future<void> toggleRecording(CameraController controller) async {
    try {
      if (!isRecording) {
        await controller.startVideoRecording();
        isRecording = true;
      } else {
        final videoFile = await controller.stopVideoRecording();
        _videoPath = File(videoFile.path);
        _videoController = VideoPlayerController.file(_videoPath!);
        await _videoController!.initialize();
        _videoController!.play();
        isRecording = false;
      }
    } catch (e) {
      print("Video recording error: $e");
    }
  }

  void dispose() {
    _videoController?.dispose();
    _videoController = null;
    _videoPath = null;
  }
}
