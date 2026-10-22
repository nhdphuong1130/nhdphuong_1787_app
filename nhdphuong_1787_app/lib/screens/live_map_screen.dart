import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/child_profile.dart';

class LiveMapScreen extends StatefulWidget {
  final List<ChildProfile> children;

  const LiveMapScreen({super.key, required this.children});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  final MapController _mapController = MapController();
  late List<ChildProfile> _children;
  int _selectedChildIndex = 0;

  // Điểm trường học an toàn mặc định (Trường Tiểu học - TP.HCM)
  final LatLng _safeZoneCenter = const LatLng(10.762622, 106.660172);

  @override
  void initState() {
    super.initState();
    _children = List.from(widget.children);
  }

  void _simulateMovement() {
    if (_children.isEmpty) return;
    setState(() {
      final child = _children[_selectedChildIndex];
      // Tự dịch chuyển nhẹ tọa độ GPS (mô phỏng bé đang đi bộ)
      child.lastKnownLat += (0.0005 * (child.lastKnownLat > 10.763 ? -1 : 1));
      child.lastKnownLng += (0.0004 * (child.lastKnownLng > 106.661 ? -1 : 1));
      _mapController.move(
        LatLng(child.lastKnownLat, child.lastKnownLng),
        16.0,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '📍 Đã cập nhật tọa độ GPS mới cho ${_children[_selectedChildIndex].fullName}: (${_children[_selectedChildIndex].lastKnownLat.toStringAsFixed(6)}, ${_children[_selectedChildIndex].lastKnownLng.toStringAsFixed(6)})',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_children.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bản Đồ Định Vị GPS')),
        body: const Center(child: Text('Chưa có dữ liệu vị trí bé nào.')),
      );
    }

    final activeChild = _children[_selectedChildIndex];
    final childLocation = LatLng(activeChild.lastKnownLat, activeChild.lastKnownLng);

    return Scaffold(
      appBar: AppBar(
        title: Text('Vị Trí Của ${activeChild.fullName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Căn giữa vị trí bé',
            onPressed: () => _mapController.move(childLocation, 16.0),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: childLocation,
              initialZoom: 15.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.nhdphuong1787.childguard',
              ),
              // Vòng tròn Vùng An Toàn (Geofencing Safe Zone - 500m)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _safeZoneCenter,
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderColor: Colors.blueAccent,
                    borderStrokeWidth: 2,
                    useRadiusInMeter: true,
                    radius: 500, // 500 mét quanh trường học
                  ),
                ],
              ),
              // Marker hiển thị vị trí bé
              MarkerLayer(
                markers: [
                  Marker(
                    point: childLocation,
                    width: 70,
                    height: 70,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            activeChild.fullName,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.redAccent, width: 3),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                          ),
                          child: Text(
                            activeChild.avatarUrl == 'girl' ? '👧' : '👦',
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Thanh điều khiển dưới cùng
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.security, color: Colors.blueAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Vùng an toàn (500m): Trường Tiểu học',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.blue[900]),
                          ),
                        ),
                        Chip(
                          label: Text('${activeChild.batteryLevel}% pin', style: const TextStyle(fontSize: 11)),
                          backgroundColor: Colors.green[50],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (_children.length > 1)
                          Expanded(
                            child: DropdownButton<int>(
                              value: _selectedChildIndex,
                              isExpanded: true,
                              underline: const SizedBox(),
                              items: List.generate(_children.length, (i) {
                                return DropdownMenuItem(
                                  value: i,
                                  child: Text('Theo dõi: ${_children[i].fullName}'),
                                );
                              }),
                              onChanged: (idx) {
                                if (idx != null) {
                                  setState(() => _selectedChildIndex = idx);
                                  final c = _children[idx];
                                  _mapController.move(LatLng(c.lastKnownLat, c.lastKnownLng), 16.0);
                                }
                              },
                            ),
                          ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _simulateMovement,
                          icon: const Icon(Icons.directions_walk, size: 18),
                          label: const Text('Mô Phỏng Di Chuyển'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
