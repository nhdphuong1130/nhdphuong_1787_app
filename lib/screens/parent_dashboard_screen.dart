import 'dart:async';
import 'package:flutter/material.dart';
import '../models/child_profile.dart';
import '../models/alert_log.dart';
import '../services/child_service.dart';
import '../services/token_service.dart';
import '../widgets/child_card.dart';
import '../widgets/child_form_dialog.dart';
import '../utils/map_utils.dart';
import 'add_child_scan_screen.dart';
import 'live_map_screen.dart';
import 'kid_mode_simulator_screen.dart';
import 'login_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  List<ChildProfile> _children = [];
  List<AlertLog> _recentAlerts = [];
  bool _isLoading = true;
  String _parentName = 'Phụ huynh';
  int _currentTabIndex = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) => _silentRefresh());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _silentRefresh() async {
    if (!mounted) return;
    try {
      final children = await ChildService.getChildren();
      final alerts = await ChildService.getAlerts(null);
      if (mounted) {
        setState(() {
          _children = children;
          _recentAlerts = alerts;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final name = await TokenService.getUsername();
    final children = await ChildService.getChildren();
    final alerts = await ChildService.getAlerts(null);

    setState(() {
      _parentName = name ?? 'Phụ huynh';
      _children = children;
      _recentAlerts = alerts;
      _isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
    await TokenService.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showAddChildDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddChildScanScreen(
          onSaved: _loadData,
        ),
      ),
    );
  }

  void _showEditChildDialog(ChildProfile child) {
    showDialog(
      context: context,
      builder: (_) => ChildFormDialog(
        child: child,
        onSave: (updated) async {
          await ChildService.updateChild(child.id, updated);
          _loadData();
        },
      ),
    );
  }

  void _deleteChild(ChildProfile child) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa hồ sơ bé?'),
        content: Text('Bạn có chắc chắn muốn xóa hồ sơ bé ${child.fullName} không?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ChildService.deleteChild(child.id);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final onlineCount = _children.where((c) => c.isOnline).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_rounded, color: Color(0xFF3730A3), size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ChildGuard',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                Text(
                  'Phụ huynh: $_parentName',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Color(0xFF475569)),
            tooltip: 'Làm mới',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF475569)),
            tooltip: 'Đăng xuất',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentTabIndex == 0
              ? _buildChildrenTab(onlineCount)
              : _buildAlertsTab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        backgroundColor: Colors.white,
        elevation: 2,
        onDestinationSelected: (idx) => setState(() => _currentTabIndex = idx),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.family_restroom_outlined),
            selectedIcon: const Icon(Icons.family_restroom, color: Color(0xFF3730A3)),
            label: 'Hồ Sơ Con (${_children.length})',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _recentAlerts.isNotEmpty,
              label: Text('${_recentAlerts.length}'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: const Icon(Icons.notifications_active, color: Color(0xFF3730A3)),
            label: 'Cảnh Báo',
          ),
        ],
      ),
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF3730A3),
              foregroundColor: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onPressed: _showAddChildDialog,
              icon: const Icon(Icons.person_add_rounded, size: 20),
              label: const Text('Tạo Tài Khoản Bé', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildChildrenTab(int onlineCount) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. THANH TỔNG QUAN TELEMETRY NHANH
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  _buildQuickStat(
                    icon: Icons.shield_outlined,
                    label: 'Bảo vệ',
                    value: '${_children.length} máy',
                    color: const Color(0xFF4F46E5),
                  ),
                  Container(width: 1, height: 26, color: const Color(0xFFE2E8F0)),
                  _buildQuickStat(
                    icon: Icons.wifi_rounded,
                    label: 'Online',
                    value: '$onlineCount kết nối',
                    color: const Color(0xFF10B981),
                  ),
                  Container(width: 1, height: 26, color: const Color(0xFFE2E8F0)),
                  _buildQuickStat(
                    icon: Icons.warning_amber_rounded,
                    label: 'Cảnh báo',
                    value: '${_recentAlerts.length} sự kiện',
                    color: _recentAlerts.isNotEmpty ? const Color(0xFFF59E0B) : const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. KHUNG CHẾ ĐỘ MÁY CON (Gọn gàng, tinh tế)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF5FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE9D5FF)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phonelink_setup_rounded, color: Color(0xFF7C3AED), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chế độ máy con (Kid Mode)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF581C87)),
                        ),
                        Text(
                          'Mô phỏng quét QR, khóa màn hình & test cảm biến',
                          style: TextStyle(fontSize: 11, color: Color(0xFF7E22CE)),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF7C3AED),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: () {
                      if (_children.isNotEmpty) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => KidModeSimulatorScreen(
                              childId: _children.first.id,
                              childName: _children.first.fullName,
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Mở Demo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. TIÊU ĐỀ DANH SÁCH & BẢN ĐỒ
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Thiết bị trẻ em (${_children.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                  ),
                ),
                if (_children.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        onPressed: () {
                          final c = _children.first;
                          MapUtils.openGoogleMaps(c.lastKnownLat, c.lastKnownLng, label: 'Bé ${c.fullName}');
                        },
                        icon: const Icon(Icons.near_me_rounded, size: 16, color: Color(0xFF2563EB)),
                        label: const Text('Bật Google Maps', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.map_outlined, size: 18, color: Color(0xFF64748B)),
                        tooltip: 'Bản đồ trong app',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => LiveMapScreen(children: _children)),
                          );
                        },
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // 4. DANH SÁCH THIẾT BỊ
            if (_children.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.child_care_rounded, size: 48, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 10),
                    const Text('Chưa có hồ sơ trẻ em nào', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                    const SizedBox(height: 12),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF3730A3)),
                      onPressed: _showAddChildDialog,
                      child: const Text('Thêm Hồ Sơ Đầu Tiên'),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _children.length,
                itemBuilder: (ctx, i) {
                  final child = _children[i];
                  return ChildCard(
                    child: child,
                    onEdit: () => _showEditChildDialog(child),
                    onDelete: () => _deleteChild(child),
                    onToggleLock: (v) async {
                      await ChildService.toggleLock(child.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(v ? Icons.lock_rounded : Icons.lock_open_rounded, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    v
                                        ? '🔒 Đã gửi lệnh KHÓA máy ${child.fullName} từ xa!'
                                        : '🔓 Đã gửi lệnh MỞ KHÓA máy cho ${child.fullName}!',
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: v ? Colors.red[700] : const Color(0xFF059669),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                      _loadData();
                    },
                    onOpenMap: () {
                      MapUtils.openGoogleMaps(
                        child.lastKnownLat,
                        child.lastKnownLng,
                        label: 'Vị trí của Bé ${child.fullName}',
                      );
                    },
                  );
                },
              ),
            const SizedBox(height: 60), // Khoảng trống cho FAB
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              Text(
                value,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _recentAlerts.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 48, color: Color(0xFF10B981)),
                  SizedBox(height: 10),
                  Text('Hệ thống an toàn, chưa có cảnh báo vi phạm nào.', style: TextStyle(color: Color(0xFF64748B))),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _recentAlerts.length,
              itemBuilder: (ctx, i) {
                final alert = _recentAlerts[i];
                final isEye = alert.alertType == 'EYE_DISTANCE';
                final isNoise = alert.alertType == 'NOISE_DANGER';

                Color typeColor = isEye ? const Color(0xFFD97706) : (isNoise ? const Color(0xFFDC2626) : const Color(0xFF2563EB));
                Color typeBg = isEye ? const Color(0xFFFFFBEB) : (isNoise ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF));

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: typeBg, shape: BoxShape.circle),
                        child: Icon(
                          isEye ? Icons.visibility_rounded : (isNoise ? Icons.mic_rounded : Icons.location_on_rounded),
                          color: typeColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.message,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Chỉ số: ${alert.value} • Mức độ: ${alert.severity}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${alert.createdAt.hour.toString().padLeft(2, '0')}:${alert.createdAt.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
