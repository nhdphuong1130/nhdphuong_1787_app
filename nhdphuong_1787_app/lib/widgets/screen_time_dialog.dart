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

  Future<void> _showAddScheduleDialog() async {
    final titleCtrl = TextEditingController(text: 'Khung giờ học bài tối');
    String dayOfWeek = 'Thứ 2 - Thứ 6';
    TimeOfDay startTime = const TimeOfDay(hour: 19, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 21, minute: 0);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Thêm Lịch Biểu Giờ Dùng Máy'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Tên lịch biểu'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: dayOfWeek,
                  decoration: const InputDecoration(labelText: 'Các ngày trong tuần'),
                  items: const [
                    DropdownMenuItem(value: 'Thứ 2 - Thứ 6', child: Text('Thứ 2 - Thứ 6 (Ngày học)')),
                    DropdownMenuItem(value: 'Thứ 7 - Chủ Nhật', child: Text('Thứ 7 - Chủ Nhật (Cuối tuần)')),
                    DropdownMenuItem(value: 'Tất cả các ngày', child: Text('Mỗi ngày trong tuần')),
                  ],
                  onChanged: (val) => setDlgState(() => dayOfWeek = val!),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final t = await showTimePicker(context: ctx, initialTime: startTime);
                          if (t != null) setDlgState(() => startTime = t);
                        },
                        child: Text('Bắt đầu: ${startTime.format(ctx)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final t = await showTimePicker(context: ctx, initialTime: endTime);
                          if (t != null) setDlgState(() => endTime = t);
                        },
                        child: Text('Kết thúc: ${endTime.format(ctx)}'),
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
                if (titleCtrl.text.isEmpty) return;
                Navigator.of(ctx).pop();
                final sched = ScreenTimeSchedule(
                  id: 0,
                  childProfileId: widget.childId,
                  scheduleTitle: titleCtrl.text.trim(),
                  dayOfWeek: dayOfWeek,
                  allowedStartTime: '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00',
                  allowedEndTime: '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00',
                );
                await ChildService.createSchedule(sched);
                _loadSchedules();
              },
              child: const Text('Lưu Lịch'),
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
              onPressed: _showAddScheduleDialog,
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
                          onPressed: _showAddScheduleDialog,
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
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.access_time, color: Colors.white),
                          ),
                          title: Text(item.scheduleTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${item.dayOfWeek} • Từ ${item.allowedStartTime} đến ${item.allowedEndTime}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.grey),
                            onPressed: () async {
                              await ChildService.deleteSchedule(item.id);
                              _loadSchedules();
                            },
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
