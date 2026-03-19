import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';
import 'add_expense_screen.dart';
import 'chart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _box = Hive.box('expenses');
  List<Expense> _expenses = [];

  @override
  void initState() {
    super.initState();
    _loadExpenses(); // load saved expenses when app opens
  }

  // Read from Hive box
  void _loadExpenses() {
    final data = _box.values.toList();
    setState(() {
      _expenses = data.map((e) => Expense.fromMap(e)).toList();
    });
  }

  // Save new expense to Hive
  void _addExpense(Expense expense) {
    _box.put(expense.id, expense.toMap());
    setState(() {
      _expenses.add(expense);
    });
  }

  // Delete expense from Hive
  void _removeExpense(int index) {
    final expense = _expenses[index];
    _box.delete(expense.id);
    setState(() {
      _expenses.removeAt(index);
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${expense.title} deleted'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  double get _totalExpenses =>
      _expenses.fold(0, (sum, e) => sum + e.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => ChartScreen(expenses: _expenses),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Total banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Spent',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  '₹${_totalExpenses.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Expense list
          Expanded(
            child: _expenses.isEmpty
                ? const Center(child: Text('No expenses yet. Add one!'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _expenses.length,
                    itemBuilder: (ctx, index) {
                      final expense = _expenses[index];
                      return Dismissible(
                        key: ValueKey(expense.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        onDismissed: (_) => _removeExpense(index),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: categoryColors[expense.category],
                              child: Icon(
                                categoryIcons[expense.category],
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(expense.title),
                            subtitle: Text(
                              '${expense.category.name} · ${expense.formattedDate}',
                            ),
                            trailing: Text(
                              '₹${expense.amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (ctx) => AddExpenseScreen(
              onAddExpense: _addExpense,
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}