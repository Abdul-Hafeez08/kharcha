import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user_model.dart';
import '../../utils/theme.dart';
import 'package:intl/intl.dart';

class PersonCard extends StatelessWidget {
  final PersonModel person;
  final VoidCallback onTap;
  final VoidCallback onLongPress; // Add this
  final VoidCallback onAddCash;

  const PersonCard({
    super.key,
    required this.person,
    required this.onTap,
    required this.onLongPress, // Add this
    required this.onAddCash,
  });

  @override
  Widget build(BuildContext context) {
    final double remaining = person.totalCash - person.totalExpense;
    final currencyFormat = NumberFormat.simpleCurrency(
      name: '',
      decimalDigits: 0,
    ); // Assuming PKR or generic

    final bool isOverBudget = person.totalExpense > person.totalCash;

    return Card(
      color: isOverBudget ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
      elevation: 4, // Flat look with border is deeper/cleaner
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isOverBudget
              ? const Color(0xFFEF9A9A) // Red 200
              : Colors.green.withOpacity(0.2),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress, // Use it
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    person.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  InkWell(
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(
                          text:
                              'User ID ${person.id} \n\n Download the app to use it!\nhttps://drive.google.com/drive/folders/1bREgHafHTS5IK9HvqiKKRuSHSBlpRMCo?usp=sharing',
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('ID copied ${person.id} '),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ID:',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.copy, size: 18, color: Colors.blue),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStat(
                    'Expenses',
                    person.totalExpense,
                    AppTheme.expenseColor,
                    context,
                  ),
                  _buildStat(
                    'Cash',
                    person.totalCash,
                    AppTheme.cashColor,
                    context,
                  ),
                  _buildStat(
                    'Remain',
                    remaining,
                    remaining >= 0 ? Colors.green : Colors.red,
                    context,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(
    String label,
    double amount,
    Color color,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: Colors.black),
        ),
        const SizedBox(height: 4),
        Text(
          amount.abs().toStringAsFixed(0),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
