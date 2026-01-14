import 'package:flutter/material.dart';
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
  
  Future<List<FeedItem>>? _dataFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _dataFuture = _fetchFeedWithoutMe();
    });
  }

  Future<List<FeedItem>> _fetchFeedWithoutMe() async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktywności Znajomych'),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<FeedItem>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Błąd: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Brak aktywności znajomych.'));
          }

          final items = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
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