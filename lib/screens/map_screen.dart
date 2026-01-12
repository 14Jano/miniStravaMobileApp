import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/activity_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final ActivityService _activityService = ActivityService();
  
  LatLng _currentPosition = const LatLng(52.237, 21.017);
  bool _hasLocation = false;
  StreamSubscription<Position>? _positionStream;

  bool _isRecording = false;
  List<LatLng> _routePoints = [];
  DateTime? _startTime;
  Timer? _timer;
  int _durationSeconds = 0;
  double _totalDistanceMeters = 0.0;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLocate();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkPermissionsAndLocate() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _hasLocation = true;
      });
      _mapController.move(_currentPosition, 16.0);
    }
  }

  void _toggleRecording() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _routePoints = [];
      _durationSeconds = 0;
      _totalDistanceMeters = 0;
      _startTime = DateTime.now();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _durationSeconds++;
      });
    });


    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      final newPoint = LatLng(position.latitude, position.longitude);

      setState(() {
        if (_routePoints.isNotEmpty) {
          final distance = Geolocator.distanceBetween(
            _routePoints.last.latitude, _routePoints.last.longitude,
            newPoint.latitude, newPoint.longitude,
          );
          _totalDistanceMeters += distance;
        }

        _currentPosition = newPoint;
        _routePoints.add(newPoint);
      });
      
      _mapController.move(newPoint, 17.0);
    });
  }

  void _stopRecording() async {
    _positionStream?.pause();
    _timer?.cancel();
    setState(() => _isRecording = false);

    final endTime = DateTime.now();

    final titleController = TextEditingController();
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Koniec treningu!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Czas: ${_formatDuration(_durationSeconds)}'),
            Text('Dystans: ${(_totalDistanceMeters / 1000).toStringAsFixed(2)} km'),
            const SizedBox(height: 10),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Nazwij swój trening'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Odrzuć', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
            
              final success = await _activityService.createActivity(
                title: titleController.text.isEmpty ? "Popołudniowy bieg" : titleController.text,
                type: "run",
                startTime: _startTime!,
                endTime: endTime,
                durationSeconds: _durationSeconds,
                distanceMeters: _totalDistanceMeters,
                routePoints: _routePoints,
              );

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Trening zapisany! Sprawdź zakładkę Aktywności.')),
                );
                setState(() {
                   _routePoints.clear();
                });
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Błąd zapisu.')),
                );
              }
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }


  String _formatDuration(int seconds) {
    final int h = seconds ~/ 3600;
    final int m = (seconds % 3600) ~/ 60;
    final int s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ministrava',
              ),

              if (_routePoints.isNotEmpty) 
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.0,
                      color: Colors.blue,
                    ),
                  ],
                ),

              if (_hasLocation)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition,
                      width: 60,
                      height: 60,
                      child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                    ),
                  ],
                ),
            ],
          ),

          if (_isRecording)
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [const BoxShadow(blurRadius: 10, color: Colors.black12)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('CZAS', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(_formatDuration(_durationSeconds),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('DYSTANS (km)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text((_totalDistanceMeters / 1000).toStringAsFixed(2),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),

      floatingActionButton: SizedBox(
        width: 80,
        height: 80,
        child: FloatingActionButton(
          onPressed: _toggleRecording,
          backgroundColor: _isRecording ? Colors.red : const Color(0xFFFC4C02),
          child: Icon(
            _isRecording ? Icons.stop : Icons.play_arrow,
            size: 40,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}