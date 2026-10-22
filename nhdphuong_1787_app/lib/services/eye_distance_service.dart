import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

typedef OnDistanceUpdate = void Function(double distanceCm, bool isTooClose);

class EyeDistanceService {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = -1;

  bool _isProcessing = false;
  bool _isDisposed = false;
  DateTime? _lastProcessedTime;
  bool _isCurrentlyTooClose = false;
  int _noFaceCounter = 0;

  OnDistanceUpdate? onDistanceUpdate;

  bool get isCameraReady => _cameraController != null && _cameraController!.value.isInitialized;
  CameraController? get cameraController => _cameraController;

  Future<bool> initialize({OnDistanceUpdate? onUpdate}) async {
    onDistanceUpdate = onUpdate;
    _isDisposed = false;

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        debugPrint('[EyeDistanceService] Không tìm thấy camera nào.');
        return false;
      }

      // Ưu tiên camera trước (Front camera) để nhìn mắt trẻ
      _cameraIndex = _cameras.indexWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
      );
      if (_cameraIndex == -1) {
        _cameraIndex = 0; // Fallback camera đầu tiên
      }

      final camera = _cameras[_cameraIndex];

      _cameraController = CameraController(
        camera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();

      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          enableLandmarks: true,
          enableClassification: false,
        ),
      );

      await _cameraController!.startImageStream(_processCameraFrame);
      debugPrint('[EyeDistanceService] Đã kích hoạt giám sát cự ly mắt bằng Camera AI!');
      return true;
    } catch (e) {
      debugPrint('[EyeDistanceService] Khởi tạo camera thất bại: $e');
      return false;
    }
  }

  void _processCameraFrame(CameraImage image) async {
    if (_isDisposed || _isProcessing) return;

    // Giới hạn tần suất xử lý: khoảng 300ms/khung hình để tiết kiệm pin và CPU
    final now = DateTime.now();
    if (_lastProcessedTime != null && now.difference(_lastProcessedTime!).inMilliseconds < 350) {
      return;
    }
    _lastProcessedTime = now;
    _isProcessing = true;

    try {
      final inputImage = _convertCameraImageToInputImage(image);
      if (inputImage == null || _faceDetector == null) {
        _isProcessing = false;
        return;
      }

      final List<Face> faces = await _faceDetector!.processImage(inputImage);
      if (faces.isNotEmpty) {
        _noFaceCounter = 0;
        final face = faces.first;
        final distanceCm = _estimateDistanceCm(face, image.width.toDouble(), image.height.toDouble());

        // Hysteresis thông minh:
        // - Đang an toàn -> Cần < 25cm để bật cảnh báo
        // - Đang cảnh báo -> Cần đưa ra xa >= 28cm để tự động tắt cảnh báo
        if (_isCurrentlyTooClose) {
          if (distanceCm >= 28.0) {
            _isCurrentlyTooClose = false;
          }
        } else {
          if (distanceCm < 25.0) {
            _isCurrentlyTooClose = true;
          }
        }

        debugPrint('[EyeDistanceService] Face detected! distanceCm: $distanceCm cm (isTooClose: $_isCurrentlyTooClose)');
        onDistanceUpdate?.call(distanceCm, _isCurrentlyTooClose);
      } else {
        // Nếu không còn khuôn mặt ở gần (bé buông máy hoặc đưa máy ra xa ngoài góc nhìn)
        _noFaceCounter++;
        if (_noFaceCounter >= 3) {
          if (_isCurrentlyTooClose) {
            _isCurrentlyTooClose = false;
            onDistanceUpdate?.call(35.0, false);
          }
        }
      }
    } catch (e) {
      // Bỏ qua lỗi khung hình đơn lẻ
    } finally {
      _isProcessing = false;
    }
  }

  /// Ước lượng khoảng cách từ mắt đến màn hình (cm)
  /// Sử dụng tỷ lệ khung bao khuôn mặt (bounding box) và khoảng cách giữa 2 mắt (Inter-pupillary distance)
  double _estimateDistanceCm(Face face, double frameWidth, double frameHeight) {
    double distanceCm = 35.0;

    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];

    final minDim = min(frameWidth, frameHeight);
    final effectiveMin = minDim > 0 ? minDim : 480.0;

    if (leftEye != null && rightEye != null) {
      // Tính khoảng cách pixel Euclid giữa 2 mắt
      final dx = (rightEye.position.x - leftEye.position.x).toDouble();
      final dy = (rightEye.position.y - leftEye.position.y).toDouble();
      final eyePixelDist = sqrt(dx * dx + dy * dy);

      // Tỷ lệ khoảng cách mắt trên kích thước khung hình
      final eyeRatio = eyePixelDist / effectiveMin;

      // Khoảng cách đồng tử bình thường ~6.3cm
      if (eyeRatio > 0.05) {
        final calculated = 5.2 / eyeRatio;
        distanceCm = calculated.clamp(10.0, 65.0);
      }
    } else {
      // Dựa vào tỷ lệ chiều rộng mặt trên khung hình (Face Bounding Box Ratio)
      final faceRatio = face.boundingBox.width / effectiveMin;
      if (faceRatio > 0.05) {
        final calculated = 11.5 / faceRatio;
        distanceCm = calculated.clamp(10.0, 65.0);
      }
    }

    return (distanceCm * 10).round() / 10.0;
  }

  InputImage? _convertCameraImageToInputImage(CameraImage image) {
    if (_cameraController == null) return null;

    final camera = _cameras[_cameraIndex];
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation = _orientations[_cameraController!.value.deviceOrientation];
      if (rotationCompensation == null) return null;

      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    rotation ??= InputImageRotation.rotation0deg;

    final format = Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  static const Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  void dispose() {
    _isDisposed = true;
    _cameraController?.stopImageStream().catchError((_) {});
    _cameraController?.dispose();
    _cameraController = null;
    _faceDetector?.close();
    _faceDetector = null;
  }
}
