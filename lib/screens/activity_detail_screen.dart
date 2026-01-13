import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/activity_model.dart';
import '../services/activity_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ActivityDetailScreen extends StatefulWidget {
  final int activityId;
  final String title;

  const ActivityDetailScreen({
    super.key,
    required this.activityId,
    required this.title,
  });

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  final ActivityService _activityService = ActivityService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  Activity? _activity;
  String? _authToken;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _activityService.getActivityDetails(widget.activityId),
      _storage.read(key: 'auth_token'),
    ]);

    if (mounted) {
      setState(() {
        _activity = results[0] as Activity?;
        _authToken = results[1] as String?;
        _isLoading = false;
      });
    }
  }

  Future<void> _exportGpx() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Pobieranie pliku GPX...")),
    );

    final gpxContent = await _activityService.exportGpx(widget.activityId);

    if (gpxContent == null || gpxContent.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nie udało się pobrać pliku (lub brak trasy).")),
        );
      }
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/activity_${widget.activityId}.gpx');
      await file.writeAsString(gpxContent);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar(); 
        
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Mój trening z aplikacji Mini Strava!',
        );
      }
    } catch (e) {
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Błąd zapisu pliku.")),
        );
      }
    }
  }
  
  void _editTitle(Activity activity) {
    final controller = TextEditingController(text: activity.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Zmień tytuł"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Nowy tytuł treningu"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Anuluj"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final updatedActivity = Activity(
                id: activity.id,
                title: controller.text,
                type: activity.type,
                startTime: activity.startTime,
                endTime: activity.endTime,
                durationSeconds: activity.durationSeconds,
                distanceMeters: activity.distanceMeters,
                routePoints: activity.routePoints,
                notes: activity.notes,
                photoUrl: activity.photoUrl,
              );
              final success = await _activityService.updateActivity(updatedActivity);

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Tytuł zmieniony!")),
                );
                _loadData();
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Błąd edycji.")),
                );
              }
            },
            child: const Text("Zapisz"),
          )
        ],
      ),
    );
  }

  void _deleteActivity() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Usuń trening"),
        content: const Text("Czy na pewno chcesz usunąć ten trening? Tej operacji nie można cofnąć."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Anuluj"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final success = await _activityService.deleteActivity(widget.activityId);

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Trening usunięty.")),
                );
                Navigator.pop(context, true); 
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Nie udało się usunąć.")),
                );
              }
            },
            child: const Text("Usuń", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_activity == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Błąd')),
        body: const Center(child: Text('Nie udało się pobrać aktywności.')),
      );
    }

    final activity = _activity!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.blue),
            tooltip: "Eksportuj GPX",
            onPressed: _exportGpx,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editTitle(activity),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteActivity,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 300,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: activity.routePoints.isNotEmpty 
                      ? activity.routePoints.first 
                      : const LatLng(52.237, 21.017),
                  initialZoom: 14.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.ministrava',
                  ),
                  if (activity.routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: activity.routePoints,
                          strokeWidth: 4.0,
                          color: const Color(0xFFFC4C02),
                        ),
                      ],
                    ),
                  if (activity.routePoints.isNotEmpty)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: activity.routePoints.first,
                          child: const Icon(Icons.location_on, color: Colors.green, size: 30),
                        ),
                        Marker(
                          point: activity.routePoints.last,
                          child: const Icon(Icons.flag, color: Colors.red, size: 30),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(activity.formattedDate, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem("Dystans", "${activity.distanceKm.toStringAsFixed(2)} km"),
                      _buildStatItem("Czas", activity.formattedDuration),
                      _buildStatItem("Tempo", activity.formattedPace),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Center(child: _buildStatItem("Typ", activity.type.toUpperCase())),
                  
                  const Divider(height: 30),

                  if (activity.notes != null && activity.notes!.isNotEmpty) ...[
                    const Text(
                      "Notatka",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        activity.notes!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (activity.photoUrl != null && activity.photoUrl!.isNotEmpty) ...[
                    const Text(
                      "Zdjęcie",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        activity.photoUrl!,
                        headers: _authToken != null 
                            ? {'Authorization': 'Bearer $_authToken'} 
                            : null,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.grey[200],
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                              child: Text(
                                "Błąd ładowania: ${activity.photoUrl}\nSprawdź połączenie lub uprawnienia.",
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12, color: Colors.red),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}