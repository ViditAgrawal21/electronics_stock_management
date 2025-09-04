import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/materials.dart';

// Alert types enum
enum AlertType {
  lowStock,
  criticalStock,
  outOfStock,
  expiring,
  production,
  system,
}

class StockAlert {
  final String id;
  final AlertType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? materialId;
  final String? deviceId;
  final Map<String, dynamic>? data;

  StockAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.materialId,
    this.deviceId,
    this.data,
  });

  // Get alert color based on type
  int get priority {
    switch (type) {
      case AlertType.outOfStock:
        return 3; // Highest priority
      case AlertType.criticalStock:
        return 2;
      case AlertType.lowStock:
        return 1;
      case AlertType.expiring:
        return 1;
      case AlertType.production:
        return 1;
      case AlertType.system:
        return 0; // Lowest priority
    }
  }

  StockAlert copyWith({
    String? id,
    AlertType? type,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    String? materialId,
    String? deviceId,
    Map<String, dynamic>? data,
  }) {
    return StockAlert(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      materialId: materialId ?? this.materialId,
      deviceId: deviceId ?? this.deviceId,
      data: data ?? this.data,
    );
  }
}

class AlertNotifier extends StateNotifier<List<StockAlert>> {
  AlertNotifier() : super([]);

  // Generate alerts from materials list
  void generateMaterialAlerts(List<Material> materials) {
    List<StockAlert> newAlerts = [];

    for (Material material in materials) {
      String alertId = '${material.id}_${material.remainingQuantity}';

      // Check if alert already exists
      bool alertExists = state.any(
        (alert) =>
            alert.materialId == material.id &&
            alert.type == _getAlertTypeForMaterial(material),
      );

      if (!alertExists) {
        if (material.isOutOfStock) {
          newAlerts.add(
            StockAlert(
              id: alertId,
              type: AlertType.outOfStock,
              title: 'Out of Stock',
              message: '${material.name} is completely out of stock',
              createdAt: DateTime.now(),
              materialId: material.id,
            ),
          );
        } else if (material.isCriticalStock) {
          newAlerts.add(
            StockAlert(
              id: alertId,
              type: AlertType.criticalStock,
              title: 'Critical Stock Level',
              message:
                  '${material.name} has only ${material.remainingQuantity} units remaining',
              createdAt: DateTime.now(),
              materialId: material.id,
            ),
          );
        } else if (material.isLowStock) {
          newAlerts.add(
            StockAlert(
              id: alertId,
              type: AlertType.lowStock,
              title: 'Low Stock Alert',
              message:
                  '${material.name} is running low (${material.remainingQuantity} units)',
              createdAt: DateTime.now(),
              materialId: material.id,
            ),
          );
        }
      }
    }

    // Remove old alerts for materials that are now in good stock
    List<StockAlert> updatedAlerts = state.where((alert) {
      if (alert.materialId != null) {
        Material? material = materials
            .where((m) => m.id == alert.materialId)
            .firstOrNull;
        if (material != null) {
          // Keep alert if material still has the same stock status
          return _getAlertTypeForMaterial(material) == alert.type;
        }
      }
      return true; // Keep non-material alerts
    }).toList();

    // Add new alerts
    updatedAlerts.addAll(newAlerts);

    // Sort by priority and date
    updatedAlerts.sort((a, b) {
      int priorityCompare = b.priority.compareTo(a.priority);
      if (priorityCompare != 0) return priorityCompare;
      return b.createdAt.compareTo(a.createdAt);
    });

    state = updatedAlerts;
  }

  AlertType? _getAlertTypeForMaterial(Material material) {
    if (material.isOutOfStock) return AlertType.outOfStock;
    if (material.isCriticalStock) return AlertType.criticalStock;
    if (material.isLowStock) return AlertType.lowStock;
    return null;
  }

  // Add production alert
  void addProductionAlert({
    required String title,
    required String message,
    String? deviceId,
    Map<String, dynamic>? data,
  }) {
    final alert = StockAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: AlertType.production,
      title: title,
      message: message,
      createdAt: DateTime.now(),
      deviceId: deviceId,
      data: data,
    );

    state = [alert, ...state];
  }

  // Add system alert
  void addSystemAlert({
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) {
    final alert = StockAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: AlertType.system,
      title: title,
      message: message,
      createdAt: DateTime.now(),
      data: data,
    );

    state = [alert, ...state];
  }

  // Mark alert as read
  void markAsRead(String alertId) {
    state = state.map((alert) {
      if (alert.id == alertId) {
        return alert.copyWith(isRead: true);
      }
      return alert;
    }).toList();
  }

  // Mark all alerts as read
  void markAllAsRead() {
    state = state.map((alert) => alert.copyWith(isRead: true)).toList();
  }

  // Remove alert
  void removeAlert(String alertId) {
    state = state.where((alert) => alert.id != alertId).toList();
  }

  // Clear all alerts
  void clearAllAlerts() {
    state = [];
  }

  // Get unread count
  int get unreadCount => state.where((alert) => !alert.isRead).length;

  // Get alerts by type
  List<StockAlert> getAlertsByType(AlertType type) {
    return state.where((alert) => alert.type == type).toList();
  }

  // Get recent alerts (last 24 hours)
  List<StockAlert> getRecentAlerts() {
    final yesterday = DateTime.now().subtract(const Duration(hours: 24));
    return state.where((alert) => alert.createdAt.isAfter(yesterday)).toList();
  }
}

// Provider instances
final alertProvider = StateNotifierProvider<AlertNotifier, List<StockAlert>>(
  (ref) => AlertNotifier(),
);

// Unread alerts count provider
final unreadAlertsCountProvider = Provider<int>((ref) {
  final alerts = ref.watch(alertProvider);
  return alerts.where((alert) => !alert.isRead).length;
});

// Recent alerts provider
final recentAlertsProvider = Provider<List<StockAlert>>((ref) {
  final notifier = ref.watch(alertProvider.notifier);
  return notifier.getRecentAlerts();
});

// Alerts by type provider
final alertsByTypeProvider = Provider.family<List<StockAlert>, AlertType>((
  ref,
  type,
) {
  final notifier = ref.watch(alertProvider.notifier);
  return notifier.getAlertsByType(type);
});
