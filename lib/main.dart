import 'package:camera/camera.dart';
import 'package:camera_test/screen/main_screen.dart';
import 'package:flutter/material.dart';

Future <void> main() async  {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras =  await availableCameras();

  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      home: MainScreen(camera: firstCamera, cameras: cameras)
    )
  );
}
