import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alert_log.dart';
import '../models/app_rule.dart';
import '../models/screen_time_schedule.dart';
import '../services/child_service.dart';
import '../services/eye_distance_service.dart';
import '../services/app_blocker_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/eye_care_overlay.dart';
import 'login_screen.dart';

/// Màn hình Giao Diện Máy Trẻ Em (Child Guard Screen)
/// Theo đúng yêu cầu nghiệp vụ:
/// 1. Trẻ em KHÔNG CÓ QUYỀN GÌ HẾT ngoài việc cung cấp mã OTP & QR kết nối.
/// 2. Chỉ hiển thị: Mốc thời gian được sử dụng, Các ứng dụng được phép dùng, và Mã QR/OTP kết nối.
/// 3. Cảnh báo cự ly mắt (<25cm) tự động kích hoạt và TỰ ĐỘNG TẮT ĐI khi đủ khoảng cách an toàn (>=30cm).
/// 4. Các cảm biến (khoảng cách mắt, độ ồn micro dB, định vị GPS) chạy ngầm 24/24 gửi realtime về máy PH và Admin.
/// 5. Trẻ em KHÔNG được tự ý đăng xuất, muốn đăng xuất bắt buộc phải xác thực Mật khẩu Phụ huynh.
class KidModeSimulatorScreen extends StatefulWidget {
  final int childId;
  final String childName;

  const KidModeSimulatorScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<KidModeSimulatorScreen> createState() => _KidModeSimulatorScreenState();
}

class _KidModeSimulatorScreenState extends State<KidModeSimulatorScreen> {
  // Cự ly mắt thời gian thực (được đo liên tục bởi EyeDistanceService từ Camera trước)
  double _distanceCm = 35.0;
  String _currentDistance = '35 cm';
  bool _isEyeWarningVisible = false;
  EyeDistanceService? _eyeDistanceService;

  // Cảm biến âm thanh thời gian thực (được đo liên tục bởi NoiseMeter từ Micro thật)
  double _currentNoiseDb = 45.0;
  NoiseMeter? _noiseMeter;
  StreamSubscription<NoiseReading>? _noiseSub;
  StreamSubscription<Position>? _positionSub;
  DateTime? _lastNoiseAlertSent;

  // Trạng thái pin, định vị GPS thật từ thiết bị
  int _battery = 85;
  double _lat = 0.0;
  double _lng = 0.0;
  bool _isLockedByParent = false;

  // Mã ghép nối của máy con xuất trình cho phụ huynh
  String _pairingCode = '178701';

  Timer? _syncTimer;
  Timer? _sensorPollTimer;
  Timer? _appMonitorTimer;
  DateTime? _lastBlockAlertSent;
  bool _isShowingBlockOverlay = false;
  bool _isSyncing = false;
  List<AppRule> _appRules = [];
  List<ScreenTimeSchedule> _schedules = [];
  final bool _simulateCurfewActive = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _startRealSensors();
    // Đồng bộ trạng thái khóa máy và đẩy telemetry ngầm lên Server mỗi 2.5 giây
    _syncTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) => _syncDeviceStatus());
  }

  Future<void> _startRealSensors() async {
    // 1. Yêu cầu cấp quyền Micro, Camera và Định vị
    try {
      await [
        Permission.microphone,
        Permission.camera,
        Permission.location,
      ].request();
    } catch (_) {}

    // 2. Kích hoạt Cảm biến Âm thanh thật (Microphone qua NoiseMeter)
    try {
      _noiseMeter = NoiseMeter();
      _noiseSub = _noiseMeter?.noise.listen(
        (NoiseReading reading) {
          if (!mounted) return;
          final db = reading.meanDecibel;
          if (db.isFinite && !db.isNaN && db > 0) {
            final clamped = db.clamp(25.0, 115.0);
            setState(() {
              _currentNoiseDb = (clamped * 10).round() / 10.0;
            });
            // Nếu âm thanh quá ồn (> 80 dB), tự động gửi cảnh báo nguy hiểm lên server cho PH & Admin
            if (clamped > 80.0) {
              _sendNoiseDangerAlert(clamped);
            }
          }
        },
        onError: (err) {
          debugPrint('[KidMode] NoiseMeter error: $err');
        },
      );
    } catch (e) {
      debugPrint('[KidMode] Khởi động Micro thất bại: $e');
    }

    // 3. Kích hoạt Cảm biến Đo khoảng cách mắt thật (Camera AI qua EyeDistanceService)
    try {
      _eyeDistanceService = EyeDistanceService();
      await _eyeDistanceService?.initialize(
        onUpdate: (distanceCm, isTooClose) {
          if (!mounted) return;
          _updateDistance(distanceCm);
        },
      );
    } catch (e) {
      debugPrint('[KidMode] Khởi động EyeDistanceService thất bại: $e');
    }

    // 4. Kích hoạt Cảm biến Định vị GPS thật (Real-time GPS Stream & Fused Location)
    _startRealLocationTracking();

    // 5. Đọc dung lượng Pin thật định kỳ
    _updateRealBattery();
    _sensorPollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _updateRealBattery());

    // 6. Kích hoạt Dịch vụ Chặn ứng dụng phần cứng thật (UsageStatsManager & App Blocker)
    _startRealAppBlockingService();
  }

  Future<void> _startRealAppBlockingService() async {
    try {
      final hasUsage = await AppBlockerService.checkUsagePermission();
      if (!hasUsage && mounted) {
        await AppBlockerService.requestUsagePermission();
      }
    } catch (_) {}

    _appMonitorTimer?.cancel();
    _appMonitorTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) => _checkForegroundAndBlock());
  }

  Future<void> _checkForegroundAndBlock() async {
    if (!mounted) return;
    try {
      final currentPkg = await AppBlockerService.getForegroundPackage();
      if (currentPkg == null || currentPkg.isEmpty) return;

      // Đang ở trong chính ứng dụng ChildGuard
      if (currentPkg == 'com.nhdphuong1787.nhdphuong_1787_app') return;

      // 1. Phụ huynh bật Khóa Toàn Bộ Máy từ xa
      if (_isLockedByParent) {
        debugPrint('[AppBlocker] Thiết bị đang bị khóa từ xa! Kéo về ChildGuard.');
        await AppBlockerService.bringAppToFront();
        return;
      }

      // 2. Kiểm tra xem app bé mở có nằm trong danh sách Bị Khóa hay không
      final allRules = _getEffectiveRules();
      for (final rule in allRules) {
        if (!rule.isActive) continue;
        if (rule.status == 'Blocked') {
          final pkgs = AppBlockerService.getMatchingPackages(rule.appName, rule.packageNameOrDomain);
          if (pkgs.map((p) => p.toLowerCase()).contains(currentPkg.toLowerCase())) {
            debugPrint('[AppBlocker] Phát hiện mở app bị cấm: ${rule.appName} ($currentPkg). Đang can thiệp chặn!');
            // Kéo ngay ChildGuard về đè lên ứng dụng bị chặn
            await AppBlockerService.bringAppToFront();

            final now = DateTime.now();
            if (_lastBlockAlertSent == null || now.difference(_lastBlockAlertSent!).inSeconds >= 10) {
              _lastBlockAlertSent = now;
              ChildService.sendAlert(AlertLog(
                id: 0,
                childProfileId: widget.childId,
                alertType: 'APP_BLOCKED',
                severity: 'Danger',
                value: rule.appName,
                message: 'Bé ${widget.childName} vừa cố tình mở ứng dụng bị cấm: ${rule.appName} trên máy và đã bị hệ thống chặn lại!',
                createdAt: now,
              ));
            }

            if (!_isShowingBlockOverlay && mounted) {
              _showEnforcedBlockDialog(rule.appName);
            }
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('[AppBlocker] Lỗi kiểm tra foreground: $e');
    }
  }

  void _showEnforcedBlockDialog(String appName) {
    if (_isShowingBlockOverlay) return;
    _isShowingBlockOverlay = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.block_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text('ỨNG DỤNG BỊ CHẶN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16)),
            ),
          ],
        ),
        content: Text(
          'Ứng dụng "$appName" đã bị Phụ huynh khóa hoàn toàn trên thiết bị này.\n\nHệ thống ChildGuard đã tự động can thiệp và ngăn chặn. Con hãy tập trung học bài hoặc xin phép Ba Mẹ nhé!',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF3730A3)),
            onPressed: () {
              _isShowingBlockOverlay = false;
              Navigator.pop(ctx);
            },
            child: const Text('Đã Hiểu, Quay Lại'),
          ),
        ],
      ),
    ).then((_) => _isShowingBlockOverlay = false);
  }

  Future<void> _startRealLocationTracking() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        debugPrint('[KidMode] Quyền GPS bị từ chối: $perm');
        return;
      }

      // 1. Lấy ngay lập tức tọa độ GPS trong Fused Location Provider cache
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null && mounted) {
        setState(() {
          _lat = lastPos.latitude;
          _lng = lastPos.longitude;
        });
        debugPrint('[KidMode] Real GPS from LastKnownPosition: $_lat, $_lng');
      }

      // 2. Lắng nghe luồng di chuyển GPS thật liên tục
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2, // Cập nhật khi di chuyển tối thiểu 2m
      );
      _positionSub = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (Position pos) {
          if (!mounted) return;
          setState(() {
            _lat = pos.latitude;
            _lng = pos.longitude;
          });
          debugPrint('[KidMode] Real GPS Stream update: $_lat, $_lng');
        },
        onError: (err) {
          debugPrint('[KidMode] GPS Stream error: $err');
        },
      );

      // 3. Quét vệ tinh GPS trực tiếp nếu chưa có
      final currentPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      if (mounted) {
        setState(() {
          _lat = currentPos.latitude;
          _lng = currentPos.longitude;
        });
        debugPrint('[KidMode] Real GPS from CurrentPosition: $_lat, $_lng');
      }
    } catch (e) {
      debugPrint('[KidMode] Lỗi khởi động GPS thật: $e');
    }
  }

  Future<void> _updateRealBattery() async {
    try {
      final battery = Battery();
      final level = await battery.batteryLevel;
      if (mounted && level > 0) {
        setState(() => _battery = level);
      }
    } catch (_) {}
  }

  void _sendNoiseDangerAlert(double db) {
    final now = DateTime.now();
    if (_lastNoiseAlertSent == null || now.difference(_lastNoiseAlertSent!).inSeconds >= 10) {
      _lastNoiseAlertSent = now;
      final alert = AlertLog(
        id: 0,
        childProfileId: widget.childId,
        alertType: 'NOISE_DANGER',
        value: '${db.round()} dB',
        severity: 'Danger',
        message: 'Phát hiện tiếng ồn / la hét bất thường (${db.round()} dB) tại phòng bé ${widget.childName}',
        createdAt: now,
      );
      ChildService.sendAlert(alert);
    }
  }

  Future<void> _loadInitialData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString('paired_code');
      if (savedCode != null && savedCode.isNotEmpty) {
        if (mounted) setState(() => _pairingCode = savedCode);
      }

      final rules = await ChildService.getRules(widget.childId);
      final schedules = await ChildService.getChildSchedules(widget.childId);
      if (mounted) {
        setState(() {
          if (rules.isNotEmpty) _appRules = rules;
          if (schedules.isNotEmpty) _schedules = schedules;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _sensorPollTimer?.cancel();
    _appMonitorTimer?.cancel();
    _noiseSub?.cancel();
    _positionSub?.cancel();
    _eyeDistanceService?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Cập nhật cự ly mắt & cơ chế TỰ ĐỘNG BẬT CẢNH BÁO và TỰ ĐỘNG TẮT KHI AN TOÀN
  void _updateDistance(double cm) {
    if (!mounted) return;
    debugPrint('[KidMode] Cự ly mắt cập nhật: ${cm.toInt()}cm, Tiếng ồn: $_currentNoiseDb dB, Pin: $_battery%');
    setState(() {
      _distanceCm = cm;
      _currentDistance = '${cm.toInt()} cm';

      if (cm < 25.0) {
        // Mắt quá gần -> TỰ ĐỘNG BẬT CẢNH BÁO TOÀN MÀN HÌNH
        if (!_isEyeWarningVisible) {
          _isEyeWarningVisible = true;
          // Gửi cảnh báo lên Web API để máy Phụ huynh & Admin nhận thông báo realtime
          final alert = AlertLog(
            id: 0,
            childProfileId: widget.childId,
            alertType: 'EYE_DISTANCE',
            value: '${cm.toInt()} cm',
            severity: 'Warning',
            message: 'Bé ${widget.childName} đang để điện thoại quá gần mắt (${cm.toInt()}cm)',
            createdAt: DateTime.now(),
          );
          ChildService.sendAlert(alert);
        }
      } else if (cm >= 28.0) {
        // Đã đưa máy ra xa an toàn (>= 28-30cm) -> TỰ ĐỘNG TẮT CẢNH BÁO NGAY LẬP TỨC!
        if (_isEyeWarningVisible) {
          _isEyeWarningVisible = false;
        }
      }
    });
  }

  /// Đồng bộ cảm biến và trạng thái chạy ngầm 24/24 lên Server
  Future<void> _syncDeviceStatus() async {
    if (!mounted || _isSyncing) return;
    _isSyncing = true;
    try {
      final res = await ChildService.sendHeartbeat(
        widget.childId,
        battery: _battery,
        lat: _lat,
        lng: _lng,
        noiseDb: _currentNoiseDb,
        eyeDistanceCm: _distanceCm,
      );
      if (res != null && mounted) {
        final serverLocked = res['isLocked'] == true;
        if (serverLocked != _isLockedByParent) {
          setState(() {
            _isLockedByParent = serverLocked;
          });
        }
        if (res['appRules'] != null) {
          final List rawRules = res['appRules'];
          final parsed = rawRules.map((e) => AppRule.fromJson(e)).toList();
          setState(() {
            _appRules = parsed;
          });
        }
        if (res['schedules'] != null) {
          final List rawSched = res['schedules'];
          final parsed = rawSched.map((e) => ScreenTimeSchedule.fromJson(e)).toList();
          setState(() {
            _schedules = parsed;
          });
        }
      }
    } catch (_) {
    } finally {
      _isSyncing = false;
    }
  }

  /// KHÓA ĐĂNG XUẤT: Yêu cầu mật khẩu của Phụ huynh để thoát
  void _showParentAuthToExitDialog() {
    final passCtrl = TextEditingController();
    bool obscure = true;
    String? errText;
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Row(
            children: [
              Icon(Icons.shield_rounded, color: Color(0xFF3730A3), size: 28),
              SizedBox(width: 10),
              Text('Xác Thực Phụ Huynh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chế độ bảo vệ trẻ em đang chạy ngầm 24/24.\nTrẻ em KHÔNG ĐƯỢC PHÉP tự ý đăng xuất hoặc tắt ứng dụng. Vui lòng nhập Mật Khẩu Phụ Huynh để xác nhận thoát:',
                style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu Phụ huynh',
                  prefixIcon: const Icon(Icons.lock_outline),
                  errorText: errText,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setDlgState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy / Tiếp Tục Bảo Vệ Bé'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF3730A3)),
              onPressed: isVerifying
                  ? null
                  : () async {
                      final input = passCtrl.text.trim();
                      if (input.isEmpty) {
                        setDlgState(() => errText = 'Vui lòng nhập mật khẩu phụ huynh!');
                        return;
                      }
                      setDlgState(() {
                        isVerifying = true;
                        errText = null;
                      });

                      final nav = Navigator.of(context);
                      final verifyRes = await ChildService.verifyParentExit(widget.childId, input);
                      final success = verifyRes['success'] == true;

                      if (success) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('paired_child_id');
                        await prefs.remove('paired_child_name');
                        await prefs.remove('paired_code');
                        if (!mounted) return;
                        if (ctx.mounted) Navigator.pop(ctx);
                        nav.pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      } else {
                        setDlgState(() {
                          isVerifying = false;
                          errText = verifyRes['message'] ?? 'Mật khẩu phụ huynh không chính xác! Con không được phép thoát.';
                        });
                      }
                    },
              icon: isVerifying
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check, size: 16),
              label: const Text('Xác Nhận Đăng Xuất'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Ngăn chặn nút Back Android tự ý thoát app
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showParentAuthToExitDialog();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              const Text('👦', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Máy Của: ${widget.childName}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Row(
                      children: [
                        Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                        SizedBox(width: 4),
                        Text(
                          'Bảo vệ 24/24 bởi Phụ huynh',
                          style: TextStyle(fontSize: 10, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF3730A3),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.lock_open_rounded),
              tooltip: 'Đăng xuất (Cần xác thực Phụ huynh)',
              onPressed: _showParentAuthToExitDialog,
            ),
          ],
        ),
        body: Stack(
          children: [
            // Giao diện chính của màn hình máy trẻ em:
            // Chỉ hiển thị: 1) Mốc thời gian được sử dụng, 2) Các phần mềm được phép dùng, 3) Mã QR & OTP kết nối
            SingleChildScrollView(
              key: const PageStorageKey('kid_screen_scroll'),
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // THẺ 1: MỐC THỜI GIAN ĐƯỢC PHÉP SỬ DỤNG (SCHEDULE / SCREEN TIME)
                  _buildAllowedScheduleCard(),
                  const SizedBox(height: 14),

                  // THẺ 2: CÁC PHẦN MỀM ĐƯỢC PHÉP SỬ DỤNG KHI PHỤ HUYNH CHO PHÉP (WHITELIST APPS)
                  _buildAllowedAppsLauncherCard(),
                  const SizedBox(height: 14),

                  // THẺ 3: MÃ QR & OTP KẾT NỐI MÁY PHỤ HUYNH (ĐỂ PHỤ HUYNH QUÉT KẾT NỐI)
                  _buildPairingQrCard(),
                  const SizedBox(height: 14),

                  // THẺ 4: HỆ THỐNG CẢM BIẾN CHẠY NGẦM 24/24 (MINH BẠCH & THỜI GIAN THỰC)
                  _buildBackgroundSensorsCard(),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Ẩn Surface CameraPreview 1x1 để đảm bảo Android Camera2 Stream liên tục nhận khung hình chạy ngầm
            if (_eyeDistanceService?.cameraController != null &&
                _eyeDistanceService!.cameraController!.value.isInitialized)
              Positioned(
                bottom: 0,
                right: 0,
                width: 1,
                height: 1,
                child: Opacity(
                  opacity: 0.01,
                  child: CameraPreview(_eyeDistanceService!.cameraController!),
                ),
              ),

            // LỚP PHỦ KHÓA TOÀN BỘ KHI PHỤ HUYNH BẬT KHÓA TỪ XA HOẶC NGOÀI GIỜ CHO PHÉP
            if (_isLockedByParent)
              _buildLockedScreenOverlay(),

            // LỚP PHỦ CẢNH BÁO MẮT QUÁ GẦN (TỰ ĐỘNG BẬT KHI <25CM VÀ TỰ ĐỘNG TẮT KHI >=30CM)
            if (_isEyeWarningVisible)
              EyeCareOverlay(
                distanceText: _currentDistance,
                distanceCm: _distanceCm,
                onDismiss: () => setState(() => _isEyeWarningVisible = false),
              ),
          ],
        ),
      ),
    );
  }

  /// THẺ 1: MỐC THỜI GIAN ĐƯỢC PHÉP SỬ DỤNG
  Widget _buildAllowedScheduleCard() {
    final activeBlocking = _findCurrentBlockingSchedule('SocialMedia');
    final isCurfew = activeBlocking != null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: isCurfew ? const Color(0xFFFFFBEB) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCurfew ? const Color(0xFFFEF3C7) : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isCurfew ? Icons.nightlight_round : Icons.alarm_on_rounded,
                    color: isCurfew ? const Color(0xFFD97706) : const Color(0xFF4338CA),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thời Gian Biểu Được Sử Dụng',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        isCurfew ? 'Đang trong giờ giới nghiêm / nghỉ ngơi' : 'Khung giờ an toàn hôm nay: 07:30 - 21:30',
                        style: TextStyle(
                          fontSize: 12,
                          color: isCurfew ? const Color(0xFFB45309) : const Color(0xFF64748B),
                          fontWeight: isCurfew ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCurfew ? Colors.amber[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isCurfew ? '⏰ GIỚI HẠN' : '🟢 ĐƯỢC PHÉP',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isCurfew ? Colors.amber[900] : Colors.green[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Tiến trình thời gian sử dụng hôm nay
            const Row(
              children: [
                Expanded(
                  child: Text(
                    'Thời lượng sử dụng hôm nay:',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8),
                Text('35 phút / 120 phút', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const LinearProgressIndicator(
                value: 35 / 120,
                minHeight: 8,
                backgroundColor: Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Thời gian còn lại:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                Text('Còn 85 phút', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
              ],
            ),

            if (_schedules.isNotEmpty) ...[
              const Divider(height: 18),
              Column(
                children: _schedules.map((s) {
                  final isCurrent = _isScheduleCurrentlyActive(s);
                  final sStart = s.allowedStartTime.length >= 5 ? s.allowedStartTime.substring(0, 5) : s.allowedStartTime;
                  final sEnd = s.allowedEndTime.length >= 5 ? s.allowedEndTime.substring(0, 5) : s.allowedEndTime;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      children: [
                        Icon(isCurrent ? Icons.alarm_on : Icons.access_time, size: 14, color: isCurrent ? Colors.amber[800] : Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${s.scheduleTitle} ($sStart - $sEnd)',
                            style: TextStyle(fontSize: 11, color: isCurrent ? Colors.amber[900] : Colors.black87, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal),
                          ),
                        ),
                        if (isCurrent)
                          Text('Đang áp dụng', style: TextStyle(fontSize: 10, color: Colors.amber[900], fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Lấy danh sách quy tắc ứng dụng thực tế từ server hoặc mặc định an toàn
  List<AppRule> _getEffectiveRules() {
    if (_appRules.isNotEmpty) return _appRules;
    return [
      AppRule(id: 1, childProfileId: widget.childId, appName: 'Duolingo', category: 'Education', status: 'Allowed', packageNameOrDomain: 'com.duolingo'),
      AppRule(id: 2, childProfileId: widget.childId, appName: 'Học Toán Online', category: 'Education', status: 'Allowed', packageNameOrDomain: 'com.google.android.calculator'),
      AppRule(id: 3, childProfileId: widget.childId, appName: 'Sách Nói Bé Yêu', category: 'Education', status: 'Allowed', packageNameOrDomain: 'com.fonos.app'),
      AppRule(id: 4, childProfileId: widget.childId, appName: 'YouTube Kids', category: 'Entertainment', status: 'Limited', dailyLimitMinutes: 45, packageNameOrDomain: 'com.google.android.apps.youtube.kids'),
      AppRule(id: 5, childProfileId: widget.childId, appName: 'TikTok', category: 'SocialMedia', status: 'Blocked', packageNameOrDomain: 'com.ss.android.ugc.trill'),
      AppRule(id: 6, childProfileId: widget.childId, appName: 'Facebook', category: 'SocialMedia', status: 'Blocked', packageNameOrDomain: 'com.facebook.katana'),
      AppRule(id: 7, childProfileId: widget.childId, appName: 'Free Fire', category: 'Game', status: 'Blocked', packageNameOrDomain: 'com.dts.freefireth'),
      AppRule(id: 8, childProfileId: widget.childId, appName: 'Roblox', category: 'Game', status: 'Limited', dailyLimitMinutes: 30, packageNameOrDomain: 'com.roblox.client'),
    ];
  }

  IconData _getCategoryIcon(String category, String appName) {
    final lower = appName.toLowerCase();
    if (lower.contains('duolingo') || lower.contains('học') || lower.contains('toán')) return Icons.school_rounded;
    if (lower.contains('sách') || lower.contains('truyện')) return Icons.auto_stories_rounded;
    if (lower.contains('youtube')) return Icons.play_arrow_rounded;
    if (lower.contains('tiktok')) return Icons.music_note_rounded;
    if (lower.contains('game') || lower.contains('roblox') || lower.contains('fire')) return Icons.sports_esports_rounded;
    if (lower.contains('facebook')) return Icons.public_rounded;
    switch (category) {
      case 'Education':
        return Icons.school_rounded;
      case 'Game':
        return Icons.sports_esports_rounded;
      case 'Entertainment':
        return Icons.smart_display_rounded;
      case 'SocialMedia':
        return Icons.public_rounded;
      default:
        return Icons.apps_rounded;
    }
  }

  Color _getCategoryColor(String category, String appName) {
    final lower = appName.toLowerCase();
    if (lower.contains('duolingo')) return const Color(0xFF58CC02);
    if (lower.contains('youtube')) return const Color(0xFFFF0000);
    if (lower.contains('facebook')) return const Color(0xFF1877F2);
    if (lower.contains('tiktok')) return Colors.black87;
    if (lower.contains('roblox')) return const Color(0xFF1E293B);
    switch (category) {
      case 'Education':
        return const Color(0xFF10B981);
      case 'Game':
        return const Color(0xFFEA580C);
      case 'Entertainment':
        return const Color(0xFF8B5CF6);
      case 'SocialMedia':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF4338CA);
    }
  }

  /// THẺ 2: CÁC PHẦN MỀM ĐƯỢC PHÉP SỬ DỤNG KHI PHỤ HUYNH CHO PHÉP (WHITELIST APPS)
  Widget _buildAllowedAppsLauncherCard() {
    final allRules = _getEffectiveRules().where((r) => r.isActive).toList();
    final allowedRules = allRules.where((r) => r.status != 'Blocked').toList();
    final blockedRules = allRules.where((r) => r.status == 'Blocked').toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: Color(0xFF4338CA), size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ứng Dụng Được Phép Sử Dụng',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'Phụ huynh cho phép (${allowedRules.length} ứng dụng an toàn)',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (allowedRules.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.lock_clock_rounded, color: Colors.orange, size: 36),
                    SizedBox(height: 8),
                    Text(
                      'Hiện tại chưa có ứng dụng nào được Phụ huynh cho phép mở.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: allowedRules.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.1,
                ),
                itemBuilder: (ctx, i) {
                  final rule = allowedRules[i];
                  final icon = _getCategoryIcon(rule.category, rule.appName);
                  final iconColor = _getCategoryColor(rule.category, rule.appName);

                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _launchAllowedApp(rule),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: iconColor, size: 20),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  rule.appName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  rule.status == 'Limited'
                                      ? '⏳ Giới hạn: ${rule.dailyLimitMinutes}p'
                                      : '✅ Cho phép mở',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            // Danh sách các ứng dụng Ba Mẹ đã khóa hoàn toàn
            if (blockedRules.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.block_rounded, color: Colors.red, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Đang bị Ba Mẹ khóa (${blockedRules.length} app)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: blockedRules.map((rule) {
                  return ActionChip(
                    avatar: const Icon(Icons.lock, size: 14, color: Colors.red),
                    label: Text(
                      rule.appName,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.red),
                    ),
                    backgroundColor: const Color(0xFFFEF2F2),
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    onPressed: () => _showEnforcedBlockDialog(rule.appName),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _launchAllowedApp(AppRule rule) async {
    if (_isLockedByParent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 Thiết bị đang bị Phụ huynh khóa từ xa. Toàn bộ thao tác ứng dụng đã tạm ngưng!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('Đang mở ${rule.appName}... (Được Ba Mẹ cấp phép)')),
          ],
        ),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 2),
      ),
    );

    // Kích hoạt mở ứng dụng thật trên máy qua package
    final pkgs = AppBlockerService.getMatchingPackages(rule.appName, rule.packageNameOrDomain);
    bool launched = false;
    for (final pkg in pkgs) {
      launched = await AppBlockerService.launchApp(pkg);
      if (launched) break;
    }

    if (!launched) {
      final query = pkgs.isNotEmpty
          ? 'https://play.google.com/store/apps/details?id=${pkgs.first}'
          : 'https://www.google.com/search?q=${Uri.encodeComponent(rule.appName)}';
      try {
        final uri = Uri.parse(query);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    }
  }

  /// THẺ 3: MÃ QR & OTP KẾT NỐI MÁY PHỤ HUYNH
  Widget _buildPairingQrCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF4338CA), size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mã QR & OTP Kết Nối Máy Ba Mẹ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'Xuất trình mã này khi Phụ huynh cần quét kết nối máy con',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: QrImageView(
                    data: 'CHILDGUARD_PAIR:$_pairingCode',
                    version: QrVersions.auto,
                    size: 130.0,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF3730A3)),
                    dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF1E1B4B)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mã Ghép Nối 6 Số:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFD1D5DB)),
                        ),
                        child: Text(
                          _pairingCode,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                            color: Color(0xFF3730A3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Phụ huynh mở máy Ba Mẹ -> Bấm "Quét QR Máy Con" để liên kết tức thì.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// THẺ 4: HỆ THỐNG CẢM BIẾN CHẠY NGẦM 24/24
  Widget _buildBackgroundSensorsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.security_rounded, color: Colors.green.shade700, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cảm Biến Bảo Vệ Chạy Ngầm 24/24',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'Tự động gửi dữ liệu định vị, tiếng ồn & cự ly mắt về máy Ba Mẹ',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ĐANG BẬT',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 3 thông số cảm biến thời gian thực thật từ phần cứng
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.visibility_rounded, size: 14, color: Color(0xFFD97706)),
                            SizedBox(width: 4),
                            Text('Cự ly mắt', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _distanceCm < 25.0 ? '$_currentDistance (Gần)' : '$_currentDistance (Chuẩn)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _distanceCm < 25.0 ? Colors.red : Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.mic_rounded, size: 14, color: Color(0xFF0D9488)),
                            SizedBox(width: 4),
                            Text('Tiếng ồn', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Builder(
                          builder: (context) {
                            String noiseStatus = 'Êm dịu';
                            Color nColor = Colors.teal[700]!;
                            if (_currentNoiseDb > 80) {
                              noiseStatus = 'Rất ồn!';
                              nColor = Colors.red[700]!;
                            } else if (_currentNoiseDb > 65) {
                              noiseStatus = 'Ồn vừa';
                              nColor = Colors.orange[800]!;
                            }
                            return Text(
                              '${_currentNoiseDb.round()} dB ($noiseStatus)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: nColor),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF2563EB)),
                            SizedBox(width: 4),
                            Text('Vị trí GPS', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (_lat != 0 && _lng != 0)
                              ? '${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)}'
                              : 'Đang bắt GPS...',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// LỚP PHỦ KHÓA TOÀN BỘ KHI PHỤ HUYNH BẬT KHÓA TỪ XA
  Widget _buildLockedScreenOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.94),
      width: double.infinity,
      height: double.infinity,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.redAccent, width: 3),
                  ),
                  child: const Icon(Icons.lock_rounded, size: 50, color: Colors.redAccent),
                ),
                const SizedBox(height: 20),
                const Text(
                  'THIẾT BỊ ĐÃ BỊ KHÓA TỪ XA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield, color: Colors.redAccent, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Lệnh khóa tức thời bởi Phụ huynh',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Đã đến giờ nghỉ ngơi hoặc học bài.\nToàn bộ thao tác ứng dụng trên máy con đã tạm ngưng hoạt động.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 28),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Row(
                          children: [
                            Icon(Icons.phone_in_talk, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Cuộc Gọi Khẩn Cấp'),
                          ],
                        ),
                        content: const Text('Máy luôn hỗ trợ các cuộc gọi khẩn cấp (113, 114, 115) hoặc gọi trực tiếp đến số điện thoại của Ba Mẹ.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone_in_talk_rounded, size: 16, color: Colors.greenAccent),
                  label: const Text('Cuộc gọi khẩn cấp SOS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isScheduleCurrentlyActive(ScreenTimeSchedule s) {
    if (!s.isActive) return false;
    final now = DateTime.now();
    final currentMin = now.hour * 60 + now.minute;
    final weekday = now.weekday;

    bool dayMatches = false;
    final dow = s.dayOfWeek.toLowerCase();
    if (dow.contains('tất cả') || dow.contains('mỗi ngày') || dow.contains('all')) {
      dayMatches = true;
    } else if (dow.contains('thứ 2 - thứ 6') || dow.contains('ngày học') || dow.contains('weekday')) {
      dayMatches = weekday >= DateTime.monday && weekday <= DateTime.friday;
    } else if (dow.contains('thứ 7') || dow.contains('chủ nhật') || dow.contains('cuối tuần') || dow.contains('weekend')) {
      dayMatches = weekday == DateTime.saturday || weekday == DateTime.sunday;
    } else {
      dayMatches = true;
    }

    if (!dayMatches) return false;

    final startParts = s.allowedStartTime.split(':');
    final endParts = s.allowedEndTime.split(':');
    if (startParts.length < 2 || endParts.length < 2) return false;

    final startHour = int.tryParse(startParts[0]) ?? 0;
    final startMinute = int.tryParse(startParts[1]) ?? 0;
    final endHour = int.tryParse(endParts[0]) ?? 0;
    final endMinute = int.tryParse(endParts[1]) ?? 0;

    final startMin = startHour * 60 + startMinute;
    final endMin = endHour * 60 + endMinute;

    if (startMin <= endMin) {
      return currentMin >= startMin && currentMin < endMin;
    } else {
      return currentMin >= startMin || currentMin < endMin;
    }
  }

  ScreenTimeSchedule? _findCurrentBlockingSchedule(String category) {
    if (_simulateCurfewActive && category != 'Education') {
      final now = DateTime.now();
      return ScreenTimeSchedule(
        id: -1,
        childProfileId: widget.childId,
        scheduleTitle: 'Khung Giờ Học Bài & Giới Nghiêm (Chế độ test)',
        dayOfWeek: 'Hôm nay',
        allowedStartTime: '${now.hour.toString().padLeft(2, '0')}:00:00',
        allowedEndTime: '${((now.hour + 1) % 24).toString().padLeft(2, '0')}:00:00',
      );
    }

    for (final s in _schedules) {
      if (_isScheduleCurrentlyActive(s)) {
        final titleLower = s.scheduleTitle.toLowerCase();
        final isCurfewOrStudy = titleLower.contains('học') ||
            titleLower.contains('ngủ') ||
            titleLower.contains('khóa') ||
            titleLower.contains('giới nghiêm') ||
            titleLower.contains('curfew') ||
            titleLower.contains('sleep') ||
            titleLower.contains('bedtime');

        if (isCurfewOrStudy && category != 'Education') {
          return s;
        }
      }
    }
    return null;
  }
}
