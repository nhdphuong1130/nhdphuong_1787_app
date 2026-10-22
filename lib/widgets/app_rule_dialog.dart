import 'package:flutter/material.dart';
import '../models/app_rule.dart';
import '../services/child_service.dart';

class AppRuleDialog extends StatefulWidget {
  final int childId;
  final String childName;

  const AppRuleDialog({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<AppRuleDialog> createState() => _AppRuleDialogState();
}

class _AppRuleDialogState extends State<AppRuleDialog> {
  List<AppRule> _rules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    setState(() => _isLoading = true);
    final rules = await ChildService.getRules(widget.childId);
    setState(() {
      _rules = rules;
      _isLoading = false;
    });
  }

  Future<void> _showAddRuleDialog() async {
    final appNameCtrl = TextEditingController();
    String category = 'SocialMedia';
    String status = 'Blocked';
    int minutes = 45;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Thêm Quy Tắc Chặn / Giới Hạn App'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: appNameCtrl,
                  decoration: const InputDecoration(labelText: 'Tên ứng dụng (VD: TikTok, Roblox...)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Thể loại'),
                  items: const [
                    DropdownMenuItem(value: 'SocialMedia', child: Text('Mạng xã hội')),
                    DropdownMenuItem(value: 'Game', child: Text('Game trực tuyến')),
                    DropdownMenuItem(value: 'Entertainment', child: Text('Giải trí / Phim')),
                    DropdownMenuItem(value: 'Education', child: Text('Học tập')),
                  ],
                  onChanged: (val) => setDlgState(() => category = val!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Mức độ giới hạn'),
                  items: const [
                    DropdownMenuItem(value: 'Blocked', child: Text('🚫 Chặn hoàn toàn')),
                    DropdownMenuItem(value: 'Limited', child: Text('⏳ Giới hạn số phút/ngày')),
                    DropdownMenuItem(value: 'Allowed', child: Text('✅ Cho phép sử dụng')),
                  ],
                  onChanged: (val) => setDlgState(() => status = val!),
                ),
                if (status == 'Limited') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Giới hạn: '),
                      Expanded(
                        child: Slider(
                          value: minutes.toDouble(),
                          min: 15,
                          max: 180,
                          divisions: 11,
                          label: '$minutes phút',
                          onChanged: (v) => setDlgState(() => minutes = v.round()),
                        ),
                      ),
                      Text('$minutes ph'),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')),
            FilledButton(
              onPressed: () async {
                if (appNameCtrl.text.isEmpty) return;
                Navigator.of(ctx).pop();
                final newRule = AppRule(
                  id: 0,
                  childProfileId: widget.childId,
                  appName: appNameCtrl.text.trim(),
                  category: category,
                  status: status,
                  dailyLimitMinutes: status == 'Blocked' ? 0 : minutes,
                );
                await ChildService.createRule(newRule);
                _loadRules();
              },
              child: const Text('Lưu Quy Tắc'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Quy Tắc Ứng Dụng: ${widget.childName}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Thêm app',
              onPressed: _showAddRuleDialog,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _rules.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shield_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('Chưa có quy tắc nào.'),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _showAddRuleDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm Quy Tắc Đầu Tiên'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rules.length,
                    itemBuilder: (ctx, i) {
                      final rule = _rules[i];
                      final isBlocked = rule.status == 'Blocked';
                      final isLimited = rule.status == 'Limited';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isBlocked
                                    ? Colors.red[100]
                                    : (isLimited ? Colors.amber[100] : Colors.green[100]),
                                child: Icon(
                                  isBlocked
                                      ? Icons.block
                                      : (isLimited ? Icons.timer : Icons.check),
                                  color: isBlocked
                                      ? Colors.red
                                      : (isLimited ? Colors.amber[800] : Colors.green),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      rule.appName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${rule.category} • ${isBlocked ? "Đã chặn" : (isLimited ? "Tối đa ${rule.dailyLimitMinutes} phút/ngày" : "Không giới hạn")}',
                                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: rule.isActive,
                                onChanged: (v) async {
                                  await ChildService.toggleRule(rule.id);
                                  _loadRules();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                onPressed: () async {
                                  await ChildService.deleteRule(rule.id);
                                  _loadRules();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
