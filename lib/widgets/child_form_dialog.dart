import 'package:flutter/material.dart';
import '../models/child_profile.dart';

class ChildFormDialog extends StatefulWidget {
  final ChildProfile? child;
  final Function(ChildProfile) onSave;

  const ChildFormDialog({super.key, this.child, required this.onSave});

  @override
  State<ChildFormDialog> createState() => _ChildFormDialogState();
}

class _ChildFormDialogState extends State<ChildFormDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _deviceCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _passwordCtrl;
  String _avatar = 'boy';
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.child?.fullName ?? '');
    _ageCtrl = TextEditingController(text: widget.child?.age.toString() ?? '8');
    _deviceCtrl = TextEditingController(text: widget.child?.deviceName ?? 'Samsung Galaxy');
    _usernameCtrl = TextEditingController(text: widget.child?.childUsername ?? '');
    _passwordCtrl = TextEditingController(text: widget.child?.childPassword ?? 'Password123@');
    _avatar = widget.child?.avatarUrl ?? 'boy';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _deviceCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.child != null;

    return AlertDialog(
      title: Row(
        children: [
          Icon(isEditing ? Icons.manage_accounts_rounded : Icons.person_add_rounded, color: Colors.indigo),
          const SizedBox(width: 8),
          Text(isEditing ? 'Sửa Tài Khoản Bé' : 'Tạo Tài Khoản Bé Mới'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('👦 Bé Trai'),
                  selected: _avatar == 'boy',
                  onSelected: (s) => setState(() => _avatar = 'boy'),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('👧 Bé Gái'),
                  selected: _avatar == 'girl',
                  onSelected: (s) => setState(() => _avatar = 'girl'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Tên của bé (VD: Bé Bo, Bé Na...)',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                if (!isEditing && (_usernameCtrl.text.isEmpty || _usernameCtrl.text.startsWith('be'))) {
                  final normalized = val.toLowerCase().replaceAll(' ', '');
                  _usernameCtrl.text = normalized.isNotEmpty ? '${normalized}1787' : '';
                }
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _ageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tuổi của bé',
                      prefixIcon: Icon(Icons.cake),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _deviceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên thiết bị con',
                      prefixIcon: Icon(Icons.phone_android),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Khung tài khoản đăng nhập cấp cho bé
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.vpn_key_rounded, size: 16, color: Colors.indigo),
                      SizedBox(width: 6),
                      Text(
                        'Tài khoản cấp cho bé (Đăng nhập máy con):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _usernameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên đăng nhập của bé',
                      hintText: 'bebo1787',
                      prefixIcon: Icon(Icons.account_circle, size: 20),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu cấp cho bé',
                      prefixIcon: const Icon(Icons.lock, size: 20),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Hủy')),
        FilledButton(
          onPressed: () {
            if (_nameCtrl.text.trim().isEmpty) return;
            final updated = ChildProfile(
              id: widget.child?.id ?? 0,
              parentId: widget.child?.parentId ?? '',
              fullName: _nameCtrl.text.trim(),
              age: int.tryParse(_ageCtrl.text) ?? 8,
              avatarUrl: _avatar,
              deviceName: _deviceCtrl.text.trim(),
              deviceModel: widget.child?.deviceModel ?? 'Android Device',
              pairingCode: widget.child?.pairingCode ?? '',
              childUsername: _usernameCtrl.text.trim().isNotEmpty ? _usernameCtrl.text.trim() : 'be${DateTime.now().millisecondsSinceEpoch % 10000}',
              childPassword: _passwordCtrl.text.trim().isNotEmpty ? _passwordCtrl.text.trim() : 'Password123@',
              batteryLevel: widget.child?.batteryLevel ?? 85,
              isOnline: widget.child?.isOnline ?? true,
              isLocked: widget.child?.isLocked ?? false,
              lastKnownLat: widget.child?.lastKnownLat ?? 10.762622,
              lastKnownLng: widget.child?.lastKnownLng ?? 106.660172,
              updatedAt: DateTime.now(),
            );
            widget.onSave(updated);
            Navigator.of(context).pop();
          },
          child: Text(isEditing ? 'Cập Nhật' : 'Tạo Tài Khoản'),
        ),
      ],
    );
  }
}
