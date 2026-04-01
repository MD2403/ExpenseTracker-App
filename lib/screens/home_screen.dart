import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../providers/theme_provider.dart';
import '../services/firestore_service.dart';
import '../services/csv_export.dart';
import '../utils/toast_helper.dart';
import 'add_expense_screen.dart';
import 'budget_screen.dart';
import 'chart_screen.dart';
import 'groups_screen.dart';
import 'settings_screen.dart';
import 'upi_payment_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _monthlyBudget  = 0;
  int _selectedMonth     = DateTime.now().month;
  int _selectedYear      = DateTime.now().year;
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadBudget();
    _saveUserEmail();
    ThemeProvider.instance.addListener(_onThemeChanged);
  }

  void _onThemeChanged() => setState(() {});

  @override
  void dispose() {
    ThemeProvider.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _loadBudget() async {
    final budget = await FirestoreService.instance.getBudget();
    setState(() => _monthlyBudget = budget);
  }

  void _saveUserEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    if (data == null || data['displayName'] == null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'uid':         user.uid,
        'email':       user.email ?? '',
        'displayName': user.email?.split('@')[0] ?? 'User',
      }, SetOptions(merge: true));
    }
  }

  List<Expense> _filterExpenses(List<Expense> expenses) {
    return expenses.where((e) {
      final matchesMonth =
          e.date.month == _selectedMonth &&
          e.date.year == _selectedYear;
      final matchesCategory =
          _selectedCategory == null ||
          e.category == _selectedCategory;
      return matchesMonth && matchesCategory;
    }).toList();
  }

  double _getTotal(List<Expense> expenses) =>
      expenses.fold(0, (sum, e) => sum + e.amount);

  double _getBudgetProgress(double total) =>
      _monthlyBudget <= 0
          ? 0
          : (total / _monthlyBudget).clamp(0.0, 1.0);

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.red;
    if (progress >= 0.8) return Colors.orange;
    return Colors.green;
  }

  void _checkBudgetAlert(double total) {
    if (_monthlyBudget <= 0) return;
    final ratio = total / _monthlyBudget;
    if (ratio >= 1.0) {
      _showBudgetDialog(
        title: '🚨 Budget Exceeded!',
        message:
            'You have exceeded your monthly budget of ₹${_monthlyBudget.toStringAsFixed(0)}.',
        color: Colors.red,
      );
    } else if (ratio >= 0.8) {
      _showBudgetDialog(
        title: '⚠️ Budget Warning',
        message:
            'You have used ${(ratio * 100).toStringAsFixed(0)}% of your budget.',
        color: Colors.orange,
      );
    }
  }

  void _showBudgetDialog({
    required String title,
    required String message,
    required Color color,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  // Build background based on user preference
  Widget _buildBackground(Widget child) {
    final themeProvider = ThemeProvider.instance;
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final accent = themeProvider.accentColor;
    final scheme = Theme.of(context).colorScheme;

    switch (themeProvider.background) {
      case AppBackground.gradient:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withOpacity(isDark ? 0.15 : 0.05),
                scheme.surface,
                scheme.surface,
              ],
            ),
          ),
          child: child,
        );
      case AppBackground.mesh:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withOpacity(0.1),
                Colors.blue.withOpacity(0.05),
                Colors.pink.withOpacity(0.05),
              ],
            ),
          ),
          child: child,
        );
      case AppBackground.solid:
      default:
        return child;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.instance;
    final scheme  = Theme.of(context).colorScheme;
    final accent  = themeProvider.accentColor;
    final isDark  =
        Theme.of(context).brightness == Brightness.dark;
    final cardRadius = themeProvider.cardRadius;
    final fontScale  = themeProvider.fontScale;

    // Card color based on theme
    final cardColor = isDark
        ? const Color(0xFF111120)
        : const Color(0xFFF5F5F5);

    return _buildBackground(
      Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            'MyKharcha',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22 * fontScale,
            ),
          ),
          actions: [
            // UPI Payment
            IconButton(
              icon: const Icon(Icons.currency_rupee),
              tooltip: 'Pay via UPI',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UpiPaymentScreen(
                    onExpenseAdded: (_) {},
                  ),
                ),
              ),
            ),
            // Groups
            IconButton(
              icon: const Icon(Icons.group),
              tooltip: 'Groups',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const GroupsScreen()),
              ),
            ),
            // Export
            IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: 'Export',
              onPressed: () async {
                showModalBottomSheet(
                  context: context,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(cardRadius)),
                  ),
                  builder: (ctx) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text('Export Expenses',
                            style: TextStyle(
                                fontSize: 18 * fontScale,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                            'Choose how you want to export',
                            style: TextStyle(
                                fontSize: 13 * fontScale,
                                color: Colors.grey)),
                        const SizedBox(height: 20),
                        ListTile(
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                          tileColor: scheme.onSurface
                              .withOpacity(0.05),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.green
                                  .withOpacity(0.15),
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.save_alt,
                                color: Colors.green),
                          ),
                          title: Text('Save to Downloads',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14 * fontScale)),
                          subtitle: Text(
                              'Save CSV file to Downloads',
                              style: TextStyle(
                                  fontSize: 12 * fontScale)),
                          onTap: () async {
                            Navigator.pop(ctx);
                            try {
                              final expenses =
                                  await FirestoreService
                                      .instance
                                      .getExpensesStream()
                                      .first;
                              await CsvExport.saveToDownloads(
                                  _filterExpenses(expenses));
                              ToastHelper.success(
                                  'Saved to Downloads!');
                            } catch (e) {
                              ToastHelper.error('Error: $e');
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                          tileColor: scheme.onSurface
                              .withOpacity(0.05),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color:
                                  Colors.blue.withOpacity(0.15),
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.share,
                                color: Colors.blue),
                          ),
                          title: Text('Share',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14 * fontScale)),
                          subtitle: Text(
                              'Share via WhatsApp, Gmail etc.',
                              style: TextStyle(
                                  fontSize: 12 * fontScale)),
                          onTap: () async {
                            Navigator.pop(ctx);
                            final expenses =
                                await FirestoreService.instance
                                    .getExpensesStream()
                                    .first;
                            await CsvExport.shareExpenses(
                                _filterExpenses(expenses));
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Budget
            IconButton(
              icon: const Icon(Icons.savings_outlined),
              tooltip: 'Set Budget',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(cardRadius)),
                  ),
                  builder: (ctx) => BudgetScreen(
                    onBudgetSaved: (budget) {
                      setState(() => _monthlyBudget = budget);
                    },
                  ),
                );
              },
            ),
            // Settings
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'Appearance',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SettingsScreen()),
              ),
            ),
            // Charts
            IconButton(
              icon: const Icon(Icons.bar_chart_rounded),
              onPressed: () async {
                final expenses = await FirestoreService.instance
                    .getExpensesStream()
                    .first;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) =>
                        ChartScreen(expenses: expenses),
                  ),
                );
              },
            ),
            // Logout
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                ToastHelper.info('Logged out successfully');
              },
            ),
          ],
        ),
        body: StreamBuilder<List<Expense>>(
          stream: FirestoreService.instance.getExpensesStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text('Error: ${snapshot.error}'));
            }

            final allExpenses = snapshot.data ?? [];
            final filtered   = _filterExpenses(allExpenses);
            final total      = _getTotal(filtered);
            final progress   = _getBudgetProgress(total);

            return Column(
              children: [
                // ── Total banner ──────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      16, 8, 16, 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent,
                          accent.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          BorderRadius.circular(cardRadius),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                                Icons.account_balance_wallet,
                                color: Colors.white70,
                                size: 18),
                            const SizedBox(width: 6),
                            Text(
                              '${_months[_selectedMonth - 1]} $_selectedYear',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14 * fontScale),
                            ),
                            const Spacer(),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withOpacity(0.2),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${filtered.length} expenses',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12 * fontScale),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '₹${total.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36 * fontScale,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (_monthlyBudget > 0) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Budget: ₹${_monthlyBudget.toStringAsFixed(0)}',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12 * fontScale),
                              ),
                              Text(
                                '${(progress * 100).toStringAsFixed(0)}% used',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12 * fontScale),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: Colors.white
                                  .withOpacity(0.2),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                      _getProgressColor(
                                          progress)),
                            ),
                          ),
                          if (progress >= 0.8)
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 6),
                              child: Text(
                                progress >= 1.0
                                    ? '🚨 Budget exceeded!'
                                    : '⚠️ Approaching budget limit',
                                style: TextStyle(
                                  color: progress >= 1.0
                                      ? Colors.red[200]
                                      : Colors.orange[200],
                                  fontSize: 12 * fontScale,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── Month selector ────────────────────
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12),
                    itemCount: 12,
                    itemBuilder: (ctx, i) {
                      final isSelected =
                          (i + 1) == _selectedMonth;
                      return GestureDetector(
                        onTap: () => setState(
                            () => _selectedMonth = i + 1),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accent
                                : scheme.onSurface
                                    .withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: Text(
                            _months[i],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : scheme.onSurface
                                      .withOpacity(0.6),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13 * fontScale,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // ── Category chips ────────────────────
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4),
                        child: ChoiceChip(
                          label: Text('All',
                              style: TextStyle(
                                  fontSize: 13 * fontScale)),
                          selected: _selectedCategory == null,
                          showCheckmark: false,
                          selectedColor: accent,
                          labelStyle: TextStyle(
                            color: _selectedCategory == null
                                ? Colors.white
                                : scheme.onSurface,
                          ),
                          onSelected: (_) => setState(
                              () => _selectedCategory = null),
                        ),
                      ),
                      ...Category.values.map((cat) => Padding(
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 4),
                            child: ChoiceChip(
                              avatar: Icon(categoryIcons[cat],
                                  size: 16,
                                  color:
                                      _selectedCategory == cat
                                          ? Colors.white
                                          : categoryColors[cat]),
                              label: Text(
                                  categoryNames[cat] ?? cat.name,
                                  style: TextStyle(
                                      fontSize:
                                          12 * fontScale)),
                              selected: _selectedCategory == cat,
                              selectedColor: accent,
                              showCheckmark: false,
                              labelStyle: TextStyle(
                                color: _selectedCategory == cat
                                    ? Colors.white
                                    : scheme.onSurface,
                              ),
                              onSelected: (_) => setState(() =>
                                  _selectedCategory =
                                      _selectedCategory == cat
                                          ? null
                                          : cat),
                            ),
                          )),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ── Section header ────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        'Expenses',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16 * fontScale,
                          color: scheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedCategory != null)
                        TextButton(
                          onPressed: () => setState(
                              () => _selectedCategory = null),
                          child: Text('Clear filter',
                              style: TextStyle(
                                  fontSize: 13 * fontScale,
                                  color: accent)),
                        ),
                    ],
                  ),
                ),

                // ── Expense list ──────────────────────
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.receipt_long,
                                  size: 64,
                                  color: scheme.onSurface
                                      .withOpacity(0.2)),
                              const SizedBox(height: 12),
                              Text(
                                'No expenses for this period',
                                style: TextStyle(
                                  color: scheme.onSurface
                                      .withOpacity(0.4),
                                  fontSize: 16 * fontScale,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, index) {
                            final expense = filtered[index];
                            return Dismissible(
                              key: ValueKey(expense.id),
                              direction:
                                  DismissDirection.endToStart,
                              background: Container(
                                margin: const EdgeInsets.only(
                                    bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade400,
                                  borderRadius:
                                      BorderRadius.circular(
                                          cardRadius),
                                ),
                                alignment:
                                    Alignment.centerRight,
                                padding: const EdgeInsets.only(
                                    right: 20),
                                child: const Icon(
                                    Icons.delete_rounded,
                                    color: Colors.white,
                                    size: 26),
                              ),
                              confirmDismiss: (_) async {
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape:
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                              cardRadius),
                                    ),
                                    title: const Text(
                                        'Delete expense?'),
                                    content: Text(
                                      'Are you sure you want to delete "${expense.title}"?',
                                      style: TextStyle(
                                          fontSize:
                                              14 * fontScale),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(
                                                ctx, false),
                                        child: const Text(
                                            'Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(
                                                ctx, true),
                                        style: ElevatedButton
                                            .styleFrom(
                                          backgroundColor:
                                              Colors.red,
                                          foregroundColor:
                                              Colors.white,
                                        ),
                                        child: const Text(
                                            'Delete'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (_) async {
                                await FirestoreService.instance
                                    .deleteExpense(expense.id);
                                ToastHelper.success(
                                    '${expense.title} deleted');
                              },
                              child: Container(
                                margin: const EdgeInsets.only(
                                    bottom: 12),
                                decoration: BoxDecoration(
                                  color: themeProvider.isGlass
                                      ? (isDark
                                          ? Colors.white
                                              .withOpacity(0.05)
                                          : Colors.white
                                              .withOpacity(0.7))
                                      : cardColor,
                                  borderRadius:
                                      BorderRadius.circular(
                                          cardRadius),
                                  border: themeProvider.isGlass
                                      ? Border.all(
                                          color: Colors.white
                                              .withOpacity(0.1))
                                      : null,
                                ),
                                child: ListTile(
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8),
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.vertical(
                                                top: Radius
                                                    .circular(
                                                        cardRadius)),
                                      ),
                                      builder: (ctx) =>
                                          AddExpenseScreen(
                                        onAddExpense:
                                            (expense) async {
                                          await FirestoreService
                                              .instance
                                              .addExpense(expense);
                                          _checkBudgetAlert(
                                              _getTotal(
                                                  _filterExpenses(
                                                      allExpenses)));
                                        },
                                        expenseToEdit: expense,
                                        onEditExpense:
                                            (updated) async {
                                          await FirestoreService
                                              .instance
                                              .updateExpense(
                                                  updated);
                                        },
                                      ),
                                    );
                                  },
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: categoryColors[
                                              expense.category]!
                                          .withOpacity(0.15),
                                      borderRadius:
                                          BorderRadius.circular(
                                              cardRadius * 0.7),
                                    ),
                                    child: Icon(
                                      categoryIcons[
                                          expense.category],
                                      color: categoryColors[
                                          expense.category],
                                      size: 22,
                                    ),
                                  ),
                                  title: Text(
                                    expense.title,
                                    style: TextStyle(
                                        fontWeight:
                                            FontWeight.w600,
                                        fontSize:
                                            15 * fontScale),
                                  ),
                                  subtitle: Padding(
                                    padding:
                                        const EdgeInsets.only(
                                            top: 3),
                                    child: Text(
                                      '${expense.categoryName} · ${expense.formattedDate}',
                                      style: TextStyle(
                                        fontSize: 12 * fontScale,
                                        color: scheme.onSurface
                                            .withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize:
                                        MainAxisSize.min,
                                    children: [
                                      Text(
                                        '₹${expense.amount.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                          fontSize:
                                              16 * fontScale,
                                          color: accent,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 16,
                                        color: scheme.onSurface
                                            .withOpacity(0.3),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(cardRadius)),
              ),
              builder: (ctx) => AddExpenseScreen(
                onAddExpense: (expense) async {
                  await FirestoreService.instance
                      .addExpense(expense);
                },
              ),
            );
          },
          backgroundColor: accent,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: Text('Add Expense',
              style: TextStyle(fontSize: 14 * fontScale)),
        ),
      ),
    );
  }
}