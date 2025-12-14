import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class VisualSearchView extends StatefulWidget {
  const VisualSearchView({super.key});

  @override
  State<VisualSearchView> createState() => _VisualSearchViewState();
}

class _VisualSearchViewState extends State<VisualSearchView> with WidgetsBindingObserver {
  CameraController? _controller;
  late ImageLabeler _imageLabeler;
  bool _isProcessing = false;
  String _detectedLabel = "Nhấn để quét";
  List<CameraDescription> _cameras = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _initializeDetector();
  }

  Future<void> _initializeDetector() async {
    final options = ImageLabelerOptions(confidenceThreshold: 0.4);
    _imageLabeler = ImageLabeler(options: options);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
    _imageLabeler.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    final camera = _cameras.first;

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      print("Camera initialization error: $e");
    }
  }

  Future<void> _stopCamera() async {
    final CameraController? cameraController = _controller;
    
    if (cameraController != null) {
      _controller = null;

      try {
        if (cameraController.value.isStreamingImages) {
          await cameraController.stopImageStream();
        }
      } catch (e) {
        print("Error stopping image stream: $e");
      }
      
      try {
        await cameraController.dispose();
      } catch (e) {
        print("Error disposing camera: $e");
      }
    }
  }

  // ✅ Hàm chính: Capture ảnh và xử lý khi user tap
  Future<void> _captureAndDetect() async {
    print("🎯 START: _captureAndDetect() called!");
    
    if (_isProcessing) {
      print("⚠️ Already processing");
      return;
    }
    if (_controller == null || !_controller!.value.isInitialized) {
      print("❌ Camera not ready: controller=$_controller, initialized=${_controller?.value.isInitialized}");
      return;
    }

    _isProcessing = true;
    setState(() => _detectedLabel = "Đang xử lý...");

    try {
      print("📸 Step 1: Capturing image...");
      final image = await _controller!.takePicture();
      print("✓ Step 2: Image captured at ${image.path}");
      
      final file = File(image.path);
      print("✓ Step 3: File size = ${file.lengthSync()} bytes");

      final inputImage = InputImage.fromFile(file);
      print("✓ Step 4: InputImage created");

      final labels = await _imageLabeler.processImage(inputImage);
      print("✓ Step 5: Labels processed, count=${labels.length}");

      if (mounted) {
        if (labels.isNotEmpty) {
          // ✅ Lọc labels: loại bỏ những từ generic như "metal", "tool"
          final filteredLabels = labels.where((label) {
            final lower = label.label.toLowerCase();
            // Bỏ những từ quá chung chung
            final generic = ['metal', 'steel', 'object', 'thing', 'item', 'product'];
            return !generic.any((g) => lower.contains(g));
          }).toList();

          // Nếu sau khi lọc còn labels, lấy cái confidence cao nhất
          final resultLabel = filteredLabels.isNotEmpty
              ? filteredLabels.reduce((a, b) => a.confidence > b.confidence ? a : b)
              : labels.first; // Fallback: lấy cao nhất trong tất cả
          
          setState(() {
            _detectedLabel = resultLabel.label; // ✅ Giữ nguyên tiếng Anh
          });

          print("✓ FINAL: Detected = $_detectedLabel (${(resultLabel.confidence * 100).toStringAsFixed(1)}%)");

          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.pop(context, _detectedLabel);
          }
        } else {
          setState(() => _detectedLabel = "Không phát hiện được");
          print("⚠️ No labels detected");
        }
      }

      await file.delete().catchError((_) {});
    } catch (e) {
      print("❌ ERROR: $e");
      print("❌ StackTrace: ${StackTrace.current}");
      if (mounted) {
        setState(() => _detectedLabel = "Lỗi: $e");
      }
    } finally {
      if (mounted) _isProcessing = false;
      print("🏁 END: _captureAndDetect()");
    }
  }

  String _translateLabel(String label) {
    final lowerLabel = label.toLowerCase();
    
    final translations = {
      'person': 'Người',
      'shirt': 'Áo',
      'top': 'Áo',
      'jeans': 'Quần Jeans',
      'pants': 'Quần',
      'shoe': 'Giày',
      'shoes': 'Giày',
      'computer': 'Máy tính',
      'laptop': 'Laptop',
      'phone': 'Điện thoại',
      'mobile phone': 'Điện thoại',
      'bag': 'Túi xách',
      'handbag': 'Túi xách',
      'watch': 'Đồng hồ',
      'glasses': 'Mắt kính',
      'eyeglasses': 'Mắt kính',
      'hat': 'Mũ',
      'cap': 'Nón',
      'book': 'Sách',
      'cup': 'Cốc',
      'bottle': 'Chai',
      // ✅ Thêm bộ dao, nĩa, muỗng
      'spoon': 'Muỗng',
      'fork': 'Nĩa',
      'knife': 'Dao',
      'cutlery': 'Bộ dao nĩa',
      'tableware': 'Bộ đồ ăn',
      'utensil': 'Dụng cụ nhà bếp',
      'scissors': 'Kéo',
      'tool': 'Dụng cụ',
    };
    
    return translations[lowerLabel] ?? label;
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false, // ✅ Ẩn bàn phím không resize UI
        body: GestureDetector(
          onTap: () {
            // ✅ Ẩn bàn phím khi tap camera
            SystemChannels.textInput.invokeMethod('TextInput.hide');
          },
          child: Stack(
            children: [
              Center(child: CameraPreview(_controller!)),
              
              // Focus frame
              Center(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              // Bottom controls
              Positioned(
                bottom: 50,
                left: 20,
                right: 20,
                child: Column(
                  children: [
                    // Result button
                    ElevatedButton(
                      onPressed: _isProcessing ? null : _captureAndDetect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        elevation: 5,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isProcessing)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                            )
                          else
                            const Icon(Icons.search, color: Colors.blue),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              _detectedLabel,
                              style: const TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 5),
                          if (!_isProcessing)
                            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Close button
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}