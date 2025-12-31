import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/person_dashboard.dart'; // Import
import '../auth/auth_wrapper.dart';

class UserHomeScreen extends StatefulWidget {
  final PersonModel person;
  final String adminEmail;
  final bool isFirstLogin;

  const UserHomeScreen({
    super.key,
    required this.person,
    required this.adminEmail,
    this.isFirstLogin = false,
  });

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.isFirstLogin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showWelcomeAlert();
      });
    }
  }

  void _showWelcomeAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Welcome ${widget.person.name}!'),
        content: const Text(
          'You are now logged in. You can track your expenses and cash here.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Let\'s Go'),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    await LocalStorageService().clear();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${widget.person.name}'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          Text('Id: ${widget.person.id} '),
          SizedBox(width: 5),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
          ),
        ],
      ),
      body: PersonDashboard(
        person: widget.person,
        adminEmail: widget.adminEmail,
        isAdmin: false,
      ),
    );
  }
}
