import 'package:flutter/material.dart';
import 'package:kharcha/widgets/developer.dart';
import 'package:url_launcher/url_launcher.dart'; // ← add this for Google Drive link
import '../../models/user_model.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/person_dashboard.dart';
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7),
              child: const Text('Let\'s Go'),
            ),
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

  Future<void> _openHowToUse() async {
    const String driveFolderUrl =
        'https://drive.google.com/drive/folders/11KmEt9yPf_bq1lLyrypP4O2KYPDktMcy?usp=sharing';

    final Uri uri = Uri.parse(driveFolderUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open How to Use folder')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${widget.person.name}'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),

      // ── Drawer Added Here ───────────────────────────────────────
      drawer: Drawer(
        child: Column(
          children: [
            // Drawer Header with User Info + ID + Icon
            UserAccountsDrawerHeader(
              accountName: Text(
                widget.person.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Text(
                'ID: ${widget.person.id}',
                style: TextStyle(color: Colors.white70),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: colorScheme.primary.withOpacity(0.2),
                child: Icon(Icons.person, size: 40, color: colorScheme.primary),
              ),
              decoration: BoxDecoration(color: colorScheme.primary),
            ),

            // Main content (scrollable if more items added later)
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // How to Use - Google Drive Folder
                  ListTile(
                    leading: Icon(
                      Icons.folder_open_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('How to Use'),
                    onTap: () async {
                      const String driveFolderUrl =
                          'https://drive.google.com/drive/folders/11KmEt9yPf_bq1lLyrypP4O2KYPDktMcy?usp=sharing';
                      Navigator.pop(context);

                      final Uri uri = Uri.parse(driveFolderUrl);

                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode
                              .externalApplication, // Best chance for native app
                        );
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Could not open Google Drive folder',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),

                  // Developer / About
                  ListTile(
                    leading: Icon(
                      Icons.info_outline,
                      color: colorScheme.primary,
                    ),
                    title: const Text('Developer'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutDeveloperPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Bottom fixed logout
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
          ],
        ),
      ),

      body: PersonDashboard(
        person: widget.person,
        adminEmail: widget.adminEmail,
        isAdmin: false,
      ),
    );
  }
}
