import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import 'package:intl/intl.dart';

class AdminGlobalHistoryScreen extends StatelessWidget {
  final String adminEmail;

  const AdminGlobalHistoryScreen({super.key, required this.adminEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Global History'), elevation: 0),
      body: StreamBuilder<List<PersonModel>>(
        stream: FirestoreService().getPersons(adminEmail),
        builder: (context, personSnap) {
          if (!personSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final persons = personSnap.data!;
          final personMap = {for (var p in persons) p.id: p.name};

          return StreamBuilder<List<TransactionModel>>(
            stream: FirestoreService().getAllTransactions(adminEmail),
            builder: (context, txSnap) {
              if (txSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!txSnap.hasData || txSnap.data!.isEmpty) {
                return const Center(child: Text('No transactions found'));
              }

              final transactions = txSnap.data!;

              // FIXED: Correct Total Calculation
              double totalExpense = 0;
              double totalCash = 0;

              for (var tx in transactions) {
                if (tx.type == TransactionType.expense) {
                  // Group expense: count amount × number of involved users
                  int userCount = tx.involvedUserIds.length;
                  totalExpense += tx.amount * userCount;
                } else {
                  // Cash: add normally (usually 1 user)
                  totalCash += tx.amount;
                }
              }
              final totalRemaining = totalCash - totalExpense;

              return Column(
                children: [
                  // Top Summary Cards (Now showing correct totals)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            context,
                            'Total Expense',
                            totalExpense,
                            AppTheme.expenseColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSummaryCard(
                            context,
                            'Total Cash',
                            totalCash,
                            AppTheme.cashColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSummaryCard(
                            context,
                            'Remains',
                            totalRemaining,
                            totalRemaining >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Transaction List with ALL involved persons in subtitle
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        final isExpense = tx.type == TransactionType.expense;

                        // Get ALL involved person names
                        final involvedNames = tx.involvedUserIds
                            .map((id) => personMap[id] ?? 'Unknown')
                            .join(', ');

                        // Fallback if empty
                        final subtitle = involvedNames.isEmpty
                            ? 'Unknown'
                            : involvedNames;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                // Icon
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        (isExpense
                                                ? AppTheme.expenseColor
                                                : AppTheme.cashColor)
                                            .withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isExpense
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: isExpense
                                        ? AppTheme.expenseColor
                                        : AppTheme.cashColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Content: Title + All Persons
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        subtitle,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),

                                // Amount & Date
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      // Show actual stored amount (per person if split)
                                      NumberFormat.simpleCurrency(
                                        name: '',
                                        decimalDigits: 0,
                                      ).format(tx.amount),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isExpense
                                            ? AppTheme.expenseColor
                                            : AppTheme.cashColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat(
                                        'MMM d, h:mm a',
                                      ).format(tx.date),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
    );
  }

  // Yeh method same rakha hai
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
