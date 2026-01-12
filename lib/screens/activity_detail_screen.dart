import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
  late Future<Activity?> _activityFuture;

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
      print("Błąd zapisu/udostępniania: $e");
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Błąd zapisu pliku.")),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _activityFuture = _activityService.getActivityDetails(widget.activityId);
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
              );
              final success = await _activityService.updateActivity(updatedActivity);

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Tytuł zmieniony!")),
                );
                setState(() {
                  _activityFuture = _activityService.getActivityDetails(widget.activityId);
                });
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          FutureBuilder<Activity?>(
            future: _activityFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.blue),
                    tooltip: "Eksportuj GPX",
                    onPressed: _exportGpx,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editTitle(snapshot.data!),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _deleteActivity,
                  ),
                ],
              );
            },
          )
        ],
      ),
      body: FutureBuilder<Activity?>(
        future: _activityFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text("Nie udało się pobrać szczegółów."));
          }

          final activity = snapshot.data!;
          
          final LatLng initialCenter = activity.routePoints.isNotEmpty
              ? activity.routePoints.first
              : const LatLng(52.237, 21.017);

          return Column(
            children: [
              
              SizedBox(
                height: 300,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: initialCenter,
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

              Expanded(
                child: Padding(
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
                          _buildStatItem("Dystans", "${activity.distanceKm} km"),
                          _buildStatItem("Czas", activity.formattedDuration),
                          _buildStatItem("Typ", activity.type.toUpperCase()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
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