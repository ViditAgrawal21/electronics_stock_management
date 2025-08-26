import 'package:flutter/material.dart';

/// Utility class for showing notifications, alerts, and user feedback throughout the app
class AppNotifier {
  /// Show a success message (green snackbar)
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show an error message (red snackbar)
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show a warning message (orange snackbar)
  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show an info message (blue snackbar)
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show a loading snackbar that can be dismissed programmatically
  static void showLoading(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.grey[700],
        duration: const Duration(minutes: 1), // Long duration, manually dismiss
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Hide current snackbar
  static void hideCurrentSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// Show a confirmation dialog
  static Future<bool> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Yes',
    String cancelText = 'No',
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                cancelText,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// Show a simple alert dialog
  static Future<void> showAlert({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(buttonText),
            ),
          ],
        );
      },
    );
  }

  /// Show low stock alert with material names
  static void showLowStockAlert(BuildContext context, List<String> lowStockItems) {
    if (lowStockItems.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Low Stock Alert'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('The following materials are running low:'),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: lowStockItems.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 6, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(child: Text(lowStockItems[index])),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to materials screen to reorder
                // This would be implemented based on your navigation setup
              },
              child: const Text('View Materials'),
            ),
          ],
        );
      },
    );
  }

  /// Show batch calculation result (success or failure)
  static void showBatchResult({
    required BuildContext context,
    required bool canMake,
    required int requestedQuantity,
    required String deviceName,
    List<String>? missingMaterials,
  }) {
    final title = canMake ? 'Production Possible ✅' : 'Insufficient Materials ❌';
    final color = canMake ? Colors.green : Colors.red;
    
    String message;
    if (canMake) {
      message = 'You can successfully make $requestedQuantity units of $deviceName!';
    } else {
      message = 'Cannot make $requestedQuantity units of $deviceName.\n\n'
          'Missing materials:\n${missingMaterials?.join('\n') ?? 'Unknown'}';
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                canMake ? Icons.check_circle : Icons.error,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(message),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            if (!canMake) ...[
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to materials screen to check stock
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Check Stock'),
              ),
            ],
          ],
        );
      },
    );
  }
}