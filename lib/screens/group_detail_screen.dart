import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/group.dart';
import '../models/group_expense.dart';
import '../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/toast_helper.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key, required this.group});
  final Group group;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  final _titleController  = TextEditingController();
  final _amountController = TextEditingController();
  Map<String, String> _memberNames = {};
  late Group _group;
  late TabController _tabController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _tabController = TabController(length: 3, vsync: this);
    _loadMemberNames();
    _listenToGroupUpdates();
  }

  // Listen to group document for member updates
  void _listenToGroupUpdates() {
    FirebaseFirestore.instance
        .collection('groups')
        .doc(_group.id)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        final updatedGroup = Group.fromMap(doc.data()!);
        setState(() => _group = updatedGroup);
        _loadMemberNames();
      }
    });
  }

  Future<void> _loadMemberNames() async {
    final names =
        await FirestoreService.instance.getMemberNames(_group.members);
    if (mounted) setState(() => _memberNames = names);
  }

  String _getName(String uid) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    if (uid == currentUid) return 'You';
    return _memberNames[uid] ?? 'Member';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _showAddExpenseSheet() {
    _selectedDate = DateTime.now();
    // All members selected by default
    final selectedMembers = List<String>.from(_group.members);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              16, 24, 16,
              MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Group Expense',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Title
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'What was it for?',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                // Amount
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setSheetState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Total amount (₹)',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                ),
                const SizedBox(height: 12),

                // Date picker
                Row(
                  children: [
                    const Icon(Icons.calendar_month,
                        size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      _selectedDate == null
                          ? 'No date selected'
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      style: const TextStyle(fontSize: 15),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? now,
                          firstDate: DateTime(now.year - 1),
                          lastDate: now,
                        );
                        if (picked != null) {
                          setSheetState(
                              () => _selectedDate = picked);
                        }
                      },
                      icon: const Icon(Icons.edit_calendar),
                      label: const Text('Pick Date'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Who paid
                const Text('Paid by',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person,
                          color: Color(0xFF6C63FF), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _getName(
                            FirebaseAuth.instance.currentUser!.uid),
                        style: const TextStyle(
                            color: Color(0xFF6C63FF),
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Split among
                const Text('Split among',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                const Text('Select who is sharing this expense',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),

                ..._group.members.map((uid) {
                  final isSelected = selectedMembers.contains(uid);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6C63FF).withOpacity(0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6C63FF)
                                .withOpacity(0.3)
                            : Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    child: CheckboxListTile(
                      value: isSelected,
                      activeColor: const Color(0xFF6C63FF),
                      onChanged: (val) {
                        setSheetState(() {
                          if (val == true) {
                            selectedMembers.add(uid);
                          } else {
                            selectedMembers.remove(uid);
                          }
                        });
                      },
                      title: Text(
                        _getName(uid),
                        style: const TextStyle(
                            fontWeight: FontWeight.w500),
                      ),
                      subtitle: uid ==
                              FirebaseAuth.instance.currentUser!.uid
                          ? const Text('You',
                              style: TextStyle(fontSize: 11))
                          : Text(
                              _memberNames[uid] ?? 'Member',
                              style: const TextStyle(fontSize: 11),
                            ),
                      controlAffinity:
                          ListTileControlAffinity.leading,
                      dense: true,
                    ),
                  );
                }),

                const SizedBox(height: 12),

                // Per person preview
                if (_amountController.text.isNotEmpty &&
                    selectedMembers.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF6C63FF)
                              .withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text('Per person',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey)),
                            Text(
                              '₹${((double.tryParse(_amountController.text) ?? 0) / selectedMembers.length).toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Color(0xFF6C63FF)),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Total',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey)),
                            Text(
                              '₹${_amountController.text}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final amount = double.tryParse(
                          _amountController.text);
                      if (_titleController.text.trim().isEmpty ||
                          amount == null ||
                          amount <= 0 ||
                          selectedMembers.isEmpty ||
                          _selectedDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                                'Please fill all fields and pick a date'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                        );
                        return;
                      }

                      final expense = GroupExpense(
                        title: _titleController.text.trim(),
                        amount: amount,
                        paidBy:
                            FirebaseAuth.instance.currentUser!.uid,
                        splitAmong: List.from(selectedMembers),
                        date: _selectedDate!,
                      );

                      await FirestoreService.instance
                          .addGroupExpense(_group.id, expense);
                          ToastHelper.success('Expense added to group!'); 

                      _titleController.clear();
                      _amountController.clear();
                      setState(() => _selectedDate = null);
                      Navigator.pop(ctx);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Expense added!'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Add Expense',
                        style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Balances tab ──────────────────────────────────
  Widget _buildBalancesTab(List<GroupExpense> expenses) {
    final scheme   = Theme.of(context).colorScheme;
    final balances = FirestoreService.instance
        .calculateBalances(expenses, _group.members);

    // Calculate who owes whom
    final List<Map<String, dynamic>> settlements = [];
    final debtors  = balances.entries
        .where((e) => e.value < -0.01)
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final creditors = balances.entries
        .where((e) => e.value > 0.01)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final debtorsCopy   = debtors.map((e) => MapEntry(e.key, e.value)).toList();
    final creditorsCopy = creditors.map((e) => MapEntry(e.key, e.value)).toList();
    final mutableDebts    = {for (var e in debtorsCopy) e.key: e.value};
    final mutableCredits  = {for (var e in creditorsCopy) e.key: e.value};

    for (final creditor in creditorsCopy) {
      for (final debtor in debtorsCopy) {
        if ((mutableCredits[creditor.key] ?? 0) <= 0.01) break;
        if ((mutableDebts[debtor.key] ?? 0) >= -0.01) continue;

        final amount = [(mutableCredits[creditor.key] ?? 0),
            (mutableDebts[debtor.key] ?? 0).abs()].reduce((a, b) => a < b ? a : b);

        settlements.add({
          'from': debtor.key,
          'to': creditor.key,
          'amount': amount,
        });

        mutableCredits[creditor.key] =
            (mutableCredits[creditor.key] ?? 0) - amount;
        mutableDebts[debtor.key] =
            (mutableDebts[debtor.key] ?? 0) + amount;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary cards
        const Text('Summary',
            style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ...balances.entries.map((entry) {
          final isPositive = entry.value > 0.01;
          final isNegative = entry.value < -0.01;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isNegative
                  ? Colors.red.withOpacity(0.08)
                  : isPositive
                      ? Colors.green.withOpacity(0.08)
                      : scheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isNegative
                    ? Colors.red.withOpacity(0.2)
                    : isPositive
                        ? Colors.green.withOpacity(0.2)
                        : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isNegative
                      ? Colors.red.withOpacity(0.15)
                      : isPositive
                          ? Colors.green.withOpacity(0.15)
                          : scheme.onSurface.withOpacity(0.1),
                  child: Text(
                    _getName(entry.key)[0].toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isNegative
                          ? Colors.red
                          : isPositive
                              ? Colors.green
                              : scheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getName(entry.key),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                      Text(
                        isNegative
                            ? 'Owes ₹${entry.value.abs().toStringAsFixed(2)}'
                            : isPositive
                                ? 'Gets back ₹${entry.value.toStringAsFixed(2)}'
                                : 'All settled ✓',
                        style: TextStyle(
                          fontSize: 13,
                          color: isNegative
                              ? Colors.red
                              : isPositive
                                  ? Colors.green
                                  : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),

        if (settlements.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Settle up',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Suggested payments to settle all debts',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),
          ...settlements.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          Colors.red.withOpacity(0.15),
                      child: Text(
                        _getName(s['from'] as String)[0]
                            .toUpperCase(),
                        style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_getName(s['from'] as String)} → ${_getName(s['to'] as String)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Pay ₹${(s['amount'] as double).toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          Colors.green.withOpacity(0.15),
                      child: Text(
                        _getName(s['to'] as String)[0]
                            .toUpperCase(),
                        style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              )),
        ] else if (expenses.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('All settled! No payments needed.',
                    style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Members tab ───────────────────────────────────
  Widget _buildMembersTab() {
    final scheme = Theme.of(context).colorScheme;
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Invite code card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF9C8FFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Invite others to join',
                  style:
                      TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(_group.inviteCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6,
                      )),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy,
                        color: Colors.white70),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                          text: _group.inviteCode));
                          ToastHelper.info('Invite code ${_group.inviteCode} copied!');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Code copied!'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share,
                        color: Colors.white70),
                    onPressed: () {
                      Share.share(
                        'Join my expense group "${_group.name}" on Expense Tracker!\nInvite code: ${_group.inviteCode}',
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

// Change name button
OutlinedButton.icon(
  onPressed: () {
    final nameController = TextEditingController(
      text: _memberNames[
              FirebaseAuth.instance.currentUser!.uid] ??
          '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change your name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Your name',
            hintText: 'e.g. Maharshi',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              await FirestoreService.instance
                  .saveDisplayName(name);
              await _loadMemberNames();
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  },
  icon: const Icon(Icons.edit, size: 16),
  label: const Text('Change your display name'),
),

const SizedBox(height: 16),
Text('Members (${_group.members.length})',
    style: const TextStyle(
        fontWeight: FontWeight.bold, fontSize: 16)),
const SizedBox(height: 12),

        ..._group.members.map((uid) {
          final isCreator = uid == _group.createdBy;
          final isYou     = uid == currentUid;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      const Color(0xFF6C63FF).withOpacity(0.15),
                  child: Text(
                    _getName(uid)[0].toUpperCase(),
                    style: const TextStyle(
                        color: Color(0xFF6C63FF),
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getName(uid),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                      if (_memberNames[uid] != null && !isYou)
                        Text(_memberNames[uid]!,
                            style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurface
                                    .withOpacity(0.5))),
                    ],
                  ),
                ),
                if (isCreator)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Admin',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6C63FF),
                            fontWeight: FontWeight.bold)),
                  ),
                if (isYou && !isCreator)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('You',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme     = Theme.of(context).colorScheme;
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        title: Text(_group.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => Share.share(
              'Join my group "${_group.name}"!\nCode: ${_group.inviteCode}',
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: 'Expenses'),
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Balances'),
            Tab(icon: Icon(Icons.group), text: 'Members'),
          ],
        ),
      ),
      body: StreamBuilder<List<GroupExpense>>(
        stream: FirestoreService.instance
            .getGroupExpensesStream(_group.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenses = snapshot.data ?? [];

          return TabBarView(
            controller: _tabController,
            children: [
              // ── Tab 1: Expenses ──
              expenses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long,
                              size: 64,
                              color:
                                  scheme.onSurface.withOpacity(0.2)),
                          const SizedBox(height: 12),
                          Text('No expenses yet',
                              style: TextStyle(
                                  color: scheme.onSurface
                                      .withOpacity(0.4),
                                  fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Tap + to add first expense',
                              style: TextStyle(
                                  color: scheme.onSurface
                                      .withOpacity(0.3),
                                  fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: expenses.length,
                      itemBuilder: (ctx, index) {
                        final expense = expenses[index];
                        final isPaidByMe =
                            expense.paidBy == currentUid;

                        return Dismissible(
                          key: ValueKey(expense.id),
                          direction: isPaidByMe
                              ? DismissDirection.endToStart
                              : DismissDirection.none,
                          background: Container(
                            margin: const EdgeInsets.only(
                                bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              borderRadius:
                                  BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerRight,
                            padding:
                                const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete_rounded,
                                color: Colors.white, size: 26),
                          ),
                          confirmDismiss: (_) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title:
                                    const Text('Delete expense?'),
                                content: const Text(
                                    'This will remove the expense and update all balances.'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.red,
                                        foregroundColor:
                                            Colors.white),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (_) async {
                            await FirestoreService.instance
                                .deleteGroupExpense(
                                    _group.id, expense.id);
                                     ToastHelper.success('Expense removed'); 
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: const Text(
                                    'Expense deleted'),
                                behavior:
                                    SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                            12)),
                              ),
                            );
                          },
                          child: Container(
                            margin:
                                const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: scheme.onSurface
                                  .withOpacity(0.05),
                              borderRadius:
                                  BorderRadius.circular(16),
                              border: isPaidByMe
                                  ? Border.all(
                                      color: const Color(0xFF6C63FF)
                                          .withOpacity(0.3))
                                  : null,
                            ),
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isPaidByMe
                                      ? const Color(0xFF6C63FF)
                                          .withOpacity(0.15)
                                      : Colors.orange
                                          .withOpacity(0.15),
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.receipt_long,
                                  color: isPaidByMe
                                      ? const Color(0xFF6C63FF)
                                      : Colors.orange,
                                  size: 22,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(expense.title,
                                        style: const TextStyle(
                                            fontWeight:
                                                FontWeight.w600,
                                            fontSize: 15)),
                                  ),
                                  if (isPaidByMe)
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6C63FF)
                                            .withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: const Text('You paid',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color:
                                                  Color(0xFF6C63FF),
                                              fontWeight:
                                                  FontWeight.bold)),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 2),
                                  Text(
                                    'Paid by ${_getName(expense.paidBy)} · ${expense.formattedDate}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: scheme.onSurface
                                            .withOpacity(0.5)),
                                  ),
                                  Text(
                                    'Split among ${expense.splitAmong.length} · ₹${expense.perPersonAmount.toStringAsFixed(2)}/person',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: scheme.onSurface
                                            .withOpacity(0.5)),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${expense.amount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  if (isPaidByMe)
                                    const Icon(Icons.swipe_left,
                                        size: 14,
                                        color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

              // ── Tab 2: Balances ──
              _buildBalancesTab(expenses),

              // ── Tab 3: Members ──
              _buildMembersTab(),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
    );
  }
}