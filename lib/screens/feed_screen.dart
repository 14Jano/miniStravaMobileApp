import 'package:flutter/material.dart';
import '../models/feed_model.dart';
import '../services/feed_service.dart';
import 'comments_screen.dart'; 

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final FeedService _feedService = FeedService();
  late Future<List<FeedItem>> _feedFuture;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  void _loadFeed() {
    setState(() {
      _feedFuture = _feedService.getFeed();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktywności Znajomych'),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<FeedItem>>(
        future: _feedFuture,
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
            onRefresh: () async => _loadFeed(),
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

class FeedCard extends StatefulWidget {
  final FeedItem item;

  const FeedCard({super.key, required this.item});

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
  final FeedService _feedService = FeedService();
  
  late bool _isLiked;
  late int _kudosCount;
  
  late int _commentsCount; 
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.item.likedByMe;
    _kudosCount = widget.item.kudosCount;
    _commentsCount = widget.item.commentsCount;
  }

  Future<void> _toggleLike() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _isLiked = !_isLiked;
      _kudosCount += _isLiked ? 1 : -1;
    });

    bool success;
    if (_isLiked) {
      success = await _feedService.giveKudos(widget.item.id);
    } else {
      success = await _feedService.removeKudos(widget.item.id);
    }

    if (!success) {
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _kudosCount += _isLiked ? 1 : -1;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Błąd połączenia.')),
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: widget.item.user.avatarUrl != null && widget.item.user.avatarUrl!.isNotEmpty
                      ? NetworkImage(widget.item.user.avatarUrl!)
                      : null,
                  backgroundColor: Colors.grey[300],
                  child: widget.item.user.avatarUrl == null
                      ? Text(widget.item.user.firstName[0], style: const TextStyle(fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.item.user.firstName} ${widget.item.user.lastName}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      widget.item.startTime,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.item.type == 'ride' ? Icons.directions_bike : Icons.directions_run,
                    color: const Color(0xFFFC4C02),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Text('${widget.item.distanceKm} km', style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 15),
                          const Icon(Icons.timer, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(widget.item.duration, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            
            Row(
              children: [
                InkWell(
                  onTap: _toggleLike,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked ? Colors.red : Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$_kudosCount',
                          style: TextStyle(
                            color: _isLiked ? Colors.red : Colors.black,
                            fontWeight: _isLiked ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 20),

                InkWell(
                  onTap: () async {
                    final newCount = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommentsScreen(
                          activityId: widget.item.id,
                          activityTitle: widget.item.title,
                        ),
                      ),
                    );

                    if (newCount != null && newCount is int) {
                      setState(() {
                        _commentsCount = newCount;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.comment_outlined, color: Colors.grey, size: 24),
                        const SizedBox(width: 5),
                        Text('$_commentsCount'), 
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}