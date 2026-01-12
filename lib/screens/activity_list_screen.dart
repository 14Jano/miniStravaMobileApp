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
  
  List<Activity> _allActivities = [];
  List<Activity> _displayedActivities = [];
  bool _isLoading = true;
  bool _hasError = false;

  String _filterType = 'all'; 
  String _sortOption = 'date_desc';
  
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final activities = await _activityService.getActivities();
      if (mounted) {
        setState(() {
          _allActivities = activities;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    List<Activity> temp = List.from(_allActivities);

    if (_filterType != 'all') {
      temp = temp.where((a) => a.type == _filterType).toList();
    }

    if (_filterStartDate != null) {
      final start = DateTime(_filterStartDate!.year, _filterStartDate!.month, _filterStartDate!.day);
      temp = temp.where((a) => a.startTime.isAfter(start) || a.startTime.isAtSameMomentAs(start)).toList();
    }

    if (_filterEndDate != null) {
      final end = DateTime(_filterEndDate!.year, _filterEndDate!.month, _filterEndDate!.day, 23, 59, 59);
      temp = temp.where((a) => a.startTime.isBefore(end)).toList();
    }

    switch (_sortOption) {
      case 'date_desc':
        temp.sort((a, b) => b.startTime.compareTo(a.startTime));
        break;
      case 'date_asc':
        temp.sort((a, b) => a.startTime.compareTo(b.startTime));
        break;
      case 'dist_desc':
        temp.sort((a, b) => b.distanceMeters.compareTo(a.distanceMeters));
        break;
      case 'dist_asc':
        temp.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
        break;
      case 'duration_desc':
        temp.sort((a, b) => b.durationSeconds.compareTo(a.durationSeconds));
        break;
      case 'duration_asc':
        temp.sort((a, b) => a.durationSeconds.compareTo(b.durationSeconds));
        break;
    }

    setState(() {
      _displayedActivities = temp;
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            
            Future<void> pickDate(bool isStart) async {
              final initialDate = isStart 
                  ? (_filterStartDate ?? DateTime.now())
                  : (_filterEndDate ?? DateTime.now());
                  
              final picked = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );

              if (picked != null) {
                setSheetState(() {
                  if (isStart) {
                    _filterStartDate = picked;
                  } else {
                    _filterEndDate = picked;
                  }
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 24.0, 
                right: 24.0, 
                top: 24.0, 
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Filtruj wg typu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip('Wszystkie', 'all', setSheetState),
                      _buildFilterChip('Bieg', 'run', setSheetState),
                      _buildFilterChip('Rower', 'ride', setSheetState),
                      _buildFilterChip('Spacer', 'walk', setSheetState),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Zakres dat", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            _filterStartDate = null;
                            _filterEndDate = null;
                          });
                        },
                        child: const Text("Wyczyść daty"),
                      )
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => pickDate(true),
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(_filterStartDate == null 
                              ? "Od: -" 
                              : "${_filterStartDate!.day}-${_filterStartDate!.month}-${_filterStartDate!.year}"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => pickDate(false),
                          icon: const Icon(Icons.event, size: 16),
                          label: Text(_filterEndDate == null 
                              ? "Do: -" 
                              : "${_filterEndDate!.day}-${_filterEndDate!.month}-${_filterEndDate!.year}"),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Text("Sortuj wg", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSortChip('Najnowsze', 'date_desc', setSheetState),
                      _buildSortChip('Najstarsze', 'date_asc', setSheetState),
                      _buildSortChip('Najdłuższy dystans', 'dist_desc', setSheetState),
                      _buildSortChip('Najkrótszy dystans', 'dist_asc', setSheetState),
                      _buildSortChip('Najdłuższy czas', 'duration_desc', setSheetState),
                      _buildSortChip('Najkrótszy czas', 'duration_asc', setSheetState),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _applyFilters();
                        Navigator.pop(context);
                      },
                      child: const Text("ZASTOSUJ"),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value, StateSetter setSheetState) {
    return ChoiceChip(
      label: Text(label),
      selected: _filterType == value,
      selectedColor: const Color(0xFFFC4C02).withOpacity(0.2),
      labelStyle: TextStyle(
        color: _filterType == value ? const Color(0xFFFC4C02) : Colors.black,
        fontWeight: _filterType == value ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (bool selected) {
        if (selected) {
          setSheetState(() => _filterType = value);
        }
      },
    );
  }

  Widget _buildSortChip(String label, String value, StateSetter setSheetState) {
    return ChoiceChip(
      label: Text(label),
      selected: _sortOption == value,
      selectedColor: Colors.blue.withOpacity(0.2),
      labelStyle: TextStyle(
        color: _sortOption == value ? Colors.blue : Colors.black,
        fontWeight: _sortOption == value ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (bool selected) {
        if (selected) {
          setSheetState(() => _sortOption = value);
        }
      },
    );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 50, color: Colors.red),
                      const SizedBox(height: 10),
                      const Text('Wystąpił błąd pobierania danych.'),
                      TextButton(onPressed: _loadData, child: const Text("Spróbuj ponownie"))
                    ],
                  ),
                )
              : _displayedActivities.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.sentiment_dissatisfied, size: 50, color: Colors.grey),
                          const SizedBox(height: 10),
                          Text(
                            _allActivities.isEmpty 
                                ? 'Brak zapisanych treningów.' 
                                : 'Brak wyników dla wybranych filtrów.',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _displayedActivities.length,
                        itemBuilder: (context, index) {
                          final activity = _displayedActivities[index];
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
                    ),
    );
  }
}