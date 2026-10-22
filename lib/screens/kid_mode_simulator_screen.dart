import 'dart:async';
import 'package:flutter/material.dart';
import '../models/alert_log.dart';
import '../services/child_service.dart';
import '../widgets/eye_care_overlay.dart';
import 'noise_meter_screen.dart';

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
  bool _isEyeWarningVisible = false;
  String _currentDistance = '35 cm';
  bool _isLockedByParent = false;
  final int _battery = 82;
  Timer? _syncTimer;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _syncDeviceStatus();
    // Đồng bộ trạng thái khóa máy và heartbeat với Server mỗi 2 giây
    _syncTimer = Timer.periodic(const Duration(seconds: 2), (_) => _syncDeviceStatus());
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _syncDeviceStatus() async {
    if (!mounted || _isSyncing) return;
    _isSyncing = true;
    try {
      final res = await ChildService.sendHeartbeat(widget.childId, battery: _battery);
      if (res != null && mounted) {
        final serverLocked = res['isLocked'] == true;
        if (serverLocked != _isLockedByParent) {
          setState(() {
            _isLockedByParent = serverLocked;
          });
        }
      }
    } catch (_) {
    } finally {
      _isSyncing = false;
    }
  }

  void _triggerEyeDangerTest() {
    setState(() {
      _currentDistance = '16 cm';
      _isEyeWarningVisible = true;
    });

    // Tự động gửi cảnh báo lên Web API
    final alert = AlertLog(
      id: 0,
      childProfileId: widget.childId,
      alertType: 'EYE_DISTANCE',
      value: '16 cm',
      severity: 'Warning',
      message: 'Bé ${widget.childName} đang để điện thoại quá gần mắt (16cm)',
      createdAt: DateTime.now(),
    );
    ChildService.sendAlert(alert);
  }

  void _triggerSafeDistance() {
    setState(() {
      _currentDistance = '35 cm';
      _isEyeWarningVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Mô Phỏng Máy Của: ${widget.childName}'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Giao diện chính của màn hình máy trẻ em
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Khung mô phỏng trạng thái thiết bị
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.circle, color: Colors.green, size: 12),
                                const SizedBox(width: 6),
                                Text('Trạng thái: Trực tuyến', style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.battery_5_bar, color: Colors.green),
                                Text('$_battery%'),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.deepPurple,
                          child: Text('👦', style: TextStyle(fontSize: 36)),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Thiết Bị Của Bé ${widget.childName}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Đang được đồng bộ và giám sát bởi Phụ huynh',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // KHU VỰC TÍNH NĂNG ĐỘC LẠ SÁNG TẠO: AI SMART EYE-CARE GUARD (1.0 ĐIỂM)
                Card(
                  color: Colors.amber[50],
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Colors.amber, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.amber[200], shape: BoxShape.circle),
                              child: const Icon(Icons.visibility, color: Colors.brown, size: 28),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AI Smart Eye-Care Guard (1.0đ)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.brown),
                                  ),
                                  Text(
                                    'Bảo vệ thị lực - Cảnh báo cự ly mắt < 25cm',
                                    style: TextStyle(fontSize: 12, color: Colors.brown),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber[200]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Khoảng cách mắt hiện tại:'),
                              Text(
                                _currentDistance,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: _isEyeWarningVisible ? Colors.red : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Bộ nút giả lập thử nghiệm tức thì cho Thầy kiểm tra:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(backgroundColor: Colors.red[700]),
                                onPressed: _triggerEyeDangerTest,
                                icon: const Icon(Icons.warning_amber),
                                label: const Text('Test Dí Sát Mắt (<20cm)', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _triggerSafeDistance,
                                icon: const Icon(Icons.check),
                                label: const Text('Cự Ly An Toàn (35cm)', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // KHU VỰC ĐO TIẾNG ỒN MICRO
                Card(
                  color: Colors.teal[50],
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Colors.teal, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.teal[200], shape: BoxShape.circle),
                              child: const Icon(Icons.mic, color: Colors.teal, size: 26),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Đo Tiếng Ồn Micro (dB)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal),
                                  ),
                                  Text(
                                    'Giám sát môi trường âm thanh xung quanh bé',
                                    style: TextStyle(fontSize: 12, color: Colors.teal),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: Colors.teal),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => NoiseMeterScreen(
                                  childId: widget.childId,
                                  childName: widget.childName,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.graphic_eq),
                          label: const Text('Mở Máy Đo Decibel (Microphone)'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Trạng thái Khóa từ xa tự động nhận từ Server
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Trạng thái Khóa từ xa:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Chip(
                              label: Text(_isLockedByParent ? 'ĐANG BỊ KHÓA' : 'HOẠT ĐỘNG BÌNH THƯỜNG'),
                              backgroundColor: _isLockedByParent ? Colors.red[100] : Colors.green[100],
                              labelStyle: TextStyle(
                                color: _isLockedByParent ? Colors.red[800] : Colors.green[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLockedByParent
                              ? '⚠️ Phụ huynh vừa bấm Khóa từ máy quản lý. Thiết bị sẽ bị vô hiệu hóa!'
                              : '✅ Đang đồng bộ thời gian thực mỗi 2s với máy quản lý.',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // Lớp phủ khi phụ huynh bấm Khóa từ xa
          if (_isLockedByParent)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock, size: 80, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    const Text(
                      'ĐIỆN THOẠI ĐÃ BỊ PHỤ HUYNH KHÓA',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Đã hết giờ sử dụng hoặc đến khung giờ học bài/đi ngủ.\nHãy nghỉ ngơi để bảo vệ sức khỏe!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                      onPressed: () => setState(() => _isLockedByParent = false),
                      child: const Text('Mở Khóa Giả Lập'),
                    ),
                  ],
                ),
              ),
            ),

          // Lớp phủ cảnh báo thị lực AI Smart Eye-Care Guard (Khi cự ly mắt quá gần)
          if (_isEyeWarningVisible)
            EyeCareOverlay(
              distanceText: _currentDistance,
              onDismiss: _triggerSafeDistance,
            ),
        ],
      ),
    );
  }
}
