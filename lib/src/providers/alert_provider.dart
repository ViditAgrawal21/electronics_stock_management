import 'package:flutter/material.dart';
import '../models/materials.dart';
import '../services/stock_services.dart';
import '../services/alert_services.dart';

class AlertProvider with ChangeNotifier {
  final StockService _stockService;
  final AlertService _alertService;
  
  AlertProvider(this._stockService, this._alertService);

  // Alert states
  List<MaterialModel> _lowStockMaterials = [];
  List<String> _criticalAlerts = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Alert configuration
  int _lowStockThreshold = 10;
  int _criticalStockThreshold = 5;
  bool _alertsEnabled = true;

  // Getters
  List<MaterialModel> get lowStockMaterials => _lowStockMaterials;
  List<String> get criticalAlerts => _criticalAlerts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get lowStockThreshold => _lowStockThreshold;
  int get criticalStockThreshold => _criticalStockThreshold;
  bool get alertsEnabled => _alertsEnabled;
  
  // Computed getters
  int get lowStockCount => _lowStockMaterials.length;
  int get criticalAlertsCount => _criticalAlerts.length;
  bool get hasAlerts => lowStockCount > 0 || criticalAlertsCount > 0;

  /// Check all materials for low stock and generate alerts
  Future<void> checkLowStock() async {
    if (!_alertsEnabled) return;
    
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Get all materials from stock service
      final allMaterials = await _stockService.getAllMaterials();
      
      // Filter materials with low stock
      _lowStockMaterials = allMaterials.where((material) {
        return material.remainingQuantity <= _lowStockThreshold;
      }).toList();

      // Generate critical alerts for very low stock
      _criticalAlerts.clear();
      for (var material in _lowStockMaterials) {
        if (material.remainingQuantity <= _criticalStockThreshold) {
          _criticalAlerts.add(
            'CRITICAL: ${material.name} only has ${material.remainingQuantity} units left!'
          );
        }
      }

      // Show system notifications if enabled
      if (_lowStockMaterials.isNotEmpty) {
        await _alertService.showLowStockNotification(
          _lowStockMaterials.length,
          _criticalAlerts.length,
        );
      }

    } catch (e) {
      _errorMessage = 'Failed to check stock levels: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if specific material quantity would trigger alert
  bool wouldTriggerAlert(MaterialModel material, int newQuantity) {
    return newQuantity <= _lowStockThreshold;
  }

  /// Check stock after material usage (called when BOM is processed)
  Future<void> checkStockAfterUsage(List<MaterialModel> usedMaterials) async {
    if (!_alertsEnabled) return;

    List<String> newAlerts = [];
    
    for (var material in usedMaterials) {
      if (material.remainingQuantity <= _criticalStockThreshold) {
        newAlerts.add(
          'URGENT: ${material.name} is running critically low (${material.remainingQuantity} left)'
        );
      } else if (material.remainingQuantity <= _lowStockThreshold) {
        newAlerts.add(
          'LOW STOCK: ${material.name} needs reordering (${material.remainingQuantity} left)'
        );
      }
    }

    if (newAlerts.isNotEmpty) {
      _criticalAlerts.addAll(newAlerts);
      await _alertService.showInstantAlert(
        'Stock Alert',
        '${newAlerts.length} materials need attention after production'
      );
      notifyListeners();
    }

    // Refresh full stock check
    await checkLowStock();
  }

  /// Dismiss specific alert
  void dismissAlert(int index) {
    if (index >= 0 && index < _criticalAlerts.length) {
      _criticalAlerts.removeAt(index);
      notifyListeners();
    }
  }

  /// Dismiss all alerts
  void dismissAllAlerts() {
    _criticalAlerts.clear();
    notifyListeners();
  }

  /// Update alert thresholds
  void updateThresholds({
    int? lowStock,
    int? criticalStock,
  }) {
    if (lowStock != null && lowStock > 0) {
      _lowStockThreshold = lowStock;
    }
    if (criticalStock != null && criticalStock > 0) {
      _criticalStockThreshold = criticalStock;
    }
    notifyListeners();
    
    // Recheck with new thresholds
    checkLowStock();
  }

  /// Toggle alerts on/off
  void toggleAlerts(bool enabled) {
    _alertsEnabled = enabled;
    if (!enabled) {
      _lowStockMaterials.clear();
      _criticalAlerts.clear();
    }
    notifyListeners();
    
    if (enabled) {
      checkLowStock();
    }
  }

  /// Get materials that will be insufficient for production
  List<MaterialModel> getInsufficientMaterials(
    List<MaterialModel> requiredMaterials,
    int quantity,
  ) {
    return requiredMaterials.where((required) {
      final needed = required.remainingQuantity * quantity;
      final available = _stockService.getMaterialQuantity(required.id);
      return available < needed;
    }).toList();
  }

  /// Check if production is possible with current stock
  bool canProduceQuantity(
    List<MaterialModel> requiredMaterials,
    int quantity,
  ) {
    return getInsufficientMaterials(requiredMaterials, quantity).isEmpty;
  }

  /// Get formatted alert message for UI display
  String getFormattedAlertMessage(int index) {
    if (index >= 0 && index < _criticalAlerts.length) {
      return _criticalAlerts[index];
    }
    return '';
  }

  /// Get alert severity level
  AlertSeverity getAlertSeverity(MaterialModel material) {
    if (material.remainingQuantity <= _criticalStockThreshold) {
      return AlertSeverity.critical;
    } else if (material.remainingQuantity <= _lowStockThreshold) {
      return AlertSeverity.warning;
    }
    return AlertSeverity.normal;
  }

  /// Clear any error messages
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Force refresh all alerts
  Future<void> refreshAlerts() async {
    await checkLowStock();
  }
}

// Enum for alert severity levels
enum AlertSeverity {
  normal,
  warning,
  critical,
}

// Extension for alert severity colors
extension AlertSeverityExtension on AlertSeverity {
  Color get color {
    switch (this) {
      case AlertSeverity.normal:
        return Colors.green;
      case AlertSeverity.warning:
        return Colors.orange;
      case AlertSeverity.critical:
        return Colors.red;
    }
  }

  String get label {
    switch (this) {
      case AlertSeverity.normal:
        return 'Normal';
      case AlertSeverity.warning:
        return 'Low Stock';
      case AlertSeverity.critical:
        return 'Critical';
    }
  }

  IconData get icon {
    switch (this) {
      case AlertSeverity.normal:
        return Icons.check_circle;
      case AlertSeverity.warning:
        return Icons.warning;
      case AlertSeverity.critical:
        return Icons.error;
    }
  }
}