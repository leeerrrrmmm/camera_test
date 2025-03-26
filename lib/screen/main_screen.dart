import 'dart:io';
import 'package:camera/camera.dart';
import 'package:camera_test/screen/services/camera_service.dart';
import 'package:camera_test/screen/services/galery_service.dart';
import 'package:camera_test/screen/services/video_service.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.camera, required this.cameras});
  final CameraDescription camera;
  final List<CameraDescription> cameras;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver{
  late CameraService _cameraService;
  late VideoService _videoService;
  late GalleryService _galleryService;

  File? _currentImageFile;
  File? _galleryImageFile;

  @override
  void initState() {
    super.initState();
    _cameraService = CameraService();
    _videoService = VideoService();
    _galleryService = GalleryService();

    _cameraService.initialize(widget.camera);
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _videoService.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    final imageFile = await _cameraService.takePicture();
    if (imageFile != null) {
      setState(() {
        _currentImageFile = imageFile;
      });
    }
  }

  Future<void> _toggleVideoButton() async {
    await _videoService.toggleRecording(_cameraService.controller!);
    setState(() {});
  }

  Future<void> _pickImageFromGallery() async {
    final imageFile = await _galleryService.pickImageFromGallery();
    if (imageFile != null) {
      setState(() {
        _galleryImageFile = imageFile;
      });
    }
  }

  Future<void> _toggleCamera() async {
    await _cameraService.toggleCamera(widget.cameras);
    setState(() {});
  }

  void _clearCurrentImage() {
    setState(() {
      _currentImageFile = null;
    });
  }

  void _clearGalleryImage() {
    setState(() {
      _galleryImageFile = null;
    });
  }

  void _clearVideo() {
    _videoService.dispose();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Camera Task"), centerTitle: true),
      body: Stack(
        children: [
          // Our camera
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: FutureBuilder<void>(
              future: _cameraService.initializeControllerFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.done) {
                  return CameraPreview(_cameraService.controller!);
                } else if (snap.hasError) {
                  return Center(child: Text('Camera initialization error: ${snap.error}'));
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),

          // Photo if it is made
          if (_currentImageFile != null)
            Stack(
              children: [
                SizedBox(width: double.infinity,height: double.infinity,child: Image.file(_currentImageFile!, fit: BoxFit.cover)),
                Positioned(
                  top: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: _clearCurrentImage,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.red,
                      child: Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

          //  Images from the gallery, if we select them
          if (_galleryImageFile != null && _videoService.videoPath == null && _videoService.videoController == null)
            Stack(
              children: [
                SizedBox(
                  height: double.infinity,
                  width: double.infinity,
                  child: Opacity(
                    opacity: 0.5,
                    child: Image.file(_galleryImageFile!, fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: _clearGalleryImage,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.red,
                      child: Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

          // Watch the video if it is recorded
          if (_videoService.videoPath != null)
            Stack(
              children: [
                Positioned.fill(
                  child: _videoService.videoController != null &&
                      _videoService.videoController!.value.isInitialized
                      ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoService.videoController!.value.size.width,
                      height: _videoService.videoController!.value.size.height,
                      child: VideoPlayer(_videoService.videoController!),
                    ),
                  )
                      : const SizedBox(),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: _clearVideo,
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.red,
                      child: Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

          // Management
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  // Camera shift button
                  GestureDetector(
                    onTap:_toggleCamera,
                    child: Icon(Icons.swipe_right_outlined, color: Colors.white, size: 35),
                  ),
                  //Button to take a photo
                  GestureDetector(
                    onTap: _takePicture,
                    child: Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 35),
                  ),
                  // Video recording button
                  GestureDetector(
                    onTap: _toggleVideoButton,
                    child: Container(
                      margin: const EdgeInsets.only(right: 30),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Center(
                        child: _videoService.isRecording
                            ? const Icon(Icons.stop, color: Colors.white)
                            : const Icon(Icons.videocam, color: Colors.white),
                      ),
                    ),
                  ),
                  // Button to open the gallery
                  GestureDetector(
                    onTap: _pickImageFromGallery,
                    child: Icon(Icons.photo, color: Colors.white, size: 35),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
