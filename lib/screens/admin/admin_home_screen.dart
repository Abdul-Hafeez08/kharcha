import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kharcha/utils/theme.dart';
import 'package:kharcha/widgets/developer.dart';
import 'package:kharcha/widgets/how.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/transaction_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/person_card.dart';
import 'add_expense_screen.dart';
import 'admin_person_detail_screen.dart'; // Import Detail Screen
import 'admin_global_history_screen.dart';
import 'dart:math';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _showAddPersonDialog(BuildContext context, String adminEmail) {
    final nameController = TextEditingController();

    // final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Person'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              textCapitalization: TextCapitalization.words,
            ),
            // TextField(
            //   controller: phoneController,
            //   decoration: const InputDecoration(labelText: 'Phone Number'),
            //   textCapitalization: TextCapitalization.words,
            // ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final navigator = Navigator.of(context);
                final fs = context.read<FirestoreService>();

                String id = '';
                bool exists = true;
                while (exists) {
                  id = (Random().nextInt(900000) + 100000).toString();
                  exists = await fs.checkPersonIdExists(adminEmail, id);
                }

                final newPerson = PersonModel(
                  id: id,
                  // phone: phoneController.text.trim(),
                  name: nameController.text.trim(),
                  totalCash: 0,
                  totalExpense: 0,
                  createdAt: DateTime.now(),
                  adminEmail: adminEmail,
                );

                await fs.addPerson(adminEmail, newPerson);
                navigator.pop(); // Close Dialog
                // Note: Drawer remains open or we can close it too?
                // Usually Dialogs are on top.
                if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                  Navigator.pop(context); // Close Drawer
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddCashDialog(BuildContext context, String adminEmail) {
    // Prevent multiple dialogs by checking if one is already open
    if (ModalRoute.of(context)?.isCurrent != true) return;

    bool isLoading = true; // Local loading state for this dialog

    showDialog(
      context: context,
      barrierDismissible:
          false, // User can't dismiss by tapping outside while loading
      builder: (dialogContext) {
        return StreamBuilder<List<PersonModel>>(
          stream: FirestoreService().getPersons(adminEmail),
          builder: (context, snapshot) {
            // Agar data nahi aaya abhi tak
            if (!snapshot.hasData ||
                snapshot.connectionState == ConnectionState.waiting) {
              return AlertDialog(
                content: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(child: const CircularProgressIndicator()),
                    const SizedBox(width: 20),
                    Text("Loading members..."),
                  ],
                ),
              );
            }

            // Data aa gaya
            final persons = snapshot.data!;

            if (persons.isEmpty) {
              return AlertDialog(
                title: const Text('No Members'),
                content: const Text(
                  'No members found. Please add a person first.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('OK'),
                  ),
                ],
              );
            }

            return SimpleDialog(
              title: const Text('Select Person to Add Cash'),
              children: persons.map((p) {
                return SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    ); // Close person selection dialog
                    _showCashAmountDialog(
                      context,
                      adminEmail,
                      p,
                    ); // Open amount dialog
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 8.0,
                    ),
                    child: Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  void _showCashAmountDialog(
    BuildContext context,
    String adminEmail,
    PersonModel person,
  ) {
    final titleController = TextEditingController(text: 'Cash Added');
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Cash for ${person.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title (e.g. Salary, Loan)',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixIcon: Icon(Icons.money),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (amountController.text.isNotEmpty &&
                  titleController.text.isNotEmpty) {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount > 0) {
                  try {
                    final transaction = TransactionModel(
                      id:
                          (DateTime.now().millisecondsSinceEpoch +
                                  Random().nextInt(1000))
                              .toString(),
                      title: titleController.text.trim(),
                      amount: amount,
                      type: TransactionType.cash,
                      date: DateTime.now(),
                      involvedUserIds: [person.id],
                      adminEmail: adminEmail,
                    );

                    await context.read<FirestoreService>().addTransaction(
                      transaction,
                    );
                    if (context.mounted)
                      Navigator.pop(context); // Close Amount Dialog
                    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                      Navigator.pop(context); // Close Drawer if open
                    }
                  } catch (e) {
                    if (context.mounted)
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: const Text('Add Cash'),
            ),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    LocalStorageService().clear();
    context.read<AuthService>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    if (user == null || user.email == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final adminEmail = user.email!;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: StreamBuilder<AdminModel?>(
          stream: FirestoreService().getAdminProfile(adminEmail),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(snapshot.data?.khataName ?? 'Kharcha Manager');
            }
            return const Text('Kharcha Manager');
          },
        ),
        actions: [
          ElevatedButton(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: const Text('Add Cash'),
            ),
            onPressed: () {
              _showAddCashDialog(context, adminEmail);
            },
          ),
          SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 48,
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Admin',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.person_add,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Add User'),
              onTap: () => _showAddPersonDialog(context, adminEmail),
            ),

            ListTile(
              leading: Icon(
                Icons.group,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Global History'),
              onTap: () {
                Navigator.pop(context); // Close Drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AdminGlobalHistoryScreen(adminEmail: adminEmail),
                  ),
                );
              },
            ),
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
                        content: Text('Could not open Google Drive folder'),
                      ),
                    );
                  }
                }
              },
            ),

            ListTile(
              leading: Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('About Developer'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutDeveloperPage()),
                );
              },
            ),

            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<PersonModel>>(
        stream: FirestoreService().getPersons(adminEmail),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No members yet. Use Drawer to Add!'),
                ],
              ),
            );
          }

          final persons = snapshot.data!;

          return StreamBuilder<List<TransactionModel>>(
            stream: FirestoreService().getAllTransactions(adminEmail),
            builder: (context, txSnapshot) {
              if (txSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final transactions = txSnapshot.data ?? [];

              // GLOBAL TOTALS CALCULATION (Group expense counted per user)
              double globalTotalExpense = 0;
              double globalTotalCash = 0;

              for (var tx in transactions) {
                if (tx.type == TransactionType.cash) {
                  globalTotalCash += tx.amount;
                } else {
                  // Expense: multiply by number of involved users (group expense fix)
                  int userCount = tx.involvedUserIds.length;
                  globalTotalExpense += tx.amount * userCount;
                }
              }

              final globalRemaining = globalTotalCash - globalTotalExpense;

              // Sort persons by remaining amount (highest first)
              persons.sort((a, b) {
                final remainA = a.totalCash - a.totalExpense;
                final remainB = b.totalCash - b.totalExpense;
                return remainB.compareTo(remainA);
              });

              return Column(
                children: [
                  // TOP: 3 Summary Cards using your _buildSummaryCard
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            context,
                            'Total Expense',
                            globalTotalExpense,
                            AppTheme.expenseColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSummaryCard(
                            context,
                            'Total Cash',
                            globalTotalCash,
                            AppTheme.cashColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSummaryCard(
                            context,
                            'Total Remains',
                            globalRemaining,
                            globalRemaining >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // BOTTOM: List of all users' individual cards
                  Expanded(
                    child: ListView.builder(
                      itemCount: persons.length,
                      itemBuilder: (context, index) {
                        final person = persons[index];
                        return PersonCard(
                          person: person,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminPersonDetailScreen(
                                  person: person,
                                  adminEmail: adminEmail,
                                ),
                              ),
                            );
                          },
                          onLongPress: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete User?'),
                                content: Text(
                                  'Are you sure you want to delete ${person.name}? This cannot be undone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () async {
                                      await context
                                          .read<FirestoreService>()
                                          .deletePerson(adminEmail, person.id);
                                      if (context.mounted)
                                        Navigator.pop(context);
                                    },
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                          onAddCash: () => _showCashAmountDialog(
                            context,
                            adminEmail,
                            person,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddExpenseScreen(adminEmail: adminEmail),
            ),
          );
        },
        child: const Icon(Icons.receipt_long),
        backgroundColor: Colors.red.withOpacity(0.4),
        foregroundColor: Colors.white,
      ),
    );
  }

  // Widget _buildSummaryCard(
  //   BuildContext context,
  //   String title,
  //   double amount,
  //   Color color,
  // ) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: [
  //         BoxShadow(
  //           color: color.withOpacity(0.2),
  //           blurRadius: 4,
  //           offset: const Offset(0, 2),
  //         ),
  //       ],
  //       border: Border.all(color: color.withOpacity(0.3)),
  //     ),
  //     child: Column(
  //       children: [
  //         Text(
  //           title,
  //           style: TextStyle(
  //             fontSize: 12,
  //             fontWeight: FontWeight.bold,
  //             color: Colors.grey[700],
  //           ),
  //           textAlign: TextAlign.center,
  //         ),
  //         const SizedBox(height: 8),
  //         FittedBox(
  //           child: Text(
  //             NumberFormat.compactSimpleCurrency(
  //               name: '',
  //               decimalDigits: 0,
  //             ).format(amount.abs()),
  //             style: TextStyle(
  //               fontSize: 18,
  //               fontWeight: FontWeight.bold,
  //               color: color,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    double amount,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              NumberFormat.compactSimpleCurrency(
                name: '',
                decimalDigits: 0,
              ).format(amount.abs()),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
