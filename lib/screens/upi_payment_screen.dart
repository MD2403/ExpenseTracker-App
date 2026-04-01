import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/firestore_service.dart';
import '../services/upi_service.dart';
import '../utils/toast_helper.dart';
import 'qr_scanner_screen.dart';

class UpiPaymentScreen extends StatefulWidget {
  const UpiPaymentScreen({
    super.key,
    required this.onExpenseAdded,
  });

  final void Function(Expense expense) onExpenseAdded;

  @override
  State<UpiPaymentScreen> createState() => _UpiPaymentScreenState();
}

class _UpiPaymentScreenState extends State<UpiPaymentScreen> {
  final _upiIdController  = TextEditingController();
  final _nameController   = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController   = TextEditingController();
  Category _selectedCategory = Category.food;
  DateTime _selectedDate     = DateTime.now();
  bool _isLaunching          = false;
  bool _paymentLaunched      = false;

  @override
  void dispose() {
    _upiIdController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _launchPayment() async {
    // Validate fields
    if (_upiIdController.text.trim().isEmpty) {
      ToastHelper.error('Please enter UPI ID or scan QR code');
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      ToastHelper.error('Please enter payee name');
      return;
    }
    if (_amountController.text.trim().isEmpty) {
      ToastHelper.error('Please enter amount');
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ToastHelper.error('Please enter a valid amount');
      return;
    }

    setState(() => _isLaunching = true);
    ToastHelper.info('Opening UPI app...');

    final launched = await UpiService.launchUpiPayment(
      upiId: _upiIdController.text.trim(),
      payeeName: _nameController.text.trim(),
      amount: amount,
      transactionNote: _noteController.text.trim().isEmpty
          ? 'Expense payment'
          : _noteController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isLaunching      = false;
        _paymentLaunched  = launched;
      });
    }

    if (!launched && mounted) {
      ToastHelper.error(
          'No UPI app found. Install Google Pay or PhonePe');
    }
  }

  Future<void> _confirmAndSaveExpense() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null) return;

    // Confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm payment'),
        content: Text(
          'Save ₹${amount.toStringAsFixed(0)} payment to '
          '${_nameController.text.trim()} as an expense?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, save'),
          ),
        ],
      ),
    );

    // Only save if user confirmed
    if (confirm != true) {
      ToastHelper.info('Payment not saved');
      return;
    }

    final expense = Expense(
      title: _noteController.text.trim().isEmpty
          ? 'UPI Payment to ${_nameController.text.trim()}'
          : _noteController.text.trim(),
      amount: amount,
      date: _selectedDate,
      category: _selectedCategory,
    );

    await FirestoreService.instance.addExpense(expense);
    widget.onExpenseAdded(expense);

    ToastHelper.success(
        '₹${amount.toStringAsFixed(0)} expense saved!');

    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      ToastHelper.info(
          'Date set to ${picked.day}/${picked.month}/${picked.year}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        title: const Text('Pay via UPI',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_paymentLaunched) {
              ToastHelper.warning(
                  'Payment not confirmed — expense not saved');
            }
            setState(() => _paymentLaunched = false);
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color:
                        const Color(0xFF6C63FF).withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Color(0xFF6C63FF), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Fill the details, pay via UPI app, '
                      'then confirm to save the expense.',
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6C63FF)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Payment details',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),

            // UPI ID + QR scan button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _upiIdController,
                    decoration: InputDecoration(
                      labelText: 'UPI ID',
                      hintText: 'e.g. merchant@paytm',
                      prefixIcon:
                          const Icon(Icons.account_balance),
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.qr_code_scanner,
                        color: Colors.white),
                    tooltip: 'Scan QR code',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QrScannerScreen(
                            onScanned: (upiId, name) {
                              setState(() {
                                _upiIdController.text = upiId;
                                if (name != null &&
                                    _nameController
                                        .text.isEmpty) {
                                  _nameController.text = name;
                                }
                              });
                              ToastHelper.success(
                                  'QR scanned! UPI ID filled automatically');
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Payee name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Payee name',
                hintText: 'e.g. Swiggy, Petrol pump',
                prefixIcon: const Icon(Icons.person_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            // Amount
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (₹)',
                prefixText: '₹ ',
                prefixIcon: const Icon(Icons.currency_rupee),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            // Note
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. Dinner, Fuel',
                prefixIcon: const Icon(Icons.note_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<Category>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
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
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedCategory = val);
                  ToastHelper.info(
                      'Category: ${categoryNames[val] ?? val.name}');
                }
              },
            ),
            const SizedBox(height: 12),

            // Date picker
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: scheme.onSurface.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month,
                        color: scheme.onSurface.withOpacity(0.6),
                        size: 20),
                    const SizedBox(width: 12),
                    Text(
                      '${_selectedDate.day}/'
                      '${_selectedDate.month}/'
                      '${_selectedDate.year}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Spacer(),
                    Text('Change',
                        style: TextStyle(
                            color: scheme.primary,
                            fontSize: 13)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Pay button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLaunching ? null : _launchPayment,
                icon: _isLaunching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white))
                    : const Icon(Icons.payment),
                label: Text(
                  _isLaunching
                      ? 'Opening UPI app...'
                      : 'Pay via UPI',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            // Confirm section — shows after UPI app opened
            if (_paymentLaunched) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text('Did the payment go through?',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'If payment was successful, tap '
                      '"Yes, save expense" to add it to tracker.',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() =>
                                  _paymentLaunched = false);
                              ToastHelper.error(
                                  'Payment marked as failed');
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Colors.red),
                              foregroundColor: Colors.red,
                              padding:
                                  const EdgeInsets.symmetric(
                                      vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10)),
                            ),
                            child: const Text('No, failed'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _confirmAndSaveExpense,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(
                                      vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10)),
                            ),
                            child:
                                const Text('Yes, save expense'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}