import 'dart:io'; // สำหรับ File
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart'; // ใช้ tflite_flutter

List<CameraDescription>? cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras(); // โหลดรายการกล้องทั้งหมด
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
  String _imagePath = ''; // ใช้สำหรับเก็บที่อยู่ของภาพที่ถ่ายหรือเลือก
  late Interpreter _interpreter; // ใช้ Interpreter จาก tflite_flutter

  @override
  void initState() {
    super.initState();
    _initializeCamera(); // เรียกใช้งานฟังก์ชัน _initializeCamera() เมื่อเริ่มต้น
    _loadModel(); // โหลดโมเดลเมื่อเริ่มต้น
  }

  // ฟังก์ชัน _initializeCamera() สำหรับการเริ่มต้นกล้อง
  Future<void> _initializeCamera() async {
    _controller = CameraController(
      cameras![0], // เลือกกล้องตัวแรก
      ResolutionPreset.high, // ความละเอียดของกล้อง
    );

    await _controller.initialize(); // เริ่มต้นกล้อง
    if (!mounted) return;

    setState(() {
      _isCameraInitialized = true;
    });
  }

  // โหลดโมเดล TFLite ด้วย tflite_flutter
  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
          'assets/model.tflite'); // โหลดโมเดลจาก assets
      print("Model loaded successfully!");
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  // ฟังก์ชันถ่ายภาพจากกล้อง
  Future<void> _takePicture() async {
    final XFile file = await _controller.takePicture();
    setState(() {
      _imagePath = file.path; // บันทึกที่อยู่ของภาพที่ถ่าย
    });
    _classifyImage(_imagePath); // เรียกใช้การทำนายภาพ
  }

  // ฟังก์ชันเลือกภาพจากแกลเลอรี่
  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path; // บันทึกที่อยู่ของภาพที่เลือก
      });
      _classifyImage(_imagePath); // เรียกใช้การทำนายภาพ
    }
  }

  // ฟังก์ชันทำนายภาพด้วย tflite_flutter
  Future<void> _classifyImage(String imagePath) async {
    // เตรียมการแปลงรูปภาพไปเป็นอินพุตสำหรับโมเดล
    var image = await loadImage(imagePath);

    // ใช้ Interpreter สำหรับการทำนาย
    var output = List.filled(1 * 1001, 0); // ปรับขนาดของเอาต์พุตตามจำนวนคลาส
    _interpreter.run(image, output);

    // แสดงผลลัพธ์การทำนาย
    print("Prediction: $output");
  }

  // ฟังก์ชันโหลดและแปลงรูปภาพเป็นอินพุตสำหรับโมเดล
  Future<List<double>> loadImage(String path) async {
    // คุณสามารถใช้ไลบรารี image หรือแปลงเป็นเทนเซอร์เอง
    // ตัวอย่างนี้จะต้องปรับใช้วิธีที่เหมาะสมกับโมเดลของคุณ

    return List.generate(
        224 * 224 * 3,
        (index) =>
            0.0); // ตัวอย่าง: แปลงเป็นรายการของพิกเซล (ต้องปรับให้เหมาะสมกับโมเดล)
  }

  @override
  void dispose() {
    _controller.dispose(); // ปิดกล้องเมื่อไม่ใช้งาน
    _interpreter.close(); // ปิดโมเดลเมื่อเลิกใช้งาน
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Camera & TFLite App")),
      body: Column(
        children: [
          // แสดงภาพที่ถ่ายหรือเลือก
          _imagePath.isNotEmpty
              ? Image.file(File(_imagePath)) // แสดงภาพที่ถ่ายหรือเลือก
              : _isCameraInitialized
                  ? CameraPreview(_controller) // แสดงการถ่ายภาพจากกล้อง
                  : const Center(child: CircularProgressIndicator()),

          // ปุ่มให้เลือกหรือเปิดกล้อง
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
