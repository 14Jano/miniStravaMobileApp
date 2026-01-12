import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _isPaused = false;
  
  List<LatLng> _routePoints = [];
  DateTime? _startTime;
  Timer? _timer;
  
  int _durationSeconds = 0;
  double _totalDistanceMeters = 0.0;
  double _currentSpeedKmh = 0.0;

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

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _isPaused = false;
      _routePoints = [];
      _durationSeconds = 0;
      _totalDistanceMeters = 0;
      _currentSpeedKmh = 0.0;
      _startTime = DateTime.now();
    });

    _startTimer();
    _startLocationStream();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _durationSeconds++;
      });
    });
  }

  void _startLocationStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3, 
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

        double speedMps = position.speed; 
        if (speedMps < 0) speedMps = 0;
        _currentSpeedKmh = speedMps * 3.6; 

        _currentPosition = newPoint;
        _routePoints.add(newPoint);
      });
      
      _mapController.move(newPoint, 17.0);
    });
  }

  void _pauseRecording() {
    setState(() {
      _isPaused = true;
      _currentSpeedKmh = 0.0; 
    });
    _timer?.cancel();
    _positionStream?.pause();
  }

  void _resumeRecording() {
    setState(() {
      _isPaused = false;
    });
    _startTimer();
    _positionStream?.resume();
  }

  void _stopRecording() async {
    _positionStream?.pause();
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _currentSpeedKmh = 0.0;
    });

    final endTime = DateTime.now();
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    
    String selectedType = 'run';
    File? selectedImage;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (stfContext, setDialogState) {
            
            Future<void> pickImage() async {
              final picker = ImagePicker();
              final picked = await picker.pickImage(source: ImageSource.gallery);
              if (picked != null) {
                setDialogState(() {
                  selectedImage = File(picked.path);
                });
              }
            }

            return AlertDialog(
              title: const Text('Koniec treningu!'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Czas: ${_formatDuration(_durationSeconds)}'),
                    Text('Dystans: ${(_totalDistanceMeters / 1000).toStringAsFixed(2)} km'),
                    const SizedBox(height: 20),
                    
                    GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          image: selectedImage != null 
                              ? DecorationImage(
                                  image: FileImage(selectedImage!),
                                  fit: BoxFit.cover
                                )
                              : null,
                        ),
                        child: selectedImage == null 
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                                  Text("Dodaj zdjęcie", style: TextStyle(color: Colors.grey)),
                                ],
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Nazwa treningu',
                        hintText: 'np. Poranny rozruch',
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Typ aktywności',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'run',
                          child: Row(children: [Icon(Icons.directions_run), SizedBox(width: 8), Text('Bieg')]),
                        ),
                        DropdownMenuItem(
                          value: 'ride',
                          child: Row(children: [Icon(Icons.directions_bike), SizedBox(width: 8), Text('Rower')]),
                        ),
                        DropdownMenuItem(
                          value: 'walk',
                          child: Row(children: [Icon(Icons.directions_walk), SizedBox(width: 8), Text('Spacer')]),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notatka',
                        hintText: 'Jak Ci poszło? Opisz wrażenia.',
                        prefixIcon: Icon(Icons.note),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Odrzuć', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    
                    final success = await _activityService.createActivity(
                      title: titleController.text.isEmpty 
                          ? _getDefaultTitle(selectedType) 
                          : titleController.text,
                      type: selectedType,
                      startTime: _startTime!,
                      endTime: endTime,
                      durationSeconds: _durationSeconds,
                      distanceMeters: _totalDistanceMeters,
                      routePoints: _routePoints,
                      notes: notesController.text,
                      imageFile: selectedImage,
                    );

                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Trening zapisany! Sprawdź zakładkę Aktywności.')),
                      );
                      setState(() {
                         _routePoints.clear();
                         _durationSeconds = 0;
                         _totalDistanceMeters = 0;
                         _currentSpeedKmh = 0.0;
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
            );
          },
        );
      },
    );
  }

  String _getDefaultTitle(String type) {
    final now = DateTime.now();
    final timeOfDay = now.hour < 12 ? "Poranny" : (now.hour < 18 ? "Popołudniowy" : "Wieczorny");
    
    switch (type) {
      case 'ride': return '$timeOfDay rower';
      case 'walk': return '$timeOfDay spacer';
      default: return '$timeOfDay bieg';
    }
  }

  String _formatDuration(int seconds) {
    final int h = seconds ~/ 3600;
    final int m = (seconds % 3600) ~/ 60;
    final int s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatPace() {
    if (_totalDistanceMeters == 0) return "-:--";
    
    // Obliczamy ile minut zajmuje 1 km
    final double distKm = _totalDistanceMeters / 1000;
    final double totalMinutes = _durationSeconds / 60;
    final double pace = totalMinutes / distKm;

    if (pace > 60) return ">60:00"; 
    
    final int minutes = pace.floor();
    final int seconds = ((pace - minutes) * 60).round();
    
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
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
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [const BoxShadow(blurRadius: 10, color: Colors.black12)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // PIERWSZY RZĄD: CZAS I DYSTANS
                    Row(
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
                    
                    const Divider(height: 20),

                    // DRUGI RZĄD: TEMPO I PRĘDKOŚĆ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('TEMPO (min/km)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(_formatPace(),
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('PRĘDKOŚĆ (km/h)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(_currentSpeedKmh.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          
          if (_isRecording && _isPaused)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.yellow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text("ZPAUZOWANE", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            )
        ],
      ),

      floatingActionButton: _isRecording 
        ? Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton.extended(
                  heroTag: "pause_resume",
                  onPressed: _isPaused ? _resumeRecording : _pauseRecording,
                  backgroundColor: _isPaused ? Colors.green : Colors.orange,
                  label: Text(_isPaused ? "WZNÓW" : "PAUZA", style: const TextStyle(color: Colors.white)),
                  icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause, color: Colors.white),
                ),
                const SizedBox(width: 20),
                FloatingActionButton.extended(
                  heroTag: "stop",
                  onPressed: _stopRecording,
                  backgroundColor: Colors.red,
                  label: const Text("STOP", style: TextStyle(color: Colors.white)),
                  icon: const Icon(Icons.stop, color: Colors.white),
                ),
              ],
            ),
          )
        : SizedBox(
            width: 80,
            height: 80,
            child: FloatingActionButton(
              onPressed: _startRecording,
              backgroundColor: const Color(0xFFFC4C02),
              child: const Icon(
                Icons.play_arrow,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}