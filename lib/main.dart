import 'dart:io'; // Import the dart:io package
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

List<CameraDescription>? cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const CameraApp());
}

class CameraApp extends StatelessWidget {
  const CameraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  bool _isCameraInitialized = false;
  String _imagePath =
      ''; // Initialize with an empty string to avoid LateInitializationError

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(
      cameras![0], // กล้องตัวแรก (กล้องหลัง)
      ResolutionPreset.high, // ความละเอียดสูง
    );

    await _controller.initialize();
    if (!mounted) return;

    setState(() {
      _isCameraInitialized = true;
    });
  }

  Future<void> _takePicture() async {
    final XFile file = await _controller.takePicture();
    setState(() {
      _imagePath = file.path; // Save the image path
    });
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path; // Save the image path
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Camera & Gallery App")),
      body: Column(
        children: [
          // Display either the camera preview or the selected image
          _imagePath.isNotEmpty
              ? Image.file(File(_imagePath)) // Correct usage of File
              : _isCameraInitialized
                  ? CameraPreview(_controller)
                  : const Center(child: CircularProgressIndicator()),

          // Row of buttons to select image or open camera
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _pickImageFromGallery,
                child: const Text("Pick Image from Gallery"),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: _takePicture,
                child: const Text("Open Camera"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
