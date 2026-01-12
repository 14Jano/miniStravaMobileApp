import 'package:flutter/material.dart';
import '../models/activity_model.dart';
import '../services/activity_service.dart';
import 'activity_detail_screen.dart';

class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({super.key});

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  final ActivityService _activityService = ActivityService();
  late Future<List<Activity>> _activitiesFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _activitiesFuture = _activityService.getActivities();
    });
  }
  IconData _getIconForType(String type) {
    if (type.toLowerCase().contains('run')) return Icons.directions_run;
    if (type.toLowerCase().contains('ride') || type.toLowerCase().contains('bike')) return Icons.directions_bike;
    if (type.toLowerCase().contains('walk')) return Icons.directions_walk;
    return Icons.fitness_center;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historia Treningów'),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<Activity>>(
        future: _activitiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 50, color: Colors.red),
                  const SizedBox(height: 10),
                  const Text('Wystąpił błąd pobierania danych.'),
                  TextButton(onPressed: _loadData, child: const Text("Spróbuj ponownie"))
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Brak zapisanych treningów. Rusz się!'));
          }

          final activities = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ActivityDetailScreen(
                            activityId: activity.id,
                            title: activity.title,
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadData();
                      }
                    },
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFC4C02).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconForType(activity.type),
                        color: const Color(0xFFFC4C02),
                        size: 28,
                      ),
                    ),
                    title: Text(
                      activity.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(activity.formattedDate, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.timer, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(activity.formattedDuration),
                            const SizedBox(width: 15),
                            const Icon(Icons.straighten, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('${activity.distanceKm} km'),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}