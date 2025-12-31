import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../widgets/person_dashboard.dart';
import '../../services/firestore_service.dart'; // Import

class AdminPersonDetailScreen extends StatelessWidget {
  final PersonModel person;
  final String adminEmail;

  const AdminPersonDetailScreen({
    super.key,
    required this.person,
    required this.adminEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(person.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  // user 'ctx' to avoid confusion
                  title: const Text('Reset All Data?'),
                  content: Text(
                    'This will clear history and stats for ${person.name}. Name and ID will remain.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        await FirestoreService().resetPersonData(
                          adminEmail,
                          person.id,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Reset Data'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: PersonDashboard(
        person: person,
        adminEmail: adminEmail,
        isAdmin: true,
      ),
    );
  }
}
