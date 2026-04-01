import 'package:uuid/uuid.dart';

const _uuidGen = Uuid();

class GroupExpense {
  GroupExpense({
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.splitAmong,
    required this.date,
    String? id,
  }) : id = id ?? _uuidGen.v4();

  final String id;
  final String title;
  final double amount;
  final String paidBy;          // uid of person who paid
  final List<String> splitAmong; // uids of people splitting
  final DateTime date;

  // Amount each person owes
  double get perPersonAmount => amount / splitAmong.length;

  String get formattedDate =>
      '${date.day}/${date.month}/${date.year}';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'paidBy': paidBy,
      'splitAmong': splitAmong,
      'date': date.toIso8601String(),
    };
  }

  factory GroupExpense.fromMap(Map<String, dynamic> map) {
    return GroupExpense(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      paidBy: map['paidBy'] as String,
      splitAmong: List<String>.from(map['splitAmong']),
      date: DateTime.parse(map['date'] as String),
    );
  }
}