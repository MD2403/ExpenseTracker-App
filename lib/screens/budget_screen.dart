import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../utils/toast_helper.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key, required this.onBudgetSaved});

  final void Function(double budget) onBudgetSaved;

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _budgetController = TextEditingController();
  double _currentBudget   = 0;

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  void _loadBudget() async {
    final budget = await FirestoreService.instance.getBudget();
    setState(() {
      _currentBudget = budget;
      _budgetController.text =
          budget > 0 ? budget.toStringAsFixed(0) : '';
    });
  }

  void _saveBudget() async {
    final amount = double.tryParse(_budgetController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid budget amount'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    await FirestoreService.instance.saveBudget(amount);
    ToastHelper.success('Budget set to ₹${amount.toStringAsFixed(0)}'); 
    widget.onBudgetSaved(amount);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16, 24, 16,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Set Monthly Budget',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'You will get a warning when you reach 80% of your budget.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Monthly Budget (₹)',
              prefixText: '₹ ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveBudget,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save Budget',
                  style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}