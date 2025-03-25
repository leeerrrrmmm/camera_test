import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.camera, required this.cameras});
  final CameraDescription camera;
  final List<CameraDescription> cameras;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  VideoPlayerController? _videoController;
  bool isRecording = false;
  final ImagePicker _picker = ImagePicker();


  File? _currentImageFile;
  File? _galleryImageFile;
  File? _videoPath;

  Future<void> toggleCamera() async {
    if (widget.cameras.length < 2) return;

    if (isRecording) {
      await _controller.stopVideoRecording();

    }

    final lensDirection = _controller.description.lensDirection;
    final newCamera = widget.cameras.firstWhere(
          (camera) => camera.lensDirection != lensDirection,
      orElse: () => widget.cameras.first,
    );

    await _controller.dispose();

    _controller = CameraController(newCamera, ResolutionPreset.high);
    _initializeControllerFuture = _controller.initialize();

    setState(() {});
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _galleryImageFile = File(image.path);
        });
      } else {
        print("No image selected.");
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      setState(() {
        _currentImageFile = File(image.path);
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _toggleVideoButton() async {
    try {
      if (!isRecording) {
        await _initializeControllerFuture;
        await _controller.startVideoRecording();
        setState(() {
          isRecording = true;
        });
      } else {
        final videoFile = await _controller.stopVideoRecording();
        _videoPath = File(videoFile.path);

        _videoController = VideoPlayerController.file(_videoPath!)
          ..initialize().then((_) {
            setState(() {});
            _videoController!.play();
          });

        setState(() {
          isRecording = false;
        });
      }
    } catch (e) {
      print(e);
    }
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
    _videoController?.dispose();
    setState(() {
      _videoPath = null;
      _videoController = null;
    });
  }



  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
  }




  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Camera Task"), centerTitle: true),
      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller);
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),

          if (_currentImageFile != null)
            Stack(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: Image.file(File(_currentImageFile!.path), fit: BoxFit.cover),
                ),
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
          if( _videoPath == null && _videoController == null)
            if (_galleryImageFile != null)
              Stack(
                children: [
                  SizedBox(
                    width: MediaQuery
                        .of(context)
                        .size
                        .width,
                    height: MediaQuery
                        .of(context)
                        .size
                        .height,
                    child: Opacity(
                      opacity: 0.5,
                      child: Image.file(
                          File(_galleryImageFile!.path), fit: BoxFit.cover),
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

                  // VideoPlayer(_videoController!)),
          // Проигрыватель видео после завершения
          if (_videoPath != null)
            Stack(
              children: [
                Positioned.fill(
                  child: _videoController != null && _videoController!.value.isInitialized
                      ? Center(
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                        child: VideoPlayer(_videoController!),
                      ),
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

          //OTHER WIDGETS
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  // SWAP CAMERA
                  Row(
                    children: <Widget>[
                      GestureDetector(
                        onTap: () => toggleCamera(),
                        child: Icon(Icons.swipe_right_outlined,
                            color: Colors.white, size: 35),
                      ),
                      SizedBox(width: 10),
                      // MAKE PHOTO
                      GestureDetector(
                        onTap: _takePicture,
                        child: Icon(Icons.add_circle_outline_rounded,
                            color: Colors.white, size: 35),
                      ),
                    ],
                  ),
                  // PLAY/PAUSE VIDEO
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: GestureDetector(
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
                          child: isRecording
                              ? const Icon(Icons.stop, color: Colors.white)
                              : const Icon(Icons.videocam, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  // OPEN GALLERY
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