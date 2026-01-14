import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/feed_model.dart';
import '../models/user_model.dart';
import '../services/feed_service.dart';
import '../services/user_service.dart';
import '../widgets/feed_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final FeedService _feedService = FeedService();
  final UserService _userService = UserService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  Future<List<FeedItem>>? _dataFuture;
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
      });
    } else {
      setState(() {
        _isOffline = false;
        _dataFuture = _fetchFeedWithoutMe();
      });
    }
  }

  Future<List<FeedItem>> _fetchFeedWithoutMe() async {
    try {
      final results = await Future.wait([
        _feedService.getFeed(),
        _userService.getUserProfile(),
      ]);

      final List<FeedItem> allItems = results[0] as List<FeedItem>;
      final User? me = results[1] as User?;

      if (me != null) {
        return allItems.where((item) => item.user.id != me.id).toList();
      }
      return allItems;
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktywności Znajomych'),
        automaticallyImplyLeading: false,
      ),
      body: _isOffline 
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Aktywność znajomych dostępna po zalogowaniu online', textAlign: TextAlign.center),
              ],
            ),
          )
        : FutureBuilder<List<FeedItem>>(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text('Błąd pobierania danych.'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async => _checkModeAndLoad(),
                  child: ListView(
                    children: const [
                      SizedBox(height: 50),
                      Center(child: Text('Brak aktywności znajomych.')),
                    ],
                  ),
                );
              }

              final items = snapshot.data!;

              return RefreshIndicator(
                onRefresh: () async => _checkModeAndLoad(),
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return FeedCard(item: item);
                  },
                ),
              );
            },
          ),
    );
  }
}