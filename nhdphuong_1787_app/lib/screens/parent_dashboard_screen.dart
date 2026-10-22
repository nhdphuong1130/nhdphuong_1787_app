import 'package:flutter/material.dart';
import '../models/child_profile.dart';
import '../models/alert_log.dart';
import '../services/child_service.dart';
import '../services/token_service.dart';
import '../widgets/child_card.dart';
import '../widgets/child_form_dialog.dart';
import 'live_map_screen.dart';
import 'noise_meter_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _loadData();
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
    showDialog(
      context: context,
      builder: (_) => ChildFormDialog(
        onSave: (newChild) async {
          await ChildService.createChild(newChild);
          _loadData();
        },
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
        content: Text('Bạn có chắc chắn muốn xóa hồ sơ bé ${child.fullName} không? Toàn bộ quy tắc và lịch biểu sẽ bị xóa.'),
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Bảng Giám Sát Phụ Huynh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Xin chào, $_parentName', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentTabIndex == 0
              ? _buildChildrenTab(theme)
              : _buildAlertsTab(theme),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (idx) => setState(() => _currentTabIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.family_restroom_outlined),
            selectedIcon: Icon(Icons.family_restroom),
            label: 'Hồ Sơ Con',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_active_outlined),
            selectedIcon: Icon(Icons.notifications_active),
            label: 'Nhật Ký Cảnh Báo',
          ),
        ],
      ),
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _showAddChildDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Thêm Bé'),
            )
          : null,
    );
  }

  Widget _buildChildrenTab(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Khung Banner chuyển đổi Chế độ Máy Trẻ (Kid Mode) phục vụ Thầy chấm điểm
            Card(
              color: Colors.deepPurple[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.deepPurple[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.deepPurple,
                      child: const Icon(Icons.phone_android, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Chế Độ Máy Con (Kid Simulator)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('Mở để test cự ly mắt AI, quét QR & phản ứng khóa máy', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.deepPurple),
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
                      child: const Text('Vào Demo'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tiêu đề danh sách con & nút mở nhanh bản đồ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Danh sách thiết bị trẻ em (${_children.length})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (_children.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => LiveMapScreen(children: _children)),
                      );
                    },
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('Bản đồ GPS'),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (_children.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.child_care, size: 56, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('Chưa có hồ sơ trẻ em nào.'),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _showAddChildDialog, child: const Text('Thêm Hồ Sơ Đầu Tiên')),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _children.length,
                itemBuilder: (ctx, i) {
                  final child = _children[i];
                  return Column(
                    children: [
                      ChildCard(
                        child: child,
                        onEdit: () => _showEditChildDialog(child),
                        onDelete: () => _deleteChild(child),
                        onToggleLock: (v) async {
                          await ChildService.toggleLock(child.id);
                          _loadData();
                        },
                        onOpenMap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => LiveMapScreen(children: [child])),
                          );
                        },
                      ),
                      // Nút nhanh mở tính năng đo tiếng ồn
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => NoiseMeterScreen(childId: child.id, childName: child.fullName),
                              ),
                            );
                          },
                          icon: const Icon(Icons.mic, size: 16, color: Colors.teal),
                          label: Text('Đo tiếng ồn phòng ${child.fullName} (dB)', style: const TextStyle(fontSize: 12, color: Colors.teal)),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsTab(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _recentAlerts.isEmpty
          ? const Center(child: Text('Chưa có cảnh báo vi phạm nào.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _recentAlerts.length,
              itemBuilder: (ctx, i) {
                final alert = _recentAlerts[i];
                final isEye = alert.alertType == 'EYE_DISTANCE';
                final isNoise = alert.alertType == 'NOISE_DANGER';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isEye ? Colors.amber[100] : (isNoise ? Colors.red[100] : Colors.blue[100]),
                      child: Icon(
                        isEye ? Icons.visibility : (isNoise ? Icons.volume_up : Icons.location_on),
                        color: isEye ? Colors.brown : (isNoise ? Colors.red : Colors.blue),
                      ),
                    ),
                    title: Text(alert.message, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('Giá trị: ${alert.value} • Mức độ: ${alert.severity}'),
                    trailing: Text(
                      '${alert.createdAt.hour.toString().padLeft(2, '0')}:${alert.createdAt.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
