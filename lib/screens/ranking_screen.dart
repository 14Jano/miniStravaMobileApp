import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final UserService _userService = UserService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  String _selectedPeriod = 'week'; 
  List<RankingEntry> _ranking = [];
  bool _isLoading = true;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkModeAndLoad();
  }

  Future<void> _checkModeAndLoad() async {
    final offline = await _storage.read(key: 'is_offline');
    if (offline == 'true') {
      setState(() {
        _isOffline = true;
        _isLoading = false;
      });
    } else {
      _loadRanking();
    }
  }

  Future<void> _loadRanking() async {
    setState(() => _isLoading = true);
    
    final ranking = await _userService.getRanking(_selectedPeriod);
    
    if (mounted) {
      setState(() {
        _ranking = ranking;
        _isLoading = false;
      });
    }
  }

  void _onPeriodChanged(String newPeriod) {
    if (_selectedPeriod != newPeriod) {
      setState(() {
        _selectedPeriod = newPeriod;
      });
      if (!_isOffline) _loadRanking();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _isOffline 
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.leaderboard_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Ranking dostępny po zalogowaniu online', textAlign: TextAlign.center),
              ],
            ),
          )
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _onPeriodChanged('week'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedPeriod == 'week' 
                                  ? const Color(0xFFFC4C02) 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Text(
                              'Tydzień',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _selectedPeriod == 'week' 
                                    ? Colors.white 
                                    : Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _onPeriodChanged('month'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedPeriod == 'month' 
                                  ? const Color(0xFFFC4C02) 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Text(
                              'Miesiąc',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _selectedPeriod == 'month' 
                                    ? Colors.white 
                                    : Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              Expanded(
                child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : _ranking.isEmpty
                        ? const Center(child: Text('Brak danych w rankingu.'))
                        : ListView.builder(
                            itemCount: _ranking.length,
                            itemBuilder: (context, index) {
                              final entry = _ranking[index];
                              final isTop3 = index < 3;
                              
                              Color? iconColor;
                              if (index == 0) iconColor = Colors.amber; 
                              else if (index == 1) iconColor = Colors.grey[400]; 
                              else if (index == 2) iconColor = Colors.brown[300]; 

                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                elevation: isTop3 ? 3 : 1,
                                child: ListTile(
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: iconColor?.withOpacity(0.2) ?? Colors.transparent,
                                    ),
                                    child: Text(
                                      '#${entry.position}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: iconColor ?? Colors.black,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.grey[300],
                                        ),
                                        clipBehavior: Clip.hardEdge,
                                        child: entry.avatarUrl != null && entry.avatarUrl!.isNotEmpty
                                            ? Image.network(
                                                entry.avatarUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Center(
                                                    child: Text(
                                                      entry.name.isNotEmpty ? entry.name[0] : '?',
                                                      style: const TextStyle(fontSize: 12),
                                                    ),
                                                  );
                                                },
                                              )
                                            : Center(
                                                child: Text(
                                                  entry.name.isNotEmpty ? entry.name[0] : '?',
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                              ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          entry.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: isTop3 ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${entry.distanceKm.toStringAsFixed(1)} km',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFFC4C02),
                                          fontSize: 16
                                        ),
                                      ),
                                      Text(
                                        '${entry.workouts} tren.',
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
    );
  }
}