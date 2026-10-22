import 'dart:async';
import 'package:flutter/material.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/alert_log.dart';
import '../services/child_service.dart';

class NoiseMeterScreen extends StatefulWidget {
  final int childId;
  final String childName;

  const NoiseMeterScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<NoiseMeterScreen> createState() => _NoiseMeterScreenState();
}

class _NoiseMeterScreenState extends State<NoiseMeterScreen> {
  double _currentDecibel = 48.0;
  String _noiseStatus = 'Môi trường yên tĩnh, an toàn';
  Color _statusColor = Colors.green;

  int _selectedMode = 0; // 0: Nhận từ xa từ máy con, 1: Đo trực tiếp qua Micro máy này
  Timer? _remotePollTimer;
  NoiseMeter? _noiseMeter;
  StreamSubscription<NoiseReading>? _noiseSub;
  bool _isMicActive = false;
  String _micStatusText = '📡 Đang kết nối nhận dữ liệu từ xa từ phòng bé...';
  DateTime? _lastAlertSent;

  @override
  void initState() {
    super.initState();
    _startMode();
  }

  @override
  void dispose() {
    _remotePollTimer?.cancel();
    _noiseSub?.cancel();
    super.dispose();
  }

  void _startMode() {
    if (_selectedMode == 0) {
      _noiseSub?.cancel();
      _isMicActive = false;
      _micStatusText = '📡 Đang theo dõi trực tiếp âm thanh từ phòng bé ${widget.childName}';
      _pollRemoteChildNoise();
      _remotePollTimer?.cancel();
      _remotePollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollRemoteChildNoise());
    } else {
      _remotePollTimer?.cancel();
      _startMicrophone();
    }
  }

  Future<void> _pollRemoteChildNoise() async {
    try {
      final children = await ChildService.getChildren();
      final child = children.firstWhere(
        (c) => c.id == widget.childId,
        orElse: () => children.isNotEmpty ? children.first : throw Exception(),
      );
      if (mounted) {
        _updateDecibel(child.currentNoiseDb);
        setState(() {
          _micStatusText = '📡 Đang nhận trực tiếp từ máy bé ${child.fullName} (${child.currentNoiseDb.round()} dB)';
        });
      }
    } catch (_) {}
  }

  Future<void> _startMicrophone() async {
    try {
      final status = await Permission.microphone.request();
      if (status.isGranted) {
        _noiseMeter = NoiseMeter();
        _noiseSub = _noiseMeter?.noise.listen(
          (NoiseReading reading) {
            if (!mounted) return;
            double db = reading.meanDecibel;
            if (db.isFinite && !db.isNaN) {
              db = db.clamp(30.0, 115.0);
              _updateDecibel(db);
              if (!_isMicActive) {
                setState(() {
                  _isMicActive = true;
                  _micStatusText = '🎙️ Micro thật đang thu âm môi trường thời gian thực';
                });
              }
            }
          },
          onError: (_) {
            if (mounted) {
              setState(() {
                _isMicActive = false;
                _micStatusText = 'Micro không khả dụng (Máy ảo - Dùng thanh trượt)';
              });
            }
          },
        );
      } else {
        if (mounted) {
          setState(() {
            _isMicActive = false;
            _micStatusText = 'Chưa cấp quyền Micro (Có thể kéo thanh trượt bên dưới)';
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isMicActive = false;
          _micStatusText = 'Đang chạy chế độ mô phỏng âm lượng';
        });
      }
    }
  }

  void _updateDecibel(double value) {
    setState(() {
      _currentDecibel = value;
      if (value < 65) {
        _noiseStatus = 'Yên tĩnh / Bình thường (Thích hợp học tập & nghỉ ngơi)';
        _statusColor = Colors.green;
      } else if (value <= 80) {
        _noiseStatus = 'Môi trường ồn ào vừa phải (Phố xá, giờ ra chơi)';
        _statusColor = Colors.orange;
      } else {
        _noiseStatus = '⚠️ BÁO ĐỘNG ĐỎ: ÂM THANH QUÁ LỚN / TIẾNG THÉT NGUY HIỂM!';
        _statusColor = Colors.red;
      }
    });

    // Nếu vượt ngưỡng 80 dB, tự động gửi cảnh báo lên Server (chặn spam: tối thiểu cách 5s một lần)
    if (value > 80) {
      final now = DateTime.now();
      if (_lastAlertSent == null || now.difference(_lastAlertSent!).inSeconds >= 5) {
        _lastAlertSent = now;
        final alert = AlertLog(
          id: 0,
          childProfileId: widget.childId,
          alertType: 'NOISE_DANGER',
          value: '${value.round()} dB',
          severity: 'Danger',
          message: 'Phát hiện tiếng ồn nguy hiểm (${value.round()} dB) tại phòng bé ${widget.childName}',
          createdAt: now,
        );
        ChildService.sendAlert(alert);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Đo Tiếng Ồn: ${widget.childName}'),
        actions: [
          IconButton(
            icon: Icon(_isMicActive ? Icons.mic : Icons.mic_off, color: _isMicActive ? Colors.greenAccent : Colors.white70),
            tooltip: _isMicActive ? 'Micro đang bật' : 'Bật lại micro',
            onPressed: () {
              _noiseSub?.cancel();
              _startMicrophone();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Chọn chế độ: Nghe từ xa từ phòng con vs Đo trực tiếp micro máy này
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  icon: Icon(Icons.wifi_tethering),
                  label: Text('📡 Từ Xa (Phòng Con)'),
                ),
                ButtonSegment(
                  value: 1,
                  icon: Icon(Icons.mic),
                  label: Text('🎙️ Tại Chỗ (Máy Này)'),
                ),
              ],
              selected: {_selectedMode},
              onSelectionChanged: (Set<int> newSelection) {
                setState(() => _selectedMode = newSelection.first);
                _startMode();
              },
            ),
            const SizedBox(height: 16),

            // Banner báo trạng thái Micro thật hay giả lập
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _isMicActive ? Colors.green[50] : Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _isMicActive ? Colors.green : Colors.amber),
              ),
              child: Row(
                children: [
                  Icon(_isMicActive ? Icons.sensors : Icons.tune, size: 20, color: _isMicActive ? Colors.green[800] : Colors.brown),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _micStatusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _isMicActive ? Colors.green[900] : Colors.brown,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      _currentDecibel > 80 ? Icons.volume_up : Icons.mic,
                      size: 64,
                      color: _statusColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${_currentDecibel.round()} dB',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: _statusColor,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _statusColor),
                      ),
                      child: Text(
                        _noiseStatus,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Thanh thang đo chuẩn Decibel
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thang Đo Tiêu Chuẩn Thính Giác (WHO):', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: const [
                        Icon(Icons.circle, size: 12, color: Colors.green),
                        SizedBox(width: 8),
                        Text('< 65 dB: Yên tĩnh, an toàn cho trẻ'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: const [
                        Icon(Icons.circle, size: 12, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('65 - 80 dB: Ồn ào (Không nên kéo dài)'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: const [
                        Icon(Icons.circle, size: 12, color: Colors.red),
                        SizedBox(width: 8),
                        Text('> 80 dB: Nguy hại thính giác / Tiếng la hét SOS'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Thanh trượt điều chỉnh phụ trợ (cho phép test trên máy ảo không có mic)
            Card(
              color: Colors.blue[50],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tune, color: Colors.blueAccent),
                        SizedBox(width: 8),
                        Text(
                          'Thanh Giả Lập / Can Thiệp Thủ Công (Test Máy Ảo)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Nếu chạy trên máy ảo không có Micro thật, kéo thanh trượt để thử nghiệm cảnh báo:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Slider(
                      value: _currentDecibel,
                      min: 30,
                      max: 110,
                      divisions: 16,
                      label: '${_currentDecibel.round()} dB',
                      onChanged: (v) => _updateDecibel(v),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => _updateDecibel(45),
                          child: const Text('Phòng yên tĩnh (45dB)'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[100]),
                          onPressed: () => _updateDecibel(92),
                          child: const Text('Cảnh báo la hét (92dB)', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
