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

    // Màu sắc trạng thái Pin
    Color batteryColor = Colors.green[700]!;
    if (child.batteryLevel < 20) {
      batteryColor = Colors.red[700]!;
    } else if (child.batteryLevel < 50) {
      batteryColor = Colors.amber[800]!;
    }

    // Trạng thái tiếng ồn
    final isNoiseDanger = child.currentNoiseDb > 80;
    final isNoiseWarning = child.currentNoiseDb > 65;

    // Trạng thái cự ly mắt AI
    final isEyeDanger = child.currentEyeDistanceCm < 25;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. HÀNG THÔNG TIN CƠ BẢN
            Row(
              children: [
                // Avatar bé có chấm trạng thái Online
                Stack(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isGirl ? const Color(0xFFFDF2F8) : const Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isGirl ? const Color(0xFFFBCFE8) : const Color(0xFFBFDBFE),
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isGirl ? '👧' : '👦',
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: child.isOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Tên & Thiết bị
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              child.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${child.age}t',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.smartphone_rounded, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              child.deviceName,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Badge Pin
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: batteryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.battery_charging_full_rounded, size: 12, color: batteryColor),
                                const SizedBox(width: 2),
                                Text(
                                  '${child.batteryLevel}%',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: batteryColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Menu tùy chọn
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'qr',
                      child: Row(
                        children: [
                          Icon(Icons.qr_code_rounded, size: 18, color: Color(0xFF4F46E5)),
                          SizedBox(width: 10),
                          Text('Xem mã QR'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0F172A)),
                          SizedBox(width: 10),
                          Text('Sửa thông tin'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Xóa bé', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (val) {
                    if (val == 'qr') {
                      showDialog(
                        context: context,
                        builder: (_) => QrPairingDialog(
                          childName: child.fullName,
                          pairingCode: child.pairingCode,
                          childUsername: child.childUsername,
                          childPassword: child.childPassword,
                        ),
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
            const SizedBox(height: 14),

            // 2. STITCH 3-METRIC TILES (Âm thanh - Mắt AI - Vị trí GPS)
            Row(
              children: [
                // Ô 1: Tiếng ồn
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.mic_rounded,
                    label: 'Tiếng ồn',
                    value: '${child.currentNoiseDb.round()} dB',
                    statusText: isNoiseDanger ? 'Quá ồn' : (isNoiseWarning ? 'Ồn' : 'Êm dịu'),
                    statusColor: isNoiseDanger ? Colors.red : (isNoiseWarning ? Colors.amber[800]! : const Color(0xFF059669)),
                    statusBg: isNoiseDanger ? const Color(0xFFFEF2F2) : (isNoiseWarning ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5)),
                  ),
                ),
                const SizedBox(width: 8),

                // Ô 2: Cự ly mắt AI
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.visibility_rounded,
                    label: 'Cự ly mắt',
                    value: '${child.currentEyeDistanceCm.round()} cm',
                    statusText: isEyeDanger ? 'Quá gần' : 'An toàn',
                    statusColor: isEyeDanger ? Colors.red : const Color(0xFF059669),
                    statusBg: isEyeDanger ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                  ),
                ),
                const SizedBox(width: 8),

                // Ô 3: Bản đồ GPS
                Expanded(
                  child: InkWell(
                    onTap: onOpenMap,
                    borderRadius: BorderRadius.circular(14),
                    child: _buildMetricTile(
                      icon: Icons.near_me_rounded,
                      label: 'Vị trí GPS',
                      value: 'Bản đồ',
                      statusText: child.isOnline ? 'Trực tiếp' : 'Trước đó',
                      statusColor: const Color(0xFF2563EB),
                      statusBg: const Color(0xFFEFF6FF),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 3. THANH ĐIỀU KHIỂN KHÓA & NÚT THAO TÁC NHANH
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isLocked ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isLocked ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isLocked ? Colors.red.withValues(alpha: 0.15) : const Color(0xFF10B981).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                          size: 16,
                          color: isLocked ? Colors.red : const Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isLocked ? 'Đang khóa máy' : 'Máy đang mở',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isLocked ? Colors.red[800] : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: isLocked,
                      activeThumbColor: Colors.red,
                      onChanged: (v) => onToggleLock(v),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 4. CÁC NÚT TÁC VỤ (Pill-shaped)
            Row(
              children: [
                Expanded(
                  child: _buildActionPill(
                    icon: Icons.shield_outlined,
                    label: 'Quy tắc App',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AppRuleDialog(childId: child.id, childName: child.fullName),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionPill(
                    icon: Icons.schedule_rounded,
                    label: 'Lịch biểu',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => ScreenTimeDialog(childId: child.id, childName: child.fullName),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.qr_code_rounded, size: 18, color: Color(0xFF4F46E5)),
                  tooltip: 'Mã QR ghép nối',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => QrPairingDialog(
                        childName: child.fullName,
                        pairingCode: child.pairingCode,
                        childUsername: child.childUsername,
                        childPassword: child.childPassword,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required String statusText,
    required Color statusColor,
    required Color statusBg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF64748B)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusText,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF334155)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            ),
          ],
        ),
      ),
    );
  }
}
