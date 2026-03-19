import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

enum Category { food, travel, shopping, bills, other }

const categoryIcons = {
  Category.food: Icons.restaurant,
  Category.travel: Icons.flight,
  Category.shopping: Icons.shopping_bag,
  Category.bills: Icons.receipt_long,
  Category.other: Icons.attach_money,
};

const categoryColors = {
  Category.food: Colors.orange,
  Category.travel: Colors.blue,
  Category.shopping: Colors.pink,
  Category.bills: Colors.purple,
  Category.other: Colors.teal,
};

class Expense {
  Expense({
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    String? id,
  }) : id = id ?? uuid.v4();

  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final Category category;

  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Convert to Map to save in Hive
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category.name,
    };
  }

  // Create Expense from saved Map
  factory Expense.fromMap(Map<dynamic, dynamic> map) {
    return Expense(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      category: Category.values.firstWhere(
        (c) => c.name == map['category'],
      ),
    );
  }
}