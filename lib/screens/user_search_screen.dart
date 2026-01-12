import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/social_service.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final SocialService _socialService = SocialService();
  final TextEditingController _searchController = TextEditingController();
  
  List<User> _searchResults = [];
  bool _isLoading = false;
  bool _searched = false;

  void _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _searched = true;
    });

    final results = await _socialService.searchUsers(query);
    
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  void _sendInvite(int userId) async {
    final success = await _socialService.sendInvite(userId);
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
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _search,
                  child: const Text('Szukaj'),
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
                          backgroundColor: const Color(0xFFFC4C02).withOpacity(0.2),
                          child: Text(user.firstName.isNotEmpty ? user.firstName[0] : '?', 
                              style: const TextStyle(color: Color(0xFFFC4C02), fontWeight: FontWeight.bold)),
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