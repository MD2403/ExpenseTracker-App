import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../utils/toast_helper.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({
    super.key,
    required this.onAddExpense,
    this.expenseToEdit,        // optional — only passed when editing
    this.onEditExpense,        // optional — only passed when editing
  });

  final void Function(Expense expense) onAddExpense;
  final Expense? expenseToEdit;                          // null = adding, not null = editing
  final void Function(Expense expense)? onEditExpense;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  DateTime? _selectedDate;
  Category _selectedCategory = Category.food;

  @override
  void initState() {
    super.initState();

    // If editing, pre-fill the form with existing expense data
    if (widget.expenseToEdit != null) {
      final e = widget.expenseToEdit!;
      _titleController  = TextEditingController(text: e.title);
      _amountController = TextEditingController(text: e.amount.toString());
      _selectedDate     = e.date;
      _selectedCategory = e.category;
    } else {
      // Adding new — start empty
      _titleController  = TextEditingController();
      _amountController = TextEditingController();
    }
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submitExpense() {
    final amount = double.tryParse(_amountController.text);
    final titleIsInvalid  = _titleController.text.trim().isEmpty;
    final amountIsInvalid = amount == null || amount <= 0;
    final dateIsInvalid   = _selectedDate == null;

    if (titleIsInvalid || amountIsInvalid || dateIsInvalid) {
        ToastHelper.error('Please fill all fields correctly');
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Invalid input'),
          content: const Text('Please enter a valid title, amount, and date.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Build the updated/new expense
    final expense = Expense(
      id: widget.expenseToEdit?.id,   // keep same ID if editing
      title: _titleController.text.trim(),
      amount: amount,
      date: _selectedDate!,
      category: _selectedCategory,
    );

    if (widget.expenseToEdit != null) {
      widget.onEditExpense!(expense);  // editing
    } else {
      widget.onAddExpense(expense);    // adding new
    }

    ToastHelper.success(
  _isEditing ? 'Expense updated!' : 'Expense added!'
);
Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // Are we editing or adding?
  bool get _isEditing => widget.expenseToEdit != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16, 16, 16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header changes based on add vs edit
          Text(
            _isEditing ? 'Edit Expense' : 'Add Expense',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Title field
          TextField(
            controller: _titleController,
            maxLength: 50,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // Amount field
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount (₹)',
              prefixText: '₹ ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Date picker
          Row(
            children: [
              Text(
                _selectedDate == null
                    ? 'No date selected'
                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                style: const TextStyle(fontSize: 15),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month),
                label: const Text('Pick Date'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Category dropdown
          DropdownButtonFormField<Category>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
items: Category.values.map((cat) {
  return DropdownMenuItem(
    value: cat,
    child: Row(
      children: [
        Icon(categoryIcons[cat],
            size: 20, color: categoryColors[cat]),
        const SizedBox(width: 8),
        Text(categoryNames[cat] ?? cat.name),
      ],
    ),
  );
}).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedCategory = value);
            },
          ),
          const SizedBox(height: 20),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _submitExpense,
                child: Text(_isEditing ? 'Save Changes' : 'Add Expense'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}