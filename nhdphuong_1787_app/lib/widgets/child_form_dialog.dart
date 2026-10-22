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
  String _avatar = 'boy';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.child?.fullName ?? '');
    _ageCtrl = TextEditingController(text: widget.child?.age.toString() ?? '8');
    _deviceCtrl = TextEditingController(text: widget.child?.deviceName ?? 'Samsung Galaxy');
    _avatar = widget.child?.avatarUrl ?? 'boy';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _deviceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.child != null;

    return AlertDialog(
      title: Text(isEditing ? 'Sửa Thông Tin Bé' : 'Thêm Hồ Sơ Bé Mới'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              decoration: const InputDecoration(labelText: 'Tên của bé (VD: Bé Bo)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ageCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Tuổi của bé'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _deviceCtrl,
              decoration: const InputDecoration(labelText: 'Tên thiết bị (VD: Samsung Tab / Redmi)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Hủy')),
        FilledButton(
          onPressed: () {
            if (_nameCtrl.text.isEmpty) return;
            final updated = ChildProfile(
              id: widget.child?.id ?? 0,
              parentId: widget.child?.parentId ?? '',
              fullName: _nameCtrl.text.trim(),
              age: int.tryParse(_ageCtrl.text) ?? 8,
              avatarUrl: _avatar,
              deviceName: _deviceCtrl.text.trim(),
              deviceModel: widget.child?.deviceModel ?? 'Android Emulator',
              pairingCode: widget.child?.pairingCode ?? '',
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
          child: Text(isEditing ? 'Cập Nhật' : 'Thêm Bé'),
        ),
      ],
    );
  }
}
