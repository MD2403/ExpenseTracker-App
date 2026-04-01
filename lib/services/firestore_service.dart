import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense.dart';
import '../models/group.dart';
import '../models/group_expense.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._internal();
  FirestoreService._internal();

  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference get _userDoc =>
      _db.collection('users').doc(_uid);

  CollectionReference get _expensesCollection =>
      _userDoc.collection('expenses');

  // ── Budget ────────────────────────────────────────
  Future<void> saveBudget(double budget) async {
    await _userDoc.set({'budget': budget}, SetOptions(merge: true));
  }

  Future<double> getBudget() async {
    final doc = await _userDoc.get();
    if (!doc.exists) return 0;
    final data = doc.data() as Map<String, dynamic>?;
    return (data?['budget'] as num?)?.toDouble() ?? 0;
  }

  // ── Personal expenses ─────────────────────────────
  Future<void> addExpense(Expense expense) async {
    await _expensesCollection.doc(expense.id).set(expense.toMap());
  }

  Future<void> updateExpense(Expense expense) async {
    await _expensesCollection.doc(expense.id).update(expense.toMap());
  }

  Future<void> deleteExpense(String id) async {
    await _expensesCollection.doc(id).delete();
  }

  Stream<List<Expense>> getExpensesStream() {
    return _expensesCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Expense.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // ── Groups ────────────────────────────────────────
  Future<Group> createGroup(String name) async {
    final group = Group(
      name: name,
      createdBy: _uid,
      members: [_uid],
    );
    await _db.collection('groups').doc(group.id).set(group.toMap());
    return group;
  }

  Future<Group?> joinGroupByCode(String code) async {
    final query = await _db
        .collection('groups')
        .where('inviteCode', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final doc   = query.docs.first;
    final group = Group.fromMap(doc.data());

    if (!group.members.contains(_uid)) {
      await doc.reference.update({
        'members': FieldValue.arrayUnion([_uid]),
      });
    }

    return group;
  }

  Stream<List<Group>> getGroupsStream() {
    return _db
        .collection('groups')
        .where('members', arrayContains: _uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Group.fromMap(doc.data()))
            .toList());
  }

  // ── Group expenses ────────────────────────────────
  Future<void> addGroupExpense(
      String groupId, GroupExpense expense) async {
    await _db
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .doc(expense.id)
        .set(expense.toMap());
  }

  Stream<List<GroupExpense>> getGroupExpensesStream(String groupId) {
    return _db
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupExpense.fromMap(doc.data()))
            .toList());
  }

  Future<void> deleteGroupExpense(
      String groupId, String expenseId) async {
    await _db
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .doc(expenseId)
        .delete();
  }

  // ── Member names ──────────────────────────────────
  Future<Map<String, String>> getMemberNames(
      List<String> memberUids) async {
    final Map<String, String> names = {};
    for (final uid in memberUids) {
      try {
        final doc = await _db.collection('users').doc(uid).get();
        print('=== uid: $uid | exists: ${doc.exists} | data: ${doc.data()} ===');

        if (doc.exists) {
          final data        = doc.data() as Map<String, dynamic>?;
          final displayName = data?['displayName'] as String?;
          final email       = data?['email'] as String?;

          if (displayName != null && displayName.trim().isNotEmpty) {
            names[uid] = displayName.trim();
          } else if (email != null && email.trim().isNotEmpty) {
            names[uid] = email.split('@')[0];
          } else {
            names[uid] = 'User';
          }
        } else {
          names[uid] = 'User';
        }
      } catch (e) {
        print('=== ERROR for $uid: $e ===');
        names[uid] = 'User';
      }
    }
    return names;
  }

  // ── Display name ──────────────────────────────────
  Future<void> saveDisplayName(String name) async {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    await _userDoc.set({
      'displayName': name,
      'email':       email,
      'uid':         _uid,
    }, SetOptions(merge: true));
  }

  // ── Balance calculation ───────────────────────────
  Map<String, double> calculateBalances(
      List<GroupExpense> expenses, List<String> members) {
    final Map<String, double> balances = {
      for (var m in members) m: 0.0
    };

    for (final expense in expenses) {
      final perPerson = expense.perPersonAmount;
      balances[expense.paidBy] =
          (balances[expense.paidBy] ?? 0) + expense.amount;
      for (final uid in expense.splitAmong) {
        balances[uid] = (balances[uid] ?? 0) - perPerson;
      }
    }

    return balances;
  }
}