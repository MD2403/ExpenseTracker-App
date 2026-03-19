import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/expense.dart';

class ChartScreen extends StatelessWidget {
  const ChartScreen({super.key, required this.expenses});

  final List<Expense> expenses;

  // Total spent per category
  Map<Category, double> get _categoryTotals {
    final totals = {for (var cat in Category.values) cat: 0.0};
    for (final e in expenses) {
      totals[e.category] = totals[e.category]! + e.amount;
    }
    return totals;
  }

  double get _totalSpent =>
      expenses.fold(0, (sum, e) => sum + e.amount);

  @override
  Widget build(BuildContext context) {
    final totals = _categoryTotals;
    final total = _totalSpent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Chart'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: total == 0
          ? const Center(child: Text('No expenses to show yet.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Pie chart
                  const Text(
                    'Spending by Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 240,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 50,
                        sections: Category.values
                            .where((cat) => totals[cat]! > 0)
                            .map((cat) {
                          final percent = (totals[cat]! / total) * 100;
                          return PieChartSectionData(
                            value: totals[cat],
                            title: '${percent.toStringAsFixed(0)}%',
                            color: categoryColors[cat],
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Legend
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: Category.values
                        .where((cat) => totals[cat]! > 0)
                        .map((cat) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: categoryColors[cat],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  cat.name[0].toUpperCase() +
                                      cat.name.substring(1),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ))
                        .toList(),
                  ),

                  const SizedBox(height: 36),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Bar chart
                  const Text(
                    'Amount per Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: totals.values.reduce(
                                (a, b) => a > b ? a : b) *
                            1.3,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) => Text(
                                '₹${value.toInt()}',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final cat =
                                    Category.values[value.toInt()];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Icon(
                                    categoryIcons[cat],
                                    size: 18,
                                    color: categoryColors[cat],
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          drawVerticalLine: false,
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: Category.values
                            .asMap()
                            .entries
                            .map((entry) => BarChartGroupData(
                                  x: entry.key,
                                  barRods: [
                                    BarChartRodData(
                                      toY: totals[entry.value]!,
                                      color: categoryColors[entry.value],
                                      width: 28,
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                  ],
                                ))
                            .toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Category breakdown list
                  const Text(
                    'Breakdown',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...Category.values
                      .where((cat) => totals[cat]! > 0)
                      .map((cat) => Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: categoryColors[cat],
                                  radius: 18,
                                  child: Icon(
                                    categoryIcons[cat],
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  cat.name[0].toUpperCase() +
                                      cat.name.substring(1),
                                  style: const TextStyle(fontSize: 15),
                                ),
                                const Spacer(),
                                Text(
                                  '₹${totals[cat]!.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${((totals[cat]! / total) * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )),
                ],
              ),
            ),
    );
  }
}