import 'package:flutter/material.dart';
import '../models/screen_time_schedule.dart';
import '../services/child_service.dart';

class ScreenTimeDialog extends StatefulWidget {
  final int childId;
  final String childName;

  const ScreenTimeDialog({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<ScreenTimeDialog> createState() => _ScreenTimeDialogState();
}

class _ScreenTimeDialogState extends State<ScreenTimeDialog> {
  List<ScreenTimeSchedule> _schedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    final list = await ChildService.getSchedules(widget.childId);
    setState(() {
      _schedules = list;
      _isLoading = false;
    });
  }

  TimeOfDay _parseTime(String timeStr, {TimeOfDay fallback = const TimeOfDay(hour: 7, minute: 0)}) {
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]) ?? fallback.hour;
      final m = int.tryParse(parts[1]) ?? fallback.minute;
      return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
    }
    return fallback;
  }

  Future<void> _showScheduleFormDialog({ScreenTimeSchedule? existing}) async {
    final isEditing = existing != null;
    final titleCtrl = TextEditingController(
      text: existing?.scheduleTitle ?? 'Khung giờ được phép dùng máy',
    );
    String dayOfWeek = existing?.dayOfWeek ?? 'Tất cả các ngày';
    if (!const ['Thứ 2 - Thứ 6', 'Thứ 7 - Chủ Nhật', 'Tất cả các ngày'].contains(dayOfWeek)) {
      dayOfWeek = 'Tất cả các ngày';
    }
    TimeOfDay startTime = existing != null
        ? _parseTime(existing.allowedStartTime, fallback: const TimeOfDay(hour: 7, minute: 0))
        : const TimeOfDay(hour: 7, minute: 0);
    TimeOfDay endTime = existing != null
        ? _parseTime(existing.allowedEndTime, fallback: const TimeOfDay(hour: 21, minute: 0))
        : const TimeOfDay(hour: 21, minute: 0);
    int maxDailyHours = existing?.maxDailyHours ?? 2;
    if (!const [1, 2, 3, 4, 6, 8, 12].contains(maxDailyHours)) {
      maxDailyHours = 2;
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text(isEditing ? 'Chỉnh Sửa Lịch Biểu Dùng Máy' : 'Thêm Lịch Biểu Giờ Dùng Máy'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tên lịch biểu',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: dayOfWeek,
                  decoration: const InputDecoration(
                    labelText: 'Các ngày áp dụng',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Tất cả các ngày', child: Text('Mỗi ngày trong tuần')),
                    DropdownMenuItem(value: 'Thứ 2 - Thứ 6', child: Text('Thứ 2 - Thứ 6 (Ngày học)')),
                    DropdownMenuItem(value: 'Thứ 7 - Chủ Nhật', child: Text('Thứ 7 - Chủ Nhật (Cuối tuần)')),
                  ],
                  onChanged: (val) => setDlgState(() => dayOfWeek = val!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: maxDailyHours,
                  decoration: const InputDecoration(
                    labelText: 'Giới hạn tổng thời lượng / ngày',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Tối đa 1 giờ / ngày (60 phút)')),
                    DropdownMenuItem(value: 2, child: Text('Tối đa 2 giờ / ngày (120 phút)')),
                    DropdownMenuItem(value: 3, child: Text('Tối đa 3 giờ / ngày (180 phút)')),
                    DropdownMenuItem(value: 4, child: Text('Tối đa 4 giờ / ngày (240 phút)')),
                    DropdownMenuItem(value: 6, child: Text('Tối đa 6 giờ / ngày (360 phút)')),
                    DropdownMenuItem(value: 8, child: Text('Tối đa 8 giờ / ngày (480 phút)')),
                    DropdownMenuItem(value: 12, child: Text('Tối đa 12 giờ / ngày (720 phút)')),
                  ],
                  onChanged: (val) => setDlgState(() => maxDailyHours = val!),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.play_circle_outline, size: 18),
                        onPressed: () async {
                          final t = await showTimePicker(context: ctx, initialTime: startTime);
                          if (t != null) setDlgState(() => startTime = t);
                        },
                        label: Text(
                          'Từ: ${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.stop_circle_outlined, size: 18),
                        onPressed: () async {
                          final t = await showTimePicker(context: ctx, initialTime: endTime);
                          if (t != null) setDlgState(() => endTime = t);
                        },
                        label: Text(
                          'Đến: ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.of(ctx).pop();
                final sched = ScreenTimeSchedule(
                  id: existing?.id ?? 0,
                  childProfileId: widget.childId,
                  scheduleTitle: titleCtrl.text.trim(),
                  dayOfWeek: dayOfWeek,
                  allowedStartTime: '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00',
                  allowedEndTime: '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00',
                  maxDailyHours: maxDailyHours,
                  isActive: existing?.isActive ?? true,
                );
                if (isEditing) {
                  await ChildService.updateSchedule(sched);
                } else {
                  await ChildService.createSchedule(sched);
                }
                _loadSchedules();
              },
              child: Text(isEditing ? 'Cập Nhật' : 'Lưu Lịch'),
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
          title: Text('Lịch Biểu Dùng Máy: ${widget.childName}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Thêm lịch',
              onPressed: () => _showScheduleFormDialog(),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _schedules.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.schedule, size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('Chưa có lịch biểu nào.'),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => _showScheduleFormDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Tạo Lịch Biểu Mới'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _schedules.length,
                    itemBuilder: (ctx, i) {
                      final item = _schedules[i];
                      final startFmt = item.allowedStartTime.length >= 5
                          ? item.allowedStartTime.substring(0, 5)
                          : item.allowedStartTime;
                      final endFmt = item.allowedEndTime.length >= 5
                          ? item.allowedEndTime.substring(0, 5)
                          : item.allowedEndTime;

                      return Card(
                        elevation: 1.5,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          onTap: () => _showScheduleFormDialog(existing: item),
                          leading: CircleAvatar(
                            backgroundColor: item.isActive ? const Color(0xFF4F46E5) : Colors.grey[400],
                            child: const Icon(Icons.access_time_filled, color: Colors.white),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.scheduleTitle,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: item.isActive ? const Color(0xFF0F172A) : Colors.grey[600],
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: item.isActive ? Colors.green[50] : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item.isActive ? 'Đang bật' : 'Tắt',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: item.isActive ? Colors.green[800] : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '${item.dayOfWeek}\n⏰ Khung giờ cho phép: $startFmt - $endFmt (Tối đa ${item.maxDailyHours}h / ${item.maxDailyHours * 60}p)',
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Color(0xFF4F46E5), size: 20),
                                tooltip: 'Chỉnh sửa lịch',
                                onPressed: () => _showScheduleFormDialog(existing: item),
                              ),
                              Transform.scale(
                                scale: 0.8,
                                child: Switch(
                                  value: item.isActive,
                                  activeThumbColor: const Color(0xFF4F46E5),
                                  onChanged: (val) async {
                                    await ChildService.toggleSchedule(item.id);
                                    _loadSchedules();
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                tooltip: 'Xóa lịch',
                                onPressed: () async {
                                  await ChildService.deleteSchedule(item.id);
                                  _loadSchedules();
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
