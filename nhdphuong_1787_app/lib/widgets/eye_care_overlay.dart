import 'package:flutter/material.dart';

class EyeCareOverlay extends StatefulWidget {
  final VoidCallback onDismiss;
  final String distanceText;
  final double distanceCm;
  final ValueChanged<double>? onDistanceChanged;

  const EyeCareOverlay({
    super.key,
    required this.onDismiss,
    this.distanceText = '18 cm',
    this.distanceCm = 18.0,
    this.onDistanceChanged,
  });

  @override
  State<EyeCareOverlay> createState() => _EyeCareOverlayState();
}

class _EyeCareOverlayState extends State<EyeCareOverlay> {
  late double _currentCm;

  @override
  void initState() {
    super.initState();
    _currentCm = widget.distanceCm;
    _checkAutoDismiss();
  }

  @override
  void didUpdateWidget(covariant EyeCareOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.distanceCm != oldWidget.distanceCm) {
      _currentCm = widget.distanceCm;
      _checkAutoDismiss();
    }
  }

  void _checkAutoDismiss() {
    if (_currentCm >= 28.0) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && _currentCm >= 28.0) {
          widget.onDismiss();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSafe = _currentCm >= 28.0;
    final progress = (_currentCm / 35.0).clamp(0.0, 1.0);

    return Container(
      color: Colors.black.withValues(alpha: 0.95),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon cảnh báo mắt
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: isSafe ? Colors.green.withValues(alpha: 0.25) : Colors.red.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                  border: Border.all(color: isSafe ? Colors.greenAccent : Colors.redAccent, width: 3),
                ),
                child: Icon(
                  isSafe ? Icons.check_circle_rounded : Icons.visibility_rounded,
                  size: 72,
                  color: isSafe ? Colors.greenAccent : Colors.amberAccent,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                isSafe ? '✅ KHOẢNG CÁCH ĐÃ AN TOÀN!' : '👀 ÔI KHÔNG! MẮT QUÁ GẦN RỒI!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSafe ? Colors.greenAccent : Colors.amberAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),

              // Badge khoảng cách thời gian thực
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSafe ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSafe ? Colors.green : Colors.redAccent),
                ),
                child: Text(
                  'Cự ly hiện tại: ${_currentCm.toInt()} cm ${isSafe ? "(Đạt chuẩn an toàn)" : "(Nguy hiểm < 25cm)"}',
                  style: TextStyle(
                    color: isSafe ? Colors.greenAccent : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Thanh tiến trình đo cự ly mắt trực quan
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isSafe ? Colors.greenAccent : (_currentCm > 22 ? Colors.orange : Colors.redAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('10cm (Dí sát)', style: TextStyle(color: Colors.white54, fontSize: 10)),
                        Text('25cm (Ngưỡng cảnh báo)', style: TextStyle(color: Colors.amberAccent, fontSize: 10)),
                        Text('35cm (An toàn)', style: TextStyle(color: Colors.greenAccent, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Hướng dẫn hành động & Cơ chế tự động tắt
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isSafe ? Colors.greenAccent : Colors.white24),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isSafe ? Icons.auto_awesome : Icons.phone_android, color: isSafe ? Colors.greenAccent : Colors.amberAccent, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          isSafe ? '🎉 Đang tự động mở lại màn hình...' : '👉 Hãy đưa điện thoại ra xa ít nhất 30cm',
                          style: TextStyle(
                            color: isSafe ? Colors.greenAccent : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Cơ chế AI Eye-Care bảo vệ mắt: Màn hình này sẽ TỰ ĐỘNG BIẾN MẤT ngay khi điện thoại cách mắt trên 30cm mà không cần chạm nút nào.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Thanh điều chỉnh mô phỏng cự ly mắt để kiểm tra tính năng tự động tắt
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    const Text(
                      '📱 Thử nghiệm đưa máy ra xa / lại gần mắt:',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    Slider(
                      value: _currentCm,
                      min: 10.0,
                      max: 45.0,
                      divisions: 35,
                      activeColor: isSafe ? Colors.greenAccent : Colors.redAccent,
                      inactiveColor: Colors.white24,
                      onChanged: (val) {
                        setState(() {
                          _currentCm = val;
                        });
                        widget.onDistanceChanged?.call(val);
                        _checkAutoDismiss();
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.green),
                          label: const Text('Đưa máy ra xa (35cm) -> Tự tắt', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            setState(() => _currentCm = 35.0);
                            widget.onDistanceChanged?.call(35.0);
                            _checkAutoDismiss();
                          },
                        ),
                      ],
                    ),
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
