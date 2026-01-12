import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'friends_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  User? _user;
  UserStats? _userStats;
  File? _avatarImage;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  
  String? _selectedGender;
  DateTime? _selectedBirthDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final userFuture = _userService.getUserProfile();
    final statsFuture = _userService.getUserStats(period: 'month');

    final results = await Future.wait([userFuture, statsFuture]);
    final user = results[0] as User?;
    final stats = results[1] as UserStats?;

    if (user != null) {
      if (mounted) {
        setState(() {
          _user = user;
          _userStats = stats;
          
          _firstNameController.text = user.firstName;
          _lastNameController.text = user.lastName;
          _weightController.text = user.weightKg != null && user.weightKg! > 0 ? user.weightKg.toString() : '';
          _heightController.text = user.heightCm != null && user.heightCm! > 0 ? user.heightCm.toString() : '';
          _selectedGender = user.gender;
          _selectedBirthDate = user.birthDate;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _avatarImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_user == null) return;

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Popraw błędy w formularzu!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final updatedUser = User(
      id: _user!.id,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _user!.email,
      gender: _selectedGender,
      birthDate: _selectedBirthDate,
      weightKg: int.tryParse(_weightController.text),
      heightCm: int.tryParse(_heightController.text),
    );

    final success = await _userService.updateUserProfile(updatedUser);

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil zaktualizowany!'), backgroundColor: Colors.green),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Błąd zapisu.'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  String _formatDuration(int seconds) {
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFFC4C02), size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_user == null) {
      return const Center(child: Text("Błąd ładowania profilu"));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mój Profil'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'Znajomi',
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const FriendsScreen())
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Wyloguj',
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _avatarImage != null 
                        ? FileImage(_avatarImage!) 
                        : null,
                    child: _avatarImage == null
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFFFC4C02),
                      child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _user!.fullName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(_user!.email, style: const TextStyle(color: Colors.grey)),
            
            const SizedBox(height: 24),
            
            if (_userStats != null) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Statystyki (Miesiąc)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildStatCard("Treningi", "${_userStats!.workouts}", Icons.directions_run)),
                  Expanded(child: _buildStatCard("Dystans", "${_userStats!.distanceKm.toStringAsFixed(1)} km", Icons.map)),
                  Expanded(child: _buildStatCard("Czas", _formatDuration(_userStats!.durationSeconds), Icons.timer)),
                ],
              ),
              const Divider(height: 40),
            ],

            Form(
              key: _formKey,
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Edycja danych", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  const SizedBox(height: 15),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(labelText: 'Imię'),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Wymagane';
                            if (value.length < 2) return 'Za krótkie';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(labelText: 'Nazwisko'),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Wymagane';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          decoration: const InputDecoration(labelText: 'Waga (kg)'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) return null;
                            final n = int.tryParse(value);
                            if (n == null) return 'Tylko cyfry!';
                            if (n < 30 || n > 300) return 'Błędna waga';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _heightController,
                          decoration: const InputDecoration(labelText: 'Wzrost (cm)'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) return null;
                            final n = int.tryParse(value);
                            if (n == null) return 'Tylko cyfry!';
                            if (n < 100 || n > 250) return 'Błędny wzrost';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: const InputDecoration(labelText: 'Płeć'),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Mężczyzna')),
                      DropdownMenuItem(value: 'female', child: Text('Kobieta')),
                      DropdownMenuItem(value: 'other', child: Text('Inna')),
                    ],
                    onChanged: (val) => setState(() => _selectedGender = val),
                  ),
                  const SizedBox(height: 15),

                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Data urodzenia'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_selectedBirthDate != null 
                              ? "${_selectedBirthDate!.year}-${_selectedBirthDate!.month.toString().padLeft(2, '0')}-${_selectedBirthDate!.day.toString().padLeft(2, '0')}"
                              : "Wybierz datę"),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFC4C02),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('ZAPISZ ZMIANY', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}