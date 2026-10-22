import 'package:flutter/material.dart';
import '../services/token_service.dart';
import 'login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String _adminName = 'admin1787';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final name = await TokenService.getUsername();
    if (name != null) setState(() => _adminName = name);
  }

  Future<void> _handleLogout() async {
    await TokenService.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang Quản Trị Hệ Thống (Admin)'),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.red[50],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.red[800],
                      child: const Icon(Icons.admin_panel_settings, size: 36, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Xin chào, $_adminName', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Chip(
                            label: Text('Quyền: System Administrator (Admin)'),
                            backgroundColor: Colors.red,
                            labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Thống kê Hệ thống Giám sát', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _buildStatCard('Tổng Tài Khoản', '3', Icons.people, Colors.blue),
                _buildStatCard('Thiết Bị Trẻ Em', '2', Icons.phone_android, Colors.green),
                _buildStatCard('Quy Tắc Lọc App', '6', Icons.shield, Colors.orange),
                _buildStatCard('Cảnh Báo Hôm Nay', '2', Icons.warning_amber, Colors.red),
              ],
            ),
            const SizedBox(height: 24),
            Text('Danh sách Tài khoản Hệ thống (RBAC)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  ListTile(
                    leading: CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.shield, color: Colors.white)),
                    title: Text('admin1787 (Quản trị viên)'),
                    subtitle: Text('Role: Admin • admin1787@childguard.local'),
                    trailing: Text('Full Control', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.support_agent, color: Colors.white)),
                    title: Text('staff1787 (Nhân viên Kỹ thuật)'),
                    subtitle: Text('Role: Staff • staff1787@childguard.local'),
                    trailing: Text('Catalog Staff', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white)),
                    title: Text('parent1787 (Phụ huynh Duy Phương)'),
                    subtitle: Text('Role: Customer • parent1787@childguard.local'),
                    trailing: Text('Customer', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
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
            Icon(icon, size: 28, color: color),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
