import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/local_storage_service.dart';
import 'admin_login_screen.dart';
import '../admin/admin_home_screen.dart';
import 'user_login_screen.dart';
import 'admin_setup_screen.dart';
import 'login_selection_screen.dart';
import '../user/user_home_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // We need to check Local Storage for "User Login" since Firebase Auth is only for Admin in this architecture
  // (unless we used Anonymous Auth for users, but prompt implies simple ID check).

  bool _isLoading = true;
  String? _userRole; // 'admin', 'user', or null
  Map<String, String>? _userData;

  @override
  void initState() {
    super.initState();
    _checkPersistence();
  }

  void _checkPersistence() async {
    final ls = LocalStorageService();
    final role = await ls.getRole();

    if (role == 'user') {
      _userData = await ls.getUserLogin();
      _userRole = 'user';
    }
    // If role is 'admin', Firebase Auth Stream in build will handle it.
    // If Firebase Auth is null but role was 'admin', it means session expired or cleared.

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // 1. Check for Persistent "Simple User" Login
    if (_userRole == 'user' && _userData != null) {
      // Validate against Firestore? Maybe not every time for offline speed,
      // but secure apps should. Let's do a quick stream fetch in UserHomeScreen
      // or just instantiate the screen.
      // We'll instantiate. The screen itself listens to the stream and handles "User deleted" etc.
      // We need a PersonModel object. We can create a partial one or fetch it.
      // Fetching is safer.
      return FutureBuilder<PersonModel?>(
        future: FirestoreService()
            .getPerson(_userData!['adminEmail']!, _userData!['userId']!)
            .first,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          if (snapshot.hasData && snapshot.data != null) {
            return UserHomeScreen(
              person: snapshot.data!,
              adminEmail: _userData!['adminEmail']!,
            );
          } else {
            // User not found (deleted?) -> Logout
            LocalStorageService().clear();
            return const LoginSelectionScreen();
          }
        },
      );
    }

    // 2. Check for Firebase Admin Login
    final firebaseUser = Provider.of<User?>(context);

    if (firebaseUser != null) {
      // Admin is logged in. Check for Profile Setup.
      return StreamBuilder<AdminModel?>(
        stream: FirestoreService().getAdminProfile(firebaseUser.email!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            // Profile Exists -> Go to Dashboard
            return const AdminHomeScreen();
          } else {
            // Profile Missing -> Setup Screen
            // "required setup alert box" -> The screen itself can show an alert or maintain the form.
            // The prompt says "after login setup box for admin is not showing... and if ok show main".
            // We will return `AdminSetupScreenWrapper` which acts as the Setup Page.
            return const AdminSetupScreenWrapper();
          }
        },
      );
    }

    // 3. No Login
    return const LoginSelectionScreen();
  }
}
