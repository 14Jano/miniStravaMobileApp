import 'package:flutter/material.dart';
import '../models/comment_model.dart';
import '../services/feed_service.dart';

class CommentsScreen extends StatefulWidget {
  final int activityId;
  final String activityTitle;

  const CommentsScreen({
    super.key,
    required this.activityId,
    required this.activityTitle,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final FeedService _feedService = FeedService();
  final TextEditingController _controller = TextEditingController();
  
  List<Comment>? _comments; 
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    final comments = await _feedService.getComments(widget.activityId);
    if (mounted) {
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    final success = await _feedService.addComment(widget.activityId, text);

    if (mounted) {
      setState(() {
        _isSending = false;
      });

      if (success) {
        _controller.clear();
        FocusScope.of(context).unfocus();
        _loadComments(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie udało się dodać komentarza.')),
        );
      }
    }
  }

  void _handlePop() {
    Navigator.of(context).pop(_comments?.length);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handlePop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Komentarze: ${widget.activityTitle}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handlePop,
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _comments == null || _comments!.isEmpty
                      ? const Center(child: Text('Brak komentarzy. Bądź pierwszy!'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _comments!.length,
                          separatorBuilder: (ctx, i) => const Divider(),
                          itemBuilder: (context, index) {
                            final comment = _comments![index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: comment.user.avatarUrl != null
                                    ? NetworkImage(comment.user.avatarUrl!)
                                    : null,
                                child: comment.user.avatarUrl == null
                                    ? Text(comment.user.firstName[0])
                                    : null,
                              ),
                              title: Text(
                                '${comment.user.firstName} ${comment.user.lastName}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(comment.content, style: const TextStyle(color: Colors.black87)),
                                  const SizedBox(height: 4),
                                  Text(comment.createdAt, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            );
                          },
                        ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Napisz komentarz...',
                          border: InputBorder.none,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _isSending
                        ? const SizedBox(
                            width: 24, 
                            height: 24, 
                            child: CircularProgressIndicator(strokeWidth: 2)
                          )
                        : IconButton(
                            icon: const Icon(Icons.send, color: Color(0xFFFC4C02)),
                            onPressed: _sendComment,
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}