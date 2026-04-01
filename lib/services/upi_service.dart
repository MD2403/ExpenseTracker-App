import 'package:url_launcher/url_launcher.dart';

class UpiService {
  static Future<bool> launchUpiPayment({
    required String upiId,
    required String payeeName,
    required double amount,
    required String transactionNote,
  }) async {
    // Build UPI URL as string first
    final upiUriString =
        'upi://pay?pa=${Uri.encodeComponent(upiId)}'
        '&pn=${Uri.encodeComponent(payeeName)}'
        '&am=${amount.toStringAsFixed(2)}'
        '&tn=${Uri.encodeComponent(transactionNote)}'
        '&cu=INR';

    final upiUri = Uri.parse(upiUriString);

    try {
      // Try direct launch without canLaunchUrl check
      final launched = await launchUrl(
        upiUri,
        mode: LaunchMode.externalApplication,
      );
      return launched;
    } catch (e) {
      // Try with ACTION_VIEW intent as fallback
      try {
        final fallbackUri = Uri.parse(
          'intent://pay?pa=${Uri.encodeComponent(upiId)}'
          '&pn=${Uri.encodeComponent(payeeName)}'
          '&am=${amount.toStringAsFixed(2)}'
          '&tn=${Uri.encodeComponent(transactionNote)}'
          '&cu=INR'
          '#Intent;scheme=upi;action=android.intent.action.VIEW;end',
        );
        return await launchUrl(
          fallbackUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e2) {
        return false;
      }
    }
  }

  static Future<bool> isAnyUpiAppAvailable() async {
    try {
      final uri = Uri.parse('upi://pay?pa=test@upi&pn=Test&am=1&cu=INR');
      return await canLaunchUrl(uri);
    } catch (e) {
      return false;
    }
  }
}