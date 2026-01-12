import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/social_service.dart';
import 'user_search_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SocialService _socialService = SocialService();

  List<User> _friends = [];
  List<User> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final friends = await _socialService.getFriends();
    final requests = await _socialService.getFriendRequests();
    
    if (mounted) {
      setState(() {
        _friends = friends;
        _requests = requests;
        _isLoading = false;
      });
    }
  }

  void _acceptRequest(int userId) async {
    final success = await _socialService.acceptInvite(userId);
    if (success) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Zaakceptowano!")));
      _loadData();
    }
  }

  void _rejectRequest(int userId) async {
    final success = await _socialService.rejectInvite(userId);
    if (success) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Odrzucono.")));
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Znajomi'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFC4C02),
          labelColor: const Color(0xFFFC4C02),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Moi znajomi'),
            Tab(text: 'Zaproszenia'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsList(),
                _buildRequestsList(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UserSearchScreen()),
          ).then((_) => _loadData());
        },
        backgroundColor: const Color(0xFFFC4C02),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildFriendsList() {
    if (_friends.isEmpty) {
      return const Center(child: Text('Nie masz jeszcze znajomych.'));
    }
    return ListView.builder(
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        final user = _friends[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey[300],
            child: Text(user.firstName.isNotEmpty ? user.firstName[0] : 'U', style: const TextStyle(color: Colors.black)),
          ),
          title: Text(user.fullName),
          subtitle: Text(user.email),
        );
      },
    );
  }

  Widget _buildRequestsList() {
    if (_requests.isEmpty) {
      return const Center(child: Text('Brak nowych zaproszeń.'));
    }
    return ListView.builder(
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final user = _requests[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(user.fullName),
            subtitle: const Text('Zaproszenie do znajomych'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green, size: 32),
                  onPressed: () => _acceptRequest(user.id),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red, size: 32),
                  onPressed: () => _rejectRequest(user.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}