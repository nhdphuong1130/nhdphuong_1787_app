import 'package:flutter/material.dart';
import '../models/child_profile.dart';
import 'qr_pairing_dialog.dart';
import 'app_rule_dialog.dart';
import 'screen_time_dialog.dart';

class ChildCard extends StatelessWidget {
  final ChildProfile child;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(bool) onToggleLock;
  final VoidCallback onOpenMap;

  const ChildCard({
    super.key,
    required this.child,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleLock,
    required this.onOpenMap,
  });

  @override
  Widget build(BuildContext context) {
    final isGirl = child.avatarUrl == 'girl';
    final isLocked = child.isLocked;

    Color batteryColor = Colors.green;
    if (child.batteryLevel < 20) {
      batteryColor = Colors.red;
    } else if (child.batteryLevel < 50) {
      batteryColor = Colors.orange;
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: isGirl ? Colors.pink[100] : Colors.blue[100],
                      child: Text(
                        isGirl ? '👧' : '👦',
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: child.isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            child.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('${child.age} tuổi', style: const TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone_android, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              child.deviceName,
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.battery_std, size: 16, color: batteryColor),
                          Text(
                            '${child.batteryLevel}%',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: batteryColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'qr', child: Text('Xem mã QR ghép nối')),
                    const PopupMenuItem(value: 'edit', child: Text('Sửa thông tin')),
                    const PopupMenuItem(value: 'delete', child: Text('Xóa bé', style: TextStyle(color: Colors.red))),
                  ],
                  onSelected: (val) {
                    if (val == 'qr') {
                      showDialog(
                        context: context,
                        builder: (_) => QrPairingDialog(childName: child.fullName, pairingCode: child.pairingCode),
                      );
                    } else if (val == 'edit') {
                      onEdit();
                    } else if (val == 'delete') {
                      onDelete();
                    }
                  },
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isLocked ? Icons.lock : Icons.lock_open,
                      color: isLocked ? Colors.red : Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isLocked ? 'Đang khóa máy từ xa' : 'Máy đang hoạt động',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isLocked ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: isLocked,
                  activeTrackColor: Colors.redAccent,
                  onChanged: (v) => onToggleLock(v),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AppRuleDialog(childId: child.id, childName: child.fullName),
                      );
                    },
                    icon: const Icon(Icons.shield_outlined, size: 16),
                    label: const Text('Quy tắc App', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => ScreenTimeDialog(childId: child.id, childName: child.fullName),
                      );
                    },
                    icon: const Icon(Icons.access_time, size: 16),
                    label: const Text('Lịch biểu', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.location_on, size: 18),
                  tooltip: 'Xem vị trí GPS',
                  onPressed: onOpenMap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
