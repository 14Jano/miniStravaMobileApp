import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final UserService _userService = UserService();
  List<User> _blockedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() => _isLoading = true);
    final users = await _userService.getBlockedUsers();
    if (mounted) {
      setState(() {
        _blockedUsers = users;
        _isLoading = false;
      });
    }
  }

  Future<void> _unblock(int userId) async {
    final success = await _userService.unblockUser(userId);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Użytkownik odblokowany.'), backgroundColor: Colors.green),
        );
      }
      _loadBlockedUsers();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Błąd odblokowywania.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zablokowani użytkownicy')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blockedUsers.isEmpty
              ? const Center(child: Text('Brak zablokowanych użytkowników.'))
              : ListView.separated(
                  itemCount: _blockedUsers.length,
                  separatorBuilder: (ctx, i) => const Divider(),
                  itemBuilder: (context, index) {
                    final user = _blockedUsers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                        child: user.avatarUrl == null ? Text(user.firstName[0]) : null,
                      ),
                      title: Text(user.fullName),
                      subtitle: Text(user.email),
                      trailing: TextButton(
                        onPressed: () => _unblock(user.id),
                        child: const Text('Odblokuj', style: TextStyle(color: Colors.red)),
                      ),
                    );
                  },
                ),
    );
  }
}