import 'dart:io';
import 'package:camera/camera.dart';

class CameraService {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  CameraController? get controller => _controller;
  Future<void>? get initializeControllerFuture => _initializeControllerFuture;

  Future<void> initialize(CameraDescription camera) async {
    _controller = CameraController(camera, ResolutionPreset.high);
    _initializeControllerFuture = _controller?.initialize();
  }

  Future<File?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }
    final XFile image = await _controller!.takePicture();
    return File(image.path);
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }

  Future<void> toggleCamera(List<CameraDescription> cameras) async {
    if (cameras.length < 2 || _controller == null) return;


    final lensDirection = _controller!.description.lensDirection;
    final newCamera = cameras.firstWhere(
          (camera) => camera.lensDirection != lensDirection,
      orElse: () => cameras.first,
    );

    final currentRecording = _controller!.value.isRecordingVideo;
    if (currentRecording) {
      await _controller!.stopVideoRecording();
    }

    await _controller!.dispose();
    await initialize(newCamera);


    if (currentRecording) {
      await _controller!.startVideoRecording();
    }
  }
}