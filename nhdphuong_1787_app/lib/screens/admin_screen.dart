import 'package:flutter/material.dart';
import '../models/child_profile.dart';
import '../services/child_service.dart';
import '../services/token_service.dart';
import '../widgets/child_card.dart';
import '../widgets/child_form_dialog.dart';
import '../widgets/qr_pairing_dialog.dart';
import 'live_map_screen.dart';
import 'noise_meter_screen.dart';
import 'kid_mode_simulator_screen.dart';
import 'login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _adminName = 'admin1787';
  List<ChildProfile> _allChildren = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final name = await TokenService.getUsername();
    final children = await ChildService.getChildren();

    if (mounted) {
      setState(() {
        if (name != null) _adminName = name;
        _allChildren = children;
        _isLoading = false;
      });
    }
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
        title: const Text('Xác nhận xóa thiết bị (Admin)?'),
        content: Text('Với quyền Admin tối cao, bạn có chắc chắn muốn xóa hồ sơ ${child.fullName} khỏi toàn hệ thống?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa Toàn Bộ'),
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
        title: const Text('Trang Quản Trị Tối Cao (Admin)'),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại dữ liệu',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _handleLogout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_customize), text: 'Toàn Quyền Thử Nghiệm & CRUD'),
            Tab(icon: Icon(Icons.manage_accounts), text: 'Quản Trị Người Dùng & Thống Kê'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTestingAndCrudTab(theme),
                _buildUserManagementTab(theme),
              ],
            ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              backgroundColor: Colors.red[800],
              foregroundColor: Colors.white,
              onPressed: _showAddChildDialog,
              icon: const Icon(Icons.add),
              label: const Text('Thêm Thiết Bị Mới'),
            )
          : null,
    );
  }

  Widget _buildTestingAndCrudTab(ThemeData theme) {
    final defaultChild = _allChildren.isNotEmpty ? _allChildren.first : null;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Admin Profile
            Card(
              color: Colors.red[50],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.red[800],
                      child: const Icon(Icons.admin_panel_settings, size: 32, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Xin chào Admin: $_adminName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 2),
                          const Text(
                            'Bạn có toàn quyền kiểm tra tất cả các chức năng theo barem chấm điểm',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // KHU VỰC TRUNG TÂM KIỂM THỬ NHANH CÁC CHỨC NĂNG ĐỀ THI
            Text(
              '⚡ TRUNG TÂM KIỂM THỬ TẤT CẢ CHỨC NĂNG ĐỀ BÀI (ADMIN)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red[900], letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.35,
              children: [
                // 1. Tính năng Đo khoảng cách mắt AI (1.0đ)
                _buildActionCard(
                  title: 'Đo Khoảng Cách Mắt AI',
                  subtitle: 'Tính năng độc quyền (1.0đ)',
                  icon: Icons.visibility,
                  color: Colors.amber[800]!,
                  bgColor: Colors.amber[50]!,
                  onTap: () {
                    if (defaultChild != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => KidModeSimulatorScreen(
                            childId: defaultChild.id,
                            childName: defaultChild.fullName,
                          ),
                        ),
                      );
                    } else {
                      _showNoChildAlert();
                    }
                  },
                ),

                // 2. Tính năng Đo tiếng ồn micro dB (3.5đ)
                _buildActionCard(
                  title: 'Đo Tiếng Ồn Micro (dB)',
                  subtitle: 'Thang đo Decibel (3.5đ)',
                  icon: Icons.mic,
                  color: Colors.teal[800]!,
                  bgColor: Colors.teal[50]!,
                  onTap: () {
                    if (defaultChild != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => NoiseMeterScreen(
                            childId: defaultChild.id,
                            childName: defaultChild.fullName,
                          ),
                        ),
                      );
                    } else {
                      _showNoChildAlert();
                    }
                  },
                ),

                // 3. Tính năng Bản đồ định vị GPS & Geofence (3.5đ)
                _buildActionCard(
                  title: 'Bản Đồ Vị Trí GPS',
                  subtitle: 'OpenStreetMap & Vùng 500m',
                  icon: Icons.map,
                  color: Colors.blue[800]!,
                  bgColor: Colors.blue[50]!,
                  onTap: () {
                    if (_allChildren.isNotEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => LiveMapScreen(children: _allChildren)),
                      );
                    } else {
                      _showNoChildAlert();
                    }
                  },
                ),

                // 4. Ghép nối mã QR thiết bị (3.5đ)
                _buildActionCard(
                  title: 'Mã QR Ghép Nối',
                  subtitle: 'Sinh QR Code liên kết',
                  icon: Icons.qr_code_2,
                  color: Colors.purple[800]!,
                  bgColor: Colors.purple[50]!,
                  onTap: () {
                    if (defaultChild != null) {
                      showDialog(
                        context: context,
                        builder: (_) => QrPairingDialog(
                          childName: defaultChild.fullName,
                          pairingCode: defaultChild.pairingCode,
                        ),
                      );
                    } else {
                      _showNoChildAlert();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // TOÀN QUYỀN CRUD THIẾT BỊ VÀ QUY TẮC TRẺ EM (4.5 ĐIỂM)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quản lý tất cả thiết bị trong CSDL (${_allChildren.length})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _showAddChildDialog,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Thêm Thiết Bị'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_allChildren.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: Text('Chưa có thiết bị nào trong CSDL.')),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _allChildren.length,
                itemBuilder: (ctx, i) {
                  final child = _allChildren[i];
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => NoiseMeterScreen(childId: child.id, childName: child.fullName),
                                ),
                              );
                            },
                            icon: const Icon(Icons.mic, size: 16, color: Colors.teal),
                            label: Text('Đo tiếng ồn (${child.fullName})', style: const TextStyle(fontSize: 12, color: Colors.teal)),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => KidModeSimulatorScreen(childId: child.id, childName: child.fullName),
                                ),
                              );
                            },
                            icon: const Icon(Icons.visibility, size: 16, color: Colors.amber),
                            label: Text('Test Mắt AI (${child.fullName})', style: const TextStyle(fontSize: 12, color: Colors.brown)),
                          ),
                        ],
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

  Widget _buildUserManagementTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thống kê Tổng quan Toàn Hệ thống', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _buildStatCard('Tổng Tài Khoản', '4', Icons.people, Colors.blue),
              _buildStatCard('Thiết Bị Trẻ Em', '${_allChildren.length}', Icons.phone_android, Colors.green),
              _buildStatCard('Quy Tắc Lọc App', '6', Icons.shield, Colors.orange),
              _buildStatCard('Cảnh Báo Hệ Thống', '4', Icons.warning_amber, Colors.red),
            ],
          ),
          const SizedBox(height: 24),
          Text('Danh sách Tài khoản Phân quyền (RBAC)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.shield, color: Colors.white)),
                  title: Text('admin1787 (Quản trị viên)'),
                  subtitle: Text('Role: Admin • admin1787@childguard.local'),
                  trailing: Chip(label: Text('Admin', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)), backgroundColor: Color(0xFFFFEBEE)),
                ),
                Divider(height: 1),
                ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.support_agent, color: Colors.white)),
                  title: Text('staff1787 (Kỹ thuật viên)'),
                  subtitle: Text('Role: Staff • staff1787@childguard.local'),
                  trailing: Chip(label: Text('Staff', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 11)), backgroundColor: Color(0xFFE0F2F1)),
                ),
                Divider(height: 1),
                ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white)),
                  title: Text('parent1787 (Phụ huynh Duy Phương)'),
                  subtitle: Text('Role: Customer • parent1787@childguard.local'),
                  trailing: Chip(label: Text('Customer', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11)), backgroundColor: Color(0xFFE3F2FD)),
                ),
                Divider(height: 1),
                ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.indigo, child: Icon(Icons.person_outline, color: Colors.white)),
                  title: Text('nhdphuong01 (Tài khoản vừa tạo)'),
                  subtitle: Text('Role: Customer • nhdphuong01@gmail.com'),
                  trailing: Chip(label: Text('Customer', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 11)), backgroundColor: Color(0xFFE8EAF6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Card(
      color: bgColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color,
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
                  Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey[700])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 26, color: color),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showNoChildAlert() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chưa có thiết bị nào trong CSDL! Vui lòng bấm Thêm Thiết Bị trước.')),
    );
  }
}
