import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../models/expense.dart';

class CsvExport {
  // Save to Downloads folder
  static Future<void> saveToDownloads(List<Expense> expenses) async {
    // Build CSV
    final buffer = StringBuffer();
    buffer.writeln('Title,Amount (Rs),Category,Date');
    for (final e in expenses) {
      final category =
          e.category.name[0].toUpperCase() + e.category.name.substring(1);
      buffer.writeln(
          '${e.title},${e.amount.toStringAsFixed(2)},$category,${e.formattedDate}');
    }

    // Request storage permission
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      throw Exception('Storage permission denied');
    }

    // Save to Downloads
    final fileName =
        'expenses_${DateTime.now().day}_${DateTime.now().month}_${DateTime.now().year}.csv';
    final downloadsDir = Directory('/storage/emulated/0/Download');
    final file = File('${downloadsDir.path}/$fileName');
    await file.writeAsString(buffer.toString());
  }

  // Share via share sheet (WhatsApp, Gmail etc)
  static Future<void> shareExpenses(List<Expense> expenses) async {
    final buffer = StringBuffer();
    buffer.writeln('Title,Amount (Rs),Category,Date');
    for (final e in expenses) {
      final category =
          e.category.name[0].toUpperCase() + e.category.name.substring(1);
      buffer.writeln(
          '${e.title},${e.amount.toStringAsFixed(2)},$category,${e.formattedDate}');
    }

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/expenses.csv';
    final file = File(path);
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(path)],
      subject: 'My Expense Report',
      text: 'Here is my expense report from Expense Tracker.',
    );
  }
}