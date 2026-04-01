import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

enum Category {
  food,
  travel,
  shopping,
  bills,
  entertainment,
  fuel,
  health,
  grocery,
  recharge,
  emi,
  other
}

const categoryIcons = {
  Category.food: Icons.restaurant,
  Category.travel: Icons.flight,
  Category.shopping: Icons.shopping_bag,
  Category.bills: Icons.receipt_long,
  Category.entertainment: Icons.movie,
  Category.fuel: Icons.local_gas_station,
  Category.health: Icons.medical_services,
  Category.grocery: Icons.local_grocery_store,
  Category.recharge: Icons.phone_android,
  Category.emi: Icons.account_balance,
  Category.other: Icons.attach_money,
};

const categoryColors = {
  Category.food: Colors.orange,
  Category.travel: Colors.blue,
  Category.shopping: Colors.pink,
  Category.bills: Colors.purple,
  Category.entertainment: Colors.red,
  Category.fuel: Colors.brown,
  Category.health: Colors.green,
  Category.grocery: Colors.teal,
  Category.recharge: Colors.indigo,
  Category.emi: Colors.deepOrange,
  Category.other: Colors.blueGrey,
};

// Human readable names for each category
const categoryNames = {
  Category.food:          'Food',
  Category.travel:        'Travel',
  Category.shopping:      'Shopping',
  Category.bills:         'Bills',
  Category.entertainment: 'Entertainment',
  Category.fuel:          'Fuel & Transport',
  Category.health:        'Health & Medical',
  Category.grocery:       'Grocery',
  Category.recharge:      'Recharge & Bills',
  Category.emi:           'EMI & Loans',
  Category.other:         'Other',
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

  // Get display name for category
  String get categoryName => categoryNames[category] ?? category.name;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category.name,
    };
  }

  factory Expense.fromMap(Map<dynamic, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      category: Category.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => Category.other, // fallback for old data
      ),
    );
  }
}