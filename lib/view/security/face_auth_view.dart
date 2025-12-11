import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

class FaceAuthView extends StatefulWidget {
  final VoidCallback onSuccess;

  const FaceAuthView({super.key, required this.onSuccess});

  @override
  State<FaceAuthView> createState() => _FaceAuthViewState();
}

class _FaceAuthViewState extends State<FaceAuthView> {
  CameraController? _controller; // ✅ Nullable để tránh LateInitializationError
  
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.fast,
      minFaceSize: 0.15,
    ),
  );

  bool _isBusy = false;
  String _statusText = "Đang khởi tạo camera...";
  bool _isAuthenticated = false;
  DateTime _lastProcessTime = DateTime.fromMillisecondsSinceEpoch(0);
  final Duration _processInterval = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // 1. Yêu cầu quyền camera
      final status = await Permission.camera.request();
      if (status.isDenied) {
        _handleAuthFailed(message: "Không có quyền truy cập camera");
        return;
      }

      // 2. Lấy danh sách camera
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _handleAuthFailed(message: "Không có camera trên thiết bị");
        return;
      }

      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      // 3. Khởi tạo CameraController
      _controller = CameraController(
        frontCamera,
        ResolutionPreset.low, // ✅ LOW để tránh lag
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();
      if (!mounted) return;

      setState(() => _statusText = "Giữ yên khuôn mặt...");
      debugPrint("✅ Camera initialized successfully");

      // 4. Bắt đầu stream image
      _startFaceDetection();
    } catch (e) {
      debugPrint("❌ Lỗi init camera: $e");
      if (mounted) {
        _handleAuthFailed(message: "Lỗi camera: $e");
      }
    }
  }

  void _startFaceDetection() {
    if (_controller == null) return;

    debugPrint("📹 Starting face detection stream...");
    int frameCount = 0;

    _controller!.startImageStream((CameraImage image) async {
      frameCount++;
      if (frameCount % 10 == 0) {
        debugPrint("📸 Frame #$frameCount received");
      }

      if (_isBusy || _isAuthenticated) return;

      // Throttle: Giảm số lần xử lý
      if (DateTime.now().difference(_lastProcessTime) < _processInterval) {
        return;
      }

      _isBusy = true;
      _lastProcessTime = DateTime.now();

      try {
        final inputImage = _inputImageFromCameraImage(image);
        if (inputImage == null) {
          debugPrint("⚠️ InputImage is null, skipping frame");
          _isBusy = false;
          return;
        }

        debugPrint("✓ InputImage created: ${inputImage.metadata?.size}");

        // Xử lý nhận diện khuôn mặt
        final faces = await _faceDetector.processImage(inputImage);
        debugPrint("🔍 Detected: ${faces.length} faces");

        if (faces.isNotEmpty && mounted) {
          final face = faces.first;
          
          // Lấy xác suất mở mắt
          final leftProb = face.leftEyeOpenProbability ?? 1.0;
          final rightProb = face.rightEyeOpenProbability ?? 1.0;

          debugPrint("👁️ Mắt trái: $leftProb - Mắt phải: $rightProb");

          // Kiểm tra mở mắt (threshold: 0.1)
          if (leftProb > 0.1 && rightProb > 0.1) {
            debugPrint("✅ Xác thực thành công!");
            _isAuthenticated = true;
            await _stopCamera();
            if (mounted) widget.onSuccess();
          } else {
            if (mounted) {
              setState(() => _statusText = "Vui lòng mở mắt!");
            }
          }
        } else if (mounted) {
          setState(() => _statusText = "Đang tìm khuôn mặt...");
        }
      } catch (e) {
        debugPrint("❌ Lỗi xử lý: $e");
        // Bỏ qua lỗi frame
      } finally {
        _isBusy = false;
      }
    });
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    final camera = _controller!.description;
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;

      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (image.planes.isEmpty) return null;

    // ✅ Convert YUV_420_888 to NV21
    Uint8List bytes;
    if (format == InputImageFormat.yuv_420_888 && Platform.isAndroid) {
      bytes = _convertYUV420toNV21(image);
    } else {
      final WriteBuffer allBytes = WriteBuffer();
      for (final plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      bytes = allBytes.done().buffer.asUint8List();
    }

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  // ✅ Convert YUV420_888 to NV21 format
  Uint8List _convertYUV420toNV21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    final imageSize = width * height;
    final uvImageSize = imageSize ~/ 4;

    final nv21 = Uint8List(imageSize + uvImageSize * 2);

    // Y plane
    nv21.setAll(0, image.planes[0].bytes);

    // UV planes - interleave V and U
    final int uvWidth = width ~/ 2;
    final int uvHeight = height ~/ 2;
    final int uvSize = uvWidth * uvHeight;

    final List<int> uvPixels = <int>[];
    
    for (int i = 0; i < uvSize; i++) {
      uvPixels.add(image.planes[2].bytes[i]); // V
      uvPixels.add(image.planes[1].bytes[i]); // U
    }

    nv21.setAll(imageSize, Uint8List.fromList(uvPixels));
    return nv21;
  }

  Future<void> _stopCamera() async {
    try {
      if (_controller != null && _controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
    } catch (e) {
      debugPrint("⚠️ Lỗi stop stream: $e");
    }
  }

  void _handleAuthFailed({String message = "Xác thực thất bại"}) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LockedFaceView(message: message)),
    );
  }

  final Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void dispose() {
    _stopCamera();
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Camera Preview
            if (_controller != null && _controller!.value.isInitialized)
              Center(child: CameraPreview(_controller!)),

            // Overlay Shape (Khung oval)
            Positioned.fill(child: CustomPaint(painter: OverlayShapePainter())),

            // Status Text
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 50),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ===== OVERLAY SHAPE PAINTER =====
class OverlayShapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Vẽ nền tối
    final paint = Paint()..color = Colors.black.withOpacity(0.8);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final path = Path()
      ..addRect(rect)
      ..addOval(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: 300,
          height: 350,
        ),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Vẽ border oval
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: 300,
        height: 350,
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// ===== LOCKED FACE VIEW - XÁC THỰC THẤT BẠI =====
class LockedFaceView extends StatelessWidget {
  final String message;

  const LockedFaceView({
    super.key,
    this.message = "Không thể xác nhận danh tính",
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.no_photography_outlined,
                  size: 80,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Xác thực thất bại',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$message.\nVui lòng đăng nhập lại.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    // Đăng xuất và quay về login
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  },
                  child: const Text(
                    'Đăng xuất',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}