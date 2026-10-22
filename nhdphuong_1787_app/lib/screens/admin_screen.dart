import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/child_profile.dart';
import '../models/alert_log.dart';
import '../services/child_service.dart';
import '../services/admin_service.dart';
import '../services/token_service.dart';
import '../widgets/child_card.dart';
import '../widgets/child_form_dialog.dart';
import 'add_child_scan_screen.dart';
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
  List<Map<String, dynamic>> _allUsers = [];
  Map<String, dynamic> _systemStats = {};
  List<AlertLog> _allAlerts = [];

  bool _isLoading = true;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadData();
    // Tự động làm mới dữ liệu nền mỗi 4 giây
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 4), (_) => _silentRefresh());
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final name = await TokenService.getUsername();
    final children = await ChildService.getChildren();
    final users = await AdminService.getAllUsers();
    final stats = await AdminService.getSystemStats();
    final alerts = await ChildService.getAlerts(null);

    if (mounted) {
      setState(() {
        if (name != null) _adminName = name;
        _allChildren = children;
        _allUsers = users;
        _systemStats = stats;
        _allAlerts = alerts;
        _isLoading = false;
      });
    }
  }

  Future<void> _silentRefresh() async {
    if (!mounted) return;
    try {
      final children = await ChildService.getChildren();
      final users = await AdminService.getAllUsers();
      final stats = await AdminService.getSystemStats();
      final alerts = await ChildService.getAlerts(null);
      if (mounted) {
        setState(() {
          _allChildren = children;
          _allUsers = users;
          _systemStats = stats;
          _allAlerts = alerts;
        });
      }
    } catch (_) {}
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
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getInt('paired_child_id') == child.id) {
        await ChildService.clearLocalPairing();
      }
      _loadData();
    }
  }

  void _showCreateUserDialog() {
    final userCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: 'Password123@');
    String selectedRole = 'Customer';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_add, color: Colors.red),
              SizedBox(width: 8),
              Text('Tạo Người Dùng Mới (Admin)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: userCtrl,
                  decoration: const InputDecoration(labelText: 'Tên đăng nhập *', prefixIcon: Icon(Icons.account_circle)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Họ và tên', prefixIcon: Icon(Icons.badge)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Số điện thoại', prefixIcon: Icon(Icons.phone)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passCtrl,
                  decoration: const InputDecoration(labelText: 'Mật khẩu', prefixIcon: Icon(Icons.lock)),
                ),
                const SizedBox(height: 16),
                const Text('Phân quyền tài khoản (RBAC):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Customer', label: Text('Phụ huynh', style: TextStyle(fontSize: 11))),
                    ButtonSegment(value: 'Staff', label: Text('Kỹ thuật', style: TextStyle(fontSize: 11))),
                    ButtonSegment(value: 'Admin', label: Text('Quản trị', style: TextStyle(fontSize: 11))),
                  ],
                  selected: {selectedRole},
                  onSelectionChanged: (s) => setDialogState(() => selectedRole = s.first),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red[800]),
              onPressed: () async {
                final uName = userCtrl.text.trim();
                if (uName.isEmpty) return;
                Navigator.pop(ctx);
                final ok = await AdminService.createUser(
                  userName: uName,
                  fullName: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  phoneNumber: phoneCtrl.text.trim(),
                  password: passCtrl.text.trim(),
                  role: selectedRole,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? '🎉 Đã tạo tài khoản $uName thành công!' : '❌ Không thể tạo tài khoản.'),
                      backgroundColor: ok ? Colors.green : Colors.red,
                    ),
                  );
                  _loadData();
                }
              },
              child: const Text('Tạo Tài Khoản'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteUser(Map<String, dynamic> user) async {
    final userName = user['userName'] ?? '';
    if (userName.toString().toLowerCase() == 'admin1787') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Không thể xóa tài khoản Quản trị viên tối cao (admin1787)!'), backgroundColor: Colors.orange),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa người dùng?'),
        content: Text('Bạn có chắc chắn muốn xóa tài khoản "$userName" và TOÀN BỘ thiết bị con của họ khỏi hệ thống không? Thao tác này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa Toàn Bộ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await AdminService.deleteUser(user['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? '🗑️ Đã xóa người dùng $userName thành công!' : '❌ Lỗi khi xóa người dùng.'),
            backgroundColor: ok ? Colors.green : Colors.red,
          ),
        );
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Text(
              'Quản Trị Admin',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFB91C1C),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Tải lại dữ liệu',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Đăng xuất',
            onPressed: _handleLogout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(icon: const Icon(Icons.devices_rounded, size: 20), text: 'Thiết Bị (${_allChildren.length})'),
            Tab(icon: const Icon(Icons.manage_accounts_rounded, size: 20), text: 'Users (${_allUsers.length})'),
            Tab(icon: const Icon(Icons.warning_amber_rounded, size: 20), text: 'Cảnh Báo (${_allAlerts.length})'),
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
                _buildAlertsTab(theme),
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
          : (_tabController.index == 1
              ? FloatingActionButton.extended(
                  backgroundColor: Colors.red[800],
                  foregroundColor: Colors.white,
                  onPressed: _showCreateUserDialog,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Tạo Người Dùng'),
                )
              : null),
    );
  }

  /// TAB 1: TOÀN QUYỀN ĐIỀU KHIỂN & CRUD MỌI THIẾT BỊ TRẺ EM TRONG CSDL
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF991B1B), Color(0xFFDC2626)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_rounded, size: 24, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Admin: $_adminName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        const Text('Quản trị viên toàn hệ thống', style: TextStyle(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // KIỂM THỬ NHANH CÁC CHỨC NĂNG
            const Text(
              '⚡ KIỂM THỬ TÍNH NĂNG',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.8,
              children: [
                _buildActionCard(
                  title: 'Khoảng Cách Mắt AI',
                  icon: Icons.visibility_rounded,
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
                _buildActionCard(
                  title: 'Đo Tiếng Ồn (dB)',
                  icon: Icons.mic_rounded,
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
                _buildActionCard(
                  title: 'Bản Đồ GPS',
                  icon: Icons.near_me_rounded,
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
                _buildActionCard(
                  title: 'Chế Độ Máy Con',
                  icon: Icons.smartphone_rounded,
                  color: Colors.deepPurple[800]!,
                  bgColor: Colors.deepPurple[50]!,
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
              ],
            ),
            const SizedBox(height: 20),

            // CRUD THIẾT BỊ
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Thiết bị hệ thống (${_allChildren.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _showAddChildDialog,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Thêm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_allChildren.isEmpty)
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Center(child: Text('Chưa có thiết bị nào trong CSDL.')),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _allChildren.length,
                itemBuilder: (ctx, i) {
                  final child = _allChildren[i];
                  return ChildCard(
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
                  );
                },
              ),
            const SizedBox(height: 60), // Khoảng trống cho FAB
          ],
        ),
      ),
    );
  }

  /// TAB 2: QUẢN TRỊ NGƯỜI DÙNG & THỐNG KÊ TOÀN DIỆN (RBAC)
  Widget _buildUserManagementTab(ThemeData theme) {
    final totalUsers = _systemStats['totalUsers']?.toString() ?? '${_allUsers.length}';
    final totalChildren = _systemStats['totalChildren']?.toString() ?? '${_allChildren.length}';
    final totalRules = _systemStats['totalRules']?.toString() ?? '6';
    final totalAlerts = _systemStats['totalAlerts']?.toString() ?? '${_allAlerts.length}';
    final onlineDevices = _systemStats['onlineChildren']?.toString() ?? '0';

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Thống kê hệ thống', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                ),
                IconButton(icon: const Icon(Icons.sync, size: 20), onPressed: _loadData, tooltip: 'Đồng bộ'),
              ],
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.4,
              children: [
                _buildStatCard('Tổng Người Dùng', totalUsers, Icons.people, Colors.blue),
                _buildStatCard('Thiết Bị Trẻ Em', totalChildren, Icons.phone_android, Colors.green),
                _buildStatCard('Đang Hoạt Động', onlineDevices, Icons.wifi, Colors.teal),
                _buildStatCard('Quy Tắc Lọc App', totalRules, Icons.shield, Colors.orange),
                _buildStatCard('Nhật Ký Cảnh Báo', totalAlerts, Icons.warning_amber, Colors.red),
                _buildStatCard('Đang Bị Khóa', '${_systemStats['lockedChildren'] ?? 0}', Icons.lock, Colors.deepOrange),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Người dùng (${_allUsers.length})',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _showCreateUserDialog,
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('Thêm User', style: TextStyle(fontSize: 12)),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_allUsers.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: Text('Chưa có người dùng nào.')),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _allUsers.length,
                itemBuilder: (ctx, idx) {
                  final u = _allUsers[idx];
                  final role = (u['role'] ?? 'Customer').toString();
                  final isAdmin = role.toLowerCase() == 'admin';
                  final isStaff = role.toLowerCase() == 'staff';
                  final childrenCount = u['childrenCount'] ?? 0;
                  final List children = u['children'] as List? ?? [];

                  Color roleColor = Colors.blue;
                  if (isAdmin) roleColor = Colors.red;
                  if (isStaff) roleColor = Colors.teal;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: roleColor.withValues(alpha: 0.15),
                        child: Icon(
                          isAdmin ? Icons.shield : (isStaff ? Icons.support_agent : Icons.person),
                          color: roleColor,
                        ),
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              u['userName'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              role,
                              style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        '${u['fullName'] ?? ''} • ${u['email'] ?? ''}\nSĐT: ${u['phoneNumber'] ?? 'Chưa cập nhật'} • $childrenCount thiết bị liên kết',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (ctx) => [
                          if (!isAdmin)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red, size: 18),
                                  SizedBox(width: 8),
                                  Text('Xóa tài khoản', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                        ],
                        onSelected: (val) {
                          if (val == 'delete') _deleteUser(u);
                        },
                      ),
                      children: [
                        if (children.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Người dùng này chưa ghép nối thiết bị con nào.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Thiết bị con thuộc tài khoản này:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(height: 6),
                                ...children.map((c) => ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.phone_android, size: 20, color: Colors.deepPurple),
                                  title: Text(c['fullName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${c['deviceName']} • Pin: ${c['batteryLevel']}% • Tiếng ồn: ${c['currentNoiseDb'] ?? 45}dB • Mắt: ${c['currentEyeDistanceCm'] ?? 35}cm'),
                                  trailing: Icon(Icons.circle, size: 10, color: c['isOnline'] == true ? Colors.green : Colors.grey),
                                )),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  /// TAB 3: TOÀN BỘ NHẬT KÝ CẢNH BÁO TOÀN HỆ THỐNG
  Widget _buildAlertsTab(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _allAlerts.isEmpty
          ? const Center(child: Text('Chưa có cảnh báo nào trong toàn bộ hệ thống.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _allAlerts.length,
              itemBuilder: (ctx, i) {
                final alert = _allAlerts[i];
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
                            const SizedBox(height: 3),
                            Text(
                              'Chỉ số: ${alert.value} • Mức độ: ${alert.severity}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${alert.createdAt.hour.toString().padLeft(2, '0')}:${alert.createdAt.minute.toString().padLeft(2, '0')}\n${alert.createdAt.day}/${alert.createdAt.month}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNoChildAlert() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chưa có thiết bị nào trong CSDL! Vui lòng bấm Thêm Thiết Bị trước.')),
    );
  }
}
