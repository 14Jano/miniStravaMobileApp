import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  
  List<User> _searchResults = [];
  bool _isLoading = false;
  bool _searched = false;

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _searched = true;
    });

    final results = await _userService.searchUsers(query);
    
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendInvite(int userId) async {
    final success = await _userService.sendFriendInvite(userId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Wysłano zaproszenie!' : 'Błąd wysyłania.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Szukaj znajomych'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Wpisz imię, nazwisko lub email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Color(0xFFF5F5F5),
                      prefixIcon: Icon(Icons.search),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFC4C02),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Szukaj', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const LinearProgressIndicator(),
            
          Expanded(
            child: _searchResults.isEmpty && _searched && !_isLoading
                ? const Center(child: Text("Nie znaleziono użytkowników."))
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user.avatarUrl != null 
                              ? NetworkImage(user.avatarUrl!) 
                              : null,
                          backgroundColor: const Color(0xFFFC4C02).withOpacity(0.2),
                          child: user.avatarUrl == null 
                              ? Text(user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?', 
                                  style: const TextStyle(color: Color(0xFFFC4C02), fontWeight: FontWeight.bold)) 
                              : null,
                        ),
                        title: Text(user.fullName),
                        subtitle: Text(user.email),
                        trailing: IconButton(
                          icon: const Icon(Icons.person_add, color: Color(0xFFFC4C02)),
                          onPressed: () => _sendInvite(user.id),
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