import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/config_url.dart';
import '../services/api_client.dart';
import '../services/token_service.dart';
import 'login_screen.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  String _staffName = 'staff1787';
  List<dynamic> _catalogItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchCatalog();
  }

  Future<void> _loadUser() async {
    final name = await TokenService.getUsername();
    if (name != null) setState(() => _staffName = name);
  }

  Future<void> _fetchCatalog() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.get(ConfigUrl.staffCatalog);
      if (res.statusCode == 200) {
        setState(() {
          _catalogItems = jsonDecode(res.body);
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
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

  Future<void> _showAddCatalogDialog() async {
    final appNameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'Game';
    String riskLevel = 'High';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Thêm Ứng Dụng Mẫu Vào Thư Viện'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: appNameCtrl,
                  decoration: const InputDecoration(labelText: 'Tên ứng dụng / Web'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Thể loại'),
                  items: const [
                    DropdownMenuItem(value: 'Game', child: Text('Game Online')),
                    DropdownMenuItem(value: 'SocialMedia', child: Text('Mạng xã hội')),
                    DropdownMenuItem(value: 'Gambling', child: Text('Cờ bạc / Độc hại')),
                    DropdownMenuItem(value: 'Education', child: Text('Học tập an toàn')),
                  ],
                  onChanged: (val) => setDlgState(() => category = val!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: riskLevel,
                  decoration: const InputDecoration(labelText: 'Mức độ cảnh báo rủi ro'),
                  items: const [
                    DropdownMenuItem(value: 'High', child: Text('Rất cao (Nguy hiểm)')),
                    DropdownMenuItem(value: 'Medium', child: Text('Trung bình')),
                    DropdownMenuItem(value: 'Low', child: Text('Thấp (An toàn)')),
                  ],
                  onChanged: (val) => setDlgState(() => riskLevel = val!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Mô tả khuyến cáo phụ huynh'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')),
            FilledButton(
              onPressed: () async {
                if (appNameCtrl.text.isEmpty) return;
                Navigator.of(ctx).pop();
                await ApiClient.post(
                  ConfigUrl.staffCatalog,
                  body: {
                    'appName': appNameCtrl.text.trim(),
                    'category': category,
                    'riskLevel': riskLevel,
                    'description': descCtrl.text.trim(),
                  },
                );
                _fetchCatalog();
              },
              child: const Text('Thêm Vào Danh Mục'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bàn Làm Việc Kỹ Thuật Viên (Staff)'),
        backgroundColor: Colors.teal[700],
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
              color: Colors.teal[50],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.teal[700],
                      child: const Icon(Icons.support_agent, size: 36, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Xin chào, $_staffName', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Chip(
                            label: Text('Quyền: Nhân Viên Kiểm Duyệt (Staff)'),
                            backgroundColor: Colors.teal,
                            labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Thư viện Quy tắc An toàn Mẫu cho Phụ huynh', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                FilledButton.icon(
                  onPressed: _showAddCatalogDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm Ứng Dụng'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.teal[700]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_catalogItems.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('Chưa có ứng dụng nào trong thư viện.')))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _catalogItems.length,
                itemBuilder: (ctx, i) {
                  final item = _catalogItems[i];
                  final risk = item['riskLevel'] ?? 'Medium';
                  final isHigh = risk == 'High';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isHigh ? Colors.red[100] : Colors.green[100],
                        child: Icon(
                          isHigh ? Icons.warning : Icons.check_circle,
                          color: isHigh ? Colors.red : Colors.green,
                        ),
                      ),
                      title: Text(item['appName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${item['category']} • ${item['description']}'),
                      trailing: Chip(
                        label: Text('Rủi ro: $risk', style: TextStyle(color: isHigh ? Colors.red : Colors.green, fontSize: 11)),
                        backgroundColor: isHigh ? Colors.red[50] : Colors.green[50],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
