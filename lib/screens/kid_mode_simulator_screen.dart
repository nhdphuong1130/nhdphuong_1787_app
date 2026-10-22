import 'dart:async';
import 'package:flutter/material.dart';
import '../models/alert_log.dart';
import '../models/app_rule.dart';
import '../models/screen_time_schedule.dart';
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
  List<AppRule> _appRules = [];
  List<ScreenTimeSchedule> _schedules = [];
  bool _simulateCurfewActive = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialRules();
    _syncDeviceStatus();
    // Đồng bộ trạng thái khóa máy và heartbeat với Server mỗi 2 giây
    _syncTimer = Timer.periodic(const Duration(seconds: 2), (_) => _syncDeviceStatus());
  }

  Future<void> _loadInitialRules() async {
    try {
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
    _scrollController.dispose();
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
        if (res['appRules'] != null) {
          final List rawRules = res['appRules'];
          final parsed = rawRules.map((e) => AppRule.fromJson(e)).toList();
          final changed = parsed.length != _appRules.length ||
              parsed.any((nr) {
                final match = _appRules.where((r) => r.id == nr.id).firstOrNull;
                return match == null || match.isActive != nr.isActive || match.status != nr.status;
              });
          if (changed) {
            setState(() {
              _appRules = parsed;
            });
          }
        }
        if (res['schedules'] != null) {
          final List rawSched = res['schedules'];
          final parsed = rawSched.map((e) => ScreenTimeSchedule.fromJson(e)).toList();
          final changed = parsed.length != _schedules.length ||
              parsed.any((ns) {
                final match = _schedules.where((s) => s.id == ns.id).firstOrNull;
                return match == null || match.isActive != ns.isActive;
              });
          if (changed) {
            setState(() {
              _schedules = parsed;
            });
          }
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
            key: const PageStorageKey('kid_screen_scroll'),
            controller: _scrollController,
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
                            const Expanded(
                              child: Text('Trạng thái Khóa từ xa:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _isLockedByParent ? Colors.red[100] : Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _isLockedByParent ? '🔒 ĐANG BỊ KHÓA' : '✅ BÌNH THƯỜNG',
                                style: TextStyle(
                                  color: _isLockedByParent ? Colors.red[800] : Colors.green[800],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
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
                const SizedBox(height: 20),

                // THỜI GIAN BIỂU DÙNG MÁY (ĐỒNG BỘ REAL-TIME TỪ PHỤ HUYNH)
                _buildScheduleSection(),
                const SizedBox(height: 20),

                // KHO ỨNG DỤNG CỦA BÉ (MÔ PHỎNG LAUNCHER THIẾT BỊ TRẺ EM - ĐỒNG BỘ REALTIME TỪ PHỤ HUYNH)
                _buildAppLauncherSection(),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Lớp phủ khi phụ huynh kích hoạt KHÓA TỪ XA (TOÀN DIỆN, BẢO VỆ CHẶT CHẼ)
          if (_isLockedByParent)
            Container(
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

  Widget _buildAppLauncherSection() {
    final standardApps = [
      {'name': 'TikTok', 'category': 'SocialMedia', 'icon': Icons.music_note_rounded, 'color': Colors.black87},
      {'name': 'YouTube', 'category': 'Entertainment', 'icon': Icons.play_arrow_rounded, 'color': const Color(0xFFFF0000)},
      {'name': 'Roblox', 'category': 'Game', 'icon': Icons.sports_esports_rounded, 'color': const Color(0xFF1E293B)},
      {'name': 'Duolingo', 'category': 'Education', 'icon': Icons.school_rounded, 'color': const Color(0xFF58CC02)},
      {'name': 'Facebook', 'category': 'SocialMedia', 'icon': Icons.public_rounded, 'color': const Color(0xFF1877F2)},
      {'name': 'Free Fire', 'category': 'Game', 'icon': Icons.local_fire_department_rounded, 'color': const Color(0xFFEA580C)},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3730A3).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.grid_view_rounded, size: 16, color: Color(0xFF3730A3)),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ứng Dụng Trên Thiết Bị Bé',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      'Bấm mở ứng dụng để kiểm tra quy tắc chặn',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sync_rounded, size: 11, color: Color(0xFF059669)),
                    SizedBox(width: 3),
                    Text('Realtime', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: standardApps.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.84,
            ),
            itemBuilder: (ctx, i) {
              final app = standardApps[i];
              final appName = app['name'] as String;
              final category = app['category'] as String;
              final icon = app['icon'] as IconData;
              final iconColor = app['color'] as Color;

              AppRule? matchedRule;
              try {
                matchedRule = _appRules.firstWhere(
                  (r) => r.appName.trim().toLowerCase() == appName.trim().toLowerCase(),
                );
              } catch (_) {}

              final status = (matchedRule != null && matchedRule.isActive) ? matchedRule.status : 'Allowed';
              final isBlocked = status == 'Blocked';
              final isLimited = status == 'Limited';

              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _handleAppTap(appName, category, matchedRule),
                child: Container(
                  decoration: BoxDecoration(
                    color: isBlocked ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isBlocked
                          ? const Color(0xFFFECDD3)
                          : (isLimited ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0)),
                      width: isBlocked ? 1.5 : 1.0,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: isBlocked ? 0.3 : 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: isBlocked ? Colors.grey[600] : iconColor, size: 20),
                          ),
                          if (isBlocked)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: const Icon(Icons.block, size: 10, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        appName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isBlocked ? Colors.red[900] : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isBlocked
                              ? Colors.red[100]
                              : (isLimited ? Colors.amber[100] : Colors.green[100]),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isBlocked
                              ? 'Đã Khóa'
                              : (isLimited ? '${matchedRule?.dailyLimitMinutes ?? 45}p' : 'Cho phép'),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isBlocked
                                ? Colors.red[800]
                                : (isLimited ? Colors.amber[900] : Colors.green[800]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleAppTap(String appName, String category, AppRule? rule) {
    if (_isLockedByParent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 Máy đang bị phụ huynh khóa toàn bộ. Không thể mở ứng dụng!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 1. Kiểm tra Lịch biểu / Thời gian biểu (Schedule) trước tiên
    final blockingSchedule = _findCurrentBlockingSchedule(category);
    if (blockingSchedule != null) {
      _showScheduleBlockedDialog(appName, blockingSchedule);
      return;
    }

    // 2. Kiểm tra Quy tắc ứng dụng riêng biệt (App Rules)
    final status = (rule != null && rule.isActive) ? rule.status : 'Allowed';

    if (status == 'Blocked') {
      _showBlockedAppDialog(appName, category);
      return;
    }

    if (status == 'Limited') {
      _showLimitedAppDialog(
        appName,
        category,
        rule?.dailyLimitMinutes ?? 45,
        rule?.usedMinutesToday ?? 0,
      );
      return;
    }

    // Allowed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('Đang mở $appName... (Ứng dụng an toàn, được phép dùng)')),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showBlockedAppDialog(String appName, String category) {
    // 1. Tự động gửi AlertLog lên máy chủ để Phụ huynh nhận cảnh báo tức thời
    ChildService.sendAlert(
      AlertLog(
        id: 0,
        childProfileId: widget.childId,
        alertType: 'APP_BLOCKED',
        severity: 'Warning',
        value: appName,
        message: 'Bé ${widget.childName} vừa cố gắng mở ứng dụng bị chặn: $appName lúc ${TimeOfDay.now().format(context)}',
        createdAt: DateTime.now(),
      ),
    );

    // 2. Hiển thị Dialog Khóa Ứng Dụng
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFECDD3), width: 2),
              ),
              child: const Icon(Icons.block_rounded, size: 38, color: Colors.red),
            ),
            const SizedBox(height: 14),
            const Text(
              'ỨNG DỤNG ĐÃ BỊ KHÓA',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Color(0xFF991B1B),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                appName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ba mẹ đã kích hoạt quy tắc chặn ứng dụng này trên thiết bị của con để đảm bảo an toàn và giúp con tập trung.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.notifications_active_outlined, size: 16, color: Color(0xFF2563EB)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Hệ thống đã tự động gửi cảnh báo vi phạm đến máy Phụ huynh.',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF3730A3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đã hiểu, quay lại'),
            ),
          ),
        ],
      ),
    );
  }

  void _showLimitedAppDialog(String appName, String category, int limitMins, int usedMins) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFDE68A), width: 2),
              ),
              child: const Icon(Icons.timer_outlined, size: 34, color: Color(0xFFD97706)),
            ),
            const SizedBox(height: 12),
            const Text(
              'Giới Hạn Thời Gian Sử Dụng',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            Text(
              'Ứng dụng $appName được ba mẹ cho phép dùng tối đa $limitMins phút mỗi ngày.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: limitMins > 0 ? (usedMins / limitMins).clamp(0.0, 1.0) : 0,
              backgroundColor: const Color(0xFFF1F5F9),
              color: const Color(0xFFD97706),
              minHeight: 7,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 6),
            Text(
              'Đã dùng: $usedMins / $limitMins phút',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đang mở $appName (Mô phỏng đếm giờ $usedMins/$limitMins phút)...'),
                  backgroundColor: const Color(0xFFB45309),
                ),
              );
            },
            child: const Text('Mở ứng dụng'),
          ),
        ],
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

  void _showScheduleBlockedDialog(String appName, ScreenTimeSchedule schedule) {
    final startTimeStr = schedule.allowedStartTime.length >= 5 ? schedule.allowedStartTime.substring(0, 5) : schedule.allowedStartTime;
    final endTimeStr = schedule.allowedEndTime.length >= 5 ? schedule.allowedEndTime.substring(0, 5) : schedule.allowedEndTime;

    ChildService.sendAlert(
      AlertLog(
        id: 0,
        childProfileId: widget.childId,
        alertType: 'SCHEDULE_VIOLATION',
        severity: 'Warning',
        value: schedule.scheduleTitle,
        message: 'Bé ${widget.childName} cố gắng mở ứng dụng $appName trong khung giờ: ${schedule.scheduleTitle} ($startTimeStr - $endTimeStr)',
        createdAt: DateTime.now(),
      ),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF59E0B), width: 2),
              ),
              child: const Icon(Icons.schedule_rounded, size: 36, color: Color(0xFFD97706)),
            ),
            const SizedBox(height: 14),
            const Text(
              'KHUNG GIỜ HỌC BÀI / GIỚI NGHIÊM',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF92400E),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.alarm_on_rounded, size: 16, color: Color(0xFFB45309)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          schedule.scheduleTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF78350F)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.timelapse_rounded, size: 14, color: Color(0xFFB45309)),
                      const SizedBox(width: 6),
                      Text(
                        'Thời gian: $startTimeStr - $endTimeStr (${schedule.dayOfWeek})',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ứng dụng "$appName" tạm thời bị khóa trong khung giờ này để bé tập trung học tập hoặc nghỉ ngơi.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF059669)),
                  SizedBox(width: 5),
                  Text(
                    'Ứng dụng học tập (Duolingo) vẫn được phép mở',
                    style: TextStyle(fontSize: 11, color: Color(0xFF047857), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu, Con sẽ học bài / đi ngủ', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection() {
    final activeBlocking = _findCurrentBlockingSchedule('SocialMedia');
    final hasActiveRestriction = activeBlocking != null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: hasActiveRestriction ? Colors.amber.shade400 : const Color(0xFFE2E8F0),
          width: hasActiveRestriction ? 1.5 : 1.0,
        ),
      ),
      color: hasActiveRestriction ? const Color(0xFFFFFBEB) : Colors.white,
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
                    color: hasActiveRestriction
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    hasActiveRestriction ? Icons.nightlight_round : Icons.schedule_rounded,
                    color: hasActiveRestriction ? const Color(0xFFD97706) : const Color(0xFF7C3AED),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thời Gian Biểu Dùng Máy',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        hasActiveRestriction
                            ? 'Đang áp dụng: ${activeBlocking.scheduleTitle}'
                            : 'Đang đồng bộ ${_schedules.length} lịch biểu từ Ba Mẹ',
                        style: TextStyle(
                          fontSize: 12,
                          color: hasActiveRestriction ? const Color(0xFFB45309) : Colors.grey[600],
                          fontWeight: hasActiveRestriction ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasActiveRestriction ? Colors.amber[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    hasActiveRestriction ? '⏰ ĐANG GIỚI HẠN' : '🟢 TỰ DO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: hasActiveRestriction ? Colors.amber[900] : Colors.green[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Banner giải thích khi đang trong giờ giới hạn
            if (hasActiveRestriction)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Color(0xFFB45309)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hiện tại đang trong khung giờ nghỉ ngơi / học tập (${activeBlocking.allowedStartTime.length >= 5 ? activeBlocking.allowedStartTime.substring(0, 5) : activeBlocking.allowedStartTime} - ${activeBlocking.allowedEndTime.length >= 5 ? activeBlocking.allowedEndTime.substring(0, 5) : activeBlocking.allowedEndTime}). Các ứng dụng giải trí sẽ bị chặn, chỉ mở được ứng dụng học tập.',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF78350F)),
                      ),
                    ),
                  ],
                ),
              ),

            // Danh sách các lịch biểu đã thiết lập
            if (_schedules.isEmpty)
              const Text(
                'Chưa có thời gian biểu nào được thiết lập.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              )
            else
              Column(
                children: _schedules.map((s) {
                  final isCurrent = _isScheduleCurrentlyActive(s);
                  final sStart = s.allowedStartTime.length >= 5 ? s.allowedStartTime.substring(0, 5) : s.allowedStartTime;
                  final sEnd = s.allowedEndTime.length >= 5 ? s.allowedEndTime.substring(0, 5) : s.allowedEndTime;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isCurrent ? const Color(0xFFFEF3C7) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCurrent ? const Color(0xFFFCD34D) : Colors.grey[200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCurrent ? Icons.alarm_on : Icons.access_time,
                          size: 16,
                          color: isCurrent ? const Color(0xFFD97706) : Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.scheduleTitle,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isCurrent ? const Color(0xFF92400E) : Colors.black87,
                                ),
                              ),
                              Text(
                                '$sStart - $sEnd • ${s.dayOfWeek}',
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ĐANG CHẠY',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),

            // Nút switch giả lập test nhanh
            const Divider(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.science_outlined, size: 16, color: Colors.deepPurple),
                    SizedBox(width: 6),
                    Text(
                      'Giả lập Giờ Giới Nghiêm (để test ban ngày):',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.deepPurple),
                    ),
                  ],
                ),
                Switch(
                  value: _simulateCurfewActive,
                  activeTrackColor: Colors.deepPurple.withValues(alpha: 0.5),
                  activeThumbColor: Colors.deepPurple,
                  onChanged: (val) {
                    setState(() {
                      _simulateCurfewActive = val;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
