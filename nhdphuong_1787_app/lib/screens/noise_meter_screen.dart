import 'package:flutter/material.dart';
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

    // Nếu vượt ngưỡng 80 dB, tự động gửi cảnh báo lên Server
    if (value > 80) {
      final alert = AlertLog(
        id: 0,
        childProfileId: widget.childId,
        alertType: 'NOISE_DANGER',
        value: '${value.round()} dB',
        severity: 'Danger',
        message: 'Phát hiện tiếng ồn nguy hiểm (${value.round()} dB) tại phòng bé ${widget.childName}',
        createdAt: DateTime.now(),
      );
      ChildService.sendAlert(alert);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Đo Tiếng Ồn Xung Quanh: ${widget.childName}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
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
            const SizedBox(height: 24),

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
            const SizedBox(height: 24),

            // Thanh trượt mô phỏng tiếng ồn cho Thầy cô test
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
                          'Thanh Điều Chỉnh Giả Lập Mức Âm Lượng (Test)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Kéo thanh trượt để thử nghiệm phản ứng hệ thống trên máy ảo:',
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
