import 'package:flutter/material.dart';
import '../models/feed_model.dart';
import '../services/feed_service.dart';
import '../services/user_service.dart';
import '../screens/comments_screen.dart';

class FeedCard extends StatefulWidget {
  final FeedItem item;

  const FeedCard({super.key, required this.item});

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
  final FeedService _feedService = FeedService();
  final UserService _userService = UserService();
  
  late bool _isLiked;
  late int _kudosCount;
  late int _commentsCount;
  
  bool _isLoading = false;
  bool _isHidden = false;

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
          const SnackBar(content: Text('Błąd połączenia. Nie udało się zmienić lajka.')),
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

  Future<void> _blockUser() async {
    final success = await _userService.blockUser(widget.item.user.id);
    if (success) {
      if (mounted) {
        setState(() {
          _isHidden = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Użytkownik zablokowany. Treści ukryte.'), backgroundColor: Colors.orange),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Błąd blokowania.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.report_problem, color: Colors.orange),
            title: const Text('Zgłoś nadużycie'),
            onTap: () {
              Navigator.pop(ctx);
              _showReportDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.block, color: Colors.red),
            title: const Text('Zablokuj użytkownika'),
            onTap: () {
              Navigator.pop(ctx);
              _showBlockConfirmation();
            },
          ),
        ],
      ),
    );
  }

  void _showBlockConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Zablokować użytkownika?"),
        content: Text("Nie będziesz widzieć aktywności użytkownika ${widget.item.user.firstName}. Możesz to cofnąć w ustawieniach profilu."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Anuluj")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _blockUser();
            }, 
            child: const Text("Zablokuj", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Zgłoś nadużycie"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'Powód zgłoszenia (np. spam, obraźliwe treści)...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anuluj')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await _userService.reportAbuse(
                type: 'activity', 
                targetId: widget.item.id,
                reason: reasonController.text,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Zgłoszenie wysłane.' : 'Błąd wysyłania.'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Wyślij'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isHidden) {
      return const SizedBox.shrink(); 
    }

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
                      ? Text(widget.item.user.firstName.isNotEmpty ? widget.item.user.firstName[0] : '?', style: const TextStyle(fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
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
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: _showOptions,
                )
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