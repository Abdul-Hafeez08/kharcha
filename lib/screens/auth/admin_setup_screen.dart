import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/local_storage_service.dart';

class AdminSetupScreenWrapper extends StatelessWidget {
  const AdminSetupScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminSetupScreen();
  }
}

class AdminSetupScreen extends StatefulWidget {
  const AdminSetupScreen({super.key});

  @override
  State<AdminSetupScreen> createState() => _AdminSetupScreenState();
}

class _AdminSetupScreenState extends State<AdminSetupScreen> {
  final _nameController = TextEditingController();
  final _khataNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Show alert box immediately as requested
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSetupAlert();
    });
  }

  void _showSetupAlert() {
    showDialog(
      context: context,
      barrierDismissible: false, // Force them to read
      builder: (context) => AlertDialog(
        title: const Text('Complete Your Setup'),
        content: const Text(
          'Welcome Admin! Please set up your Khata profile to continue.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = context.read<User?>();
        if (user == null) return; // Should not happen

        final admin = AdminModel(
          uid: user.uid,
          email: user.email!,
          name: _nameController.text.trim(),
          khataName: _khataNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
        );

        await context.read<FirestoreService>().saveAdminProfile(admin);

        // Mark as Admin in local storage
        await LocalStorageService().setAdminRole();

        // No explicit navigation needed because AuthWrapper listens to the Stream
        // and when the document is created, it will switch to AdminHomeScreen.
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            // Avoid overflow
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.settings_applications,
                  size: 80,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 24),
                Text(
                  'One Last Step...',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Your Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _khataNameController,
                  decoration: const InputDecoration(
                    labelText: 'Khata Name',
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading
                      ? Center(
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
