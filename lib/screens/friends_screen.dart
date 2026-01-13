import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/friend_request_model.dart';
import '../services/user_service.dart';
import 'user_search_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserService _userService = UserService();

  List<User> _friends = [];
  List<FriendRequest> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final friends = await _userService.getFriends();
    final requests = await _userService.getFriendRequests();
    
    if (mounted) {
      setState(() {
        _friends = friends;
        _requests = requests;
        _isLoading = false;
      });
    }
  }

  void _acceptRequest(int requestId) async {
    final error = await _userService.acceptFriendInvite(requestId);
    if (error == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Zaakceptowano!"), backgroundColor: Colors.green));
      _loadData(); 
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
    }
  }

  void _rejectRequest(int requestId) async {
    final error = await _userService.rejectFriendInvite(requestId);
    if (error == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Odrzucono."), backgroundColor: Colors.orange));
      _loadData(); 
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
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
            backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            backgroundColor: Colors.grey[300],
            child: user.avatarUrl == null 
                ? Text(user.firstName.isNotEmpty ? user.firstName[0] : 'U', style: const TextStyle(color: Colors.black)) 
                : null,
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
        final request = _requests[index];
        final user = request.sender; 

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
              child: user.avatarUrl == null ? const Icon(Icons.person) : null,
            ),
            title: Text(user.fullName),
            subtitle: Text('Zaproszenie wysłane: ${request.createdAt.substring(0, 10)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green, size: 32),
                  onPressed: () => _acceptRequest(request.id),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red, size: 32),
                  onPressed: () => _rejectRequest(request.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}