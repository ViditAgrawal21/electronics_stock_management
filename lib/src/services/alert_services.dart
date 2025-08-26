import 'package:flutter/material.dart';

/// Service class to handle all alert-related functionality
/// including low stock alerts, notifications, and alert management
class AlertService {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  // List to store current alerts
  List<AlertData> _currentAlerts = [];
  
  // Callback for alert updates
  Function(List<AlertData>)? _onAlertsUpdated;

  /// Get all current alerts
  List<AlertData> get currentAlerts => List.unmodifiable(_currentAlerts);

  /// Register a callback for when alerts are updated
  void onAlertsUpdated(Function(List<AlertData>) callback) {
    _onAlertsUpdated = callback;
  }

  /// Check for low stock alerts based on material quantities
  void checkLowStockAlerts(List<dynamic> materials, {int lowStockThreshold = 10}) {
    _currentAlerts.clear();
    
    for (var material in materials) {
      // Assuming material has properties: name, remainingStock, minQuantity
      int remainingStock = material.remainingStock ?? 0;
      int minQuantity = material.minQuantity ?? lowStockThreshold;
      
      if (remainingStock <= minQuantity && remainingStock > 0) {
        _currentAlerts.add(AlertData(
          id: 'low_stock_${material.name}',
          type: AlertType.lowStock,
          title: 'Low Stock Alert',
          message: '${material.name} is running low (${remainingStock} remaining)',
          materialName: material.name,
          currentStock: remainingStock,
          minRequired: minQuantity,
          severity: _getSeverity(remainingStock, minQuantity),
          timestamp: DateTime.now(),
        ));
      } else if (remainingStock == 0) {
        _currentAlerts.add(AlertData(
          id: 'out_of_stock_${material.name}',
          type: AlertType.outOfStock,
          title: 'Out of Stock',
          message: '${material.name} is out of stock!',
          materialName: material.name,
          currentStock: 0,
          minRequired: minQuantity,
          severity: AlertSeverity.critical,
          timestamp: DateTime.now(),
        ));
      }
    }
    
    // Sort alerts by severity (critical first)
    _currentAlerts.sort((a, b) => b.severity.index.compareTo(a.severity.index));
    
    // Notify listeners
    _onAlertsUpdated?.call(_currentAlerts);
  }

  /// Check if sufficient materials are available for PCB production
  AlertData? checkMaterialsForProduction(
    List<dynamic> requiredMaterials,
    List<dynamic> availableMaterials,
    int quantity,
  ) {
    List<String> insufficientMaterials = [];
    
    for (var required in requiredMaterials) {
      var available = availableMaterials.firstWhere(
        (material) => material.name == required.name,
        orElse: () => null,
      );
      
      if (available == null) {
        insufficientMaterials.add('${required.name} (Not available)');
      } else {
        int neededQuantity = (required.quantity ?? 1) * quantity;
        int availableQuantity = available.remainingStock ?? 0;
        
        if (availableQuantity < neededQuantity) {
          insufficientMaterials.add(
            '${required.name} (Need: $neededQuantity, Available: $availableQuantity)'
          );
        }
      }
    }
    
    if (insufficientMaterials.isNotEmpty) {
      return AlertData(
        id: 'insufficient_materials_${DateTime.now().millisecondsSinceEpoch}',
        type: AlertType.insufficientMaterials,
        title: 'Insufficient Materials',
        message: 'Cannot produce $quantity PCBs. Missing materials:\n${insufficientMaterials.join('\n')}',
        severity: AlertSeverity.warning,
        timestamp: DateTime.now(),
      );
    }
    
    return null; // All materials available
  }

  /// Add a custom alert
  void addCustomAlert(AlertData alert) {
    _currentAlerts.add(alert);
    _onAlertsUpdated?.call(_currentAlerts);
  }

  /// Remove an alert by ID
  void removeAlert(String alertId) {
    _currentAlerts.removeWhere((alert) => alert.id == alertId);
    _onAlertsUpdated?.call(_currentAlerts);
  }

  /// Clear all alerts
  void clearAllAlerts() {
    _currentAlerts.clear();
    _onAlertsUpdated?.call(_currentAlerts);
  }

  /// Get alert count by severity
  Map<AlertSeverity, int> getAlertCounts() {
    Map<AlertSeverity, int> counts = {
      AlertSeverity.critical: 0,
      AlertSeverity.warning: 0,
      AlertSeverity.info: 0,
    };
    
    for (var alert in _currentAlerts) {
      counts[alert.severity] = (counts[alert.severity] ?? 0) + 1;
    }
    
    return counts;
  }

  /// Show a snackbar alert
  void showSnackbarAlert(BuildContext context, String message, {AlertSeverity? severity}) {
    Color backgroundColor;
    IconData icon;
    
    switch (severity ?? AlertSeverity.info) {
      case AlertSeverity.critical:
        backgroundColor = Colors.red;
        icon = Icons.error;
        break;
      case AlertSeverity.warning:
        backgroundColor = Colors.orange;
        icon = Icons.warning;
        break;
      case AlertSeverity.info:
        backgroundColor = Colors.blue;
        icon = Icons.info;
        break;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show a dialog alert
  void showDialogAlert(BuildContext context, AlertData alert) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                alert.severity == AlertSeverity.critical ? Icons.error :
                alert.severity == AlertSeverity.warning ? Icons.warning :
                Icons.info,
                color: alert.severity == AlertSeverity.critical ? Colors.red :
                       alert.severity == AlertSeverity.warning ? Colors.orange :
                       Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(alert.title),
            ],
          ),
          content: Text(alert.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            if (alert.type == AlertType.lowStock || alert.type == AlertType.outOfStock)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to materials screen or show update dialog
                  // This would be implemented based on your navigation setup
                },
                child: const Text('Update Stock'),
              ),
          ],
        );
      },
    );
  }

  /// Get severity level for low stock based on current vs minimum quantity
  AlertSeverity _getSeverity(int currentStock, int minQuantity) {
    double ratio = currentStock / minQuantity;
    if (ratio <= 0.2) return AlertSeverity.critical;  // 20% or less
    if (ratio <= 0.5) return AlertSeverity.warning;   // 50% or less
    return AlertSeverity.info;
  }

  /// Check for alerts periodically (can be called from a timer)
  void performPeriodicCheck(List<dynamic> materials) {
    checkLowStockAlerts(materials);
  }
}

/// Data class to represent different types of alerts
class AlertData {
  final String id;
  final AlertType type;
  final String title;
  final String message;
  final String? materialName;
  final int? currentStock;
  final int? minRequired;
  final AlertSeverity severity;
  final DateTime timestamp;

  AlertData({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.materialName,
    this.currentStock,
    this.minRequired,
    required this.severity,
    required this.timestamp,
  });

  /// Convert alert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString(),
      'title': title,
      'message': message,
      'materialName': materialName,
      'currentStock': currentStock,
      'minRequired': minRequired,
      'severity': severity.toString(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create alert from map
  factory AlertData.fromMap(Map<String, dynamic> map) {
    return AlertData(
      id: map['id'],
      type: AlertType.values.firstWhere((e) => e.toString() == map['type']),
      title: map['title'],
      message: map['message'],
      materialName: map['materialName'],
      currentStock: map['currentStock'],
      minRequired: map['minRequired'],
      severity: AlertSeverity.values.firstWhere((e) => e.toString() == map['severity']),
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

/// Enum for different types of alerts
enum AlertType {
  lowStock,
  outOfStock,
  insufficientMaterials,
  pcbCreated,
  bomUploaded,
  custom,
}

/// Enum for alert severity levels
enum AlertSeverity {
  info,     // Blue - general information
  warning,  // Orange - needs attention
  critical, // Red - urgent action needed
}