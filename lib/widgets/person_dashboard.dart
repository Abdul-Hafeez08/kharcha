import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';
import '../utils/theme.dart';
import 'package:intl/intl.dart';

class PersonDashboard extends StatelessWidget {
  final PersonModel person;
  final String adminEmail;
  final bool isAdmin; // Added flag

  const PersonDashboard({
    super.key,
    required this.person,
    required this.adminEmail,
    this.isAdmin = false,
  });

  void _showEditTransactionDialog(BuildContext context, TransactionModel tx) {
    final titleController = TextEditingController(text: tx.title);
    final amountController = TextEditingController(
      text: tx.amount.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
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
              final newAmount = double.tryParse(amountController.text);
              if (newAmount != null &&
                  newAmount > 0 &&
                  titleController.text.isNotEmpty) {
                final newTx = TransactionModel(
                  id: tx.id,
                  title: titleController.text.trim(),
                  amount: newAmount,
                  type: tx
                      .type, // Changing type is complex, let's keep it fixed for now
                  date: tx.date,
                  involvedUserIds: tx.involvedUserIds,
                  adminEmail: tx.adminEmail,
                );

                await context.read<FirestoreService>().updateTransaction(
                  tx,
                  newTx,
                );
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteTransactionDialog(BuildContext context, TransactionModel tx) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: Text(
          'Delete "${tx.title}" of ${NumberFormat.simpleCurrency(name: 'Rs', decimalDigits: 0).format(tx.amount)}? This will reverse the balance effect.',
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
              await context.read<FirestoreService>().deleteTransaction(tx);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PersonModel?>(
      stream: FirestoreService().getPerson(adminEmail, person.id),
      initialData: person,
      builder: (context, personSnap) {
        if (!personSnap.hasData)
          return const Center(child: CircularProgressIndicator());
        final currentPerson = personSnap.data!;
        final remaining = currentPerson.totalCash - currentPerson.totalExpense;

        return Column(
          children: [
            // Stats Cards
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      'Expense',
                      currentPerson.totalExpense,
                      AppTheme.expenseColor,
                      context,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoCard(
                      'Cash',
                      currentPerson.totalCash,
                      AppTheme.cashColor,
                      context,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoCard(
                      'Remain',
                      remaining,
                      remaining >= 0 ? Colors.green : Colors.red,
                      context,
                    ),
                  ),
                ],
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "History",
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Transaction List
            Expanded(
              child: StreamBuilder<List<TransactionModel>>(
                stream: FirestoreService().getPersonTransactions(
                  adminEmail,
                  currentPerson.id,
                ),
                builder: (context, txSnap) {
                  if (txSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!txSnap.hasData || txSnap.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 48,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No transactions yet.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  final transactions = txSnap.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      final isExpense = tx.type == TransactionType.expense;
                      final color = isExpense
                          ? AppTheme.expenseColor
                          : AppTheme.cashColor;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: isAdmin
                              ? () => _showEditTransactionDialog(context, tx)
                              : null,
                          onLongPress: isAdmin
                              ? () => _showDeleteTransactionDialog(context, tx)
                              : null,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                // Icon
                                // Container(
                                //   padding: const EdgeInsets.all(8),
                                //   decoration: BoxDecoration(
                                //     color: color.withOpacity(0.1),
                                //     shape: BoxShape.circle,
                                //   ),
                                //   child: Icon(
                                //     isExpense
                                //         ? Icons.arrow_downward
                                //         : Icons.arrow_upward,
                                //     color: color,
                                //     size: 20,
                                //   ),
                                // ),
                                // const SizedBox(width: 12),
                                // Content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                        ),
                                      ),
                                      Text(
                                        DateFormat(
                                          'MMM d, h:mm a',
                                        ).format(tx.date),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Amount & Date
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      NumberFormat.simpleCurrency(
                                        name: '',
                                        decimalDigits: 0,
                                      ).format(tx.amount),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoCard(
    String title,
    double amount,
    Color color,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 5.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            FittedBox(
              child: Text(
                // Format: Rs 1,000
                NumberFormat.compactSimpleCurrency(
                  name: '',
                  decimalDigits: 0,
                ).format(amount.abs()),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
