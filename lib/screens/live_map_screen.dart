import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/child_profile.dart';
import '../services/child_service.dart';
import '../utils/map_utils.dart';

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
  bool _isLoadingGps = false;
  Timer? _refreshTimer;
  int _mapStyleIndex = 0; // 0: Google Standard, 1: Google Satellite, 2: CARTO Voyager, 3: OpenStreetMap

  // Điểm trường học an toàn mặc định (Trường Tiểu học - TP.HCM)
  final LatLng _safeZoneCenter = const LatLng(10.762622, 106.660172);

  String get _tileUrl {
    switch (_mapStyleIndex) {
      case 1:
        return 'https://mt{s}.google.com/vt/lyrs=y&hl=vi&x={x}&y={y}&z={z}';
      case 2:
        return 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png';
      case 3:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case 0:
      default:
        return 'https://mt{s}.google.com/vt/lyrs=m&hl=vi&x={x}&y={y}&z={z}';
    }
  }

  List<String> get _subdomains {
    switch (_mapStyleIndex) {
      case 2:
        return const ['a', 'b', 'c', 'd'];
      case 3:
        return const [];
      default:
        return const ['0', '1', '2', '3'];
    }
  }

  String get _currentStyleName {
    switch (_mapStyleIndex) {
      case 1:
        return 'Google Vệ Tinh';
      case 2:
        return 'CARTO Voyager';
      case 3:
        return 'OpenStreetMap';
      case 0:
      default:
        return 'Google Maps';
    }
  }

  @override
  void initState() {
    super.initState();
    _children = List.from(widget.children);
    // Tự động làm mới vị trí từ máy chủ mỗi 5 giây
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _reloadFromApi());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _reloadFromApi() async {
    try {
      final updated = await ChildService.getChildren();
      if (updated.isNotEmpty && mounted) {
        setState(() {
          _children = updated;
        });
      }
    } catch (_) {}
  }

  Future<void> _locateCurrentDevice() async {
    setState(() => _isLoadingGps = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );
        _mapController.move(LatLng(pos.latitude, pos.longitude), 16.5);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📍 Đã định vị vị trí hiện tại: (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể lấy GPS: $e'), backgroundColor: Colors.orange),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingGps = false);
    }
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
        title: Text(
          'Vị Trí: ${activeChild.fullName}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.layers_rounded),
            tooltip: 'Chọn kiểu bản đồ',
            initialValue: _mapStyleIndex,
            onSelected: (val) {
              setState(() => _mapStyleIndex = val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🗺️ Đã chuyển sang bản đồ: $_currentStyleName'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 0,
                child: Row(
                  children: [
                    Icon(Icons.map_rounded, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Google Maps (Chuẩn)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 1,
                child: Row(
                  children: [
                    Icon(Icons.satellite_alt_rounded, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Google Vệ Tinh (Hybrid)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 2,
                child: Row(
                  children: [
                    Icon(Icons.explore_rounded, color: Colors.deepPurple),
                    SizedBox(width: 8),
                    Text('CARTO Voyager HD'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 3,
                child: Row(
                  children: [
                    Icon(Icons.public_rounded, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('OpenStreetMap'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: _isLoadingGps
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.gps_fixed),
            tooltip: 'Định vị GPS thiết bị này',
            onPressed: _locateCurrentDevice,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Cập nhật từ máy con',
            onPressed: () async {
              await _reloadFromApi();
              _mapController.move(LatLng(activeChild.lastKnownLat, activeChild.lastKnownLng), 16.0);
            },
          ),
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
                key: ValueKey('map_tile_$_mapStyleIndex'),
                urlTemplate: _tileUrl,
                subdomains: _subdomains,
                userAgentPackageName: 'com.nhdphuong1787.nhdphuong_1787_app',
                maxZoom: 20,
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
                        FilledButton.tonalIcon(
                          onPressed: () => MapUtils.openGoogleMaps(
                            activeChild.lastKnownLat,
                            activeChild.lastKnownLng,
                            label: 'Bé ${activeChild.fullName}',
                          ),
                          icon: const Icon(Icons.near_me_rounded, size: 18),
                          label: const Text('Bật Google Maps'),
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
