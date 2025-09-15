import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/materials_providers.dart';
import '../models/materials.dart' as material_model;
// import '../widgets/notifier.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  String _selectedFilter = 'All';
  List<Map<String, dynamic>> _localAlerts = [];
  bool _alertsManuallyCleared = false;

  @override
  Widget build(BuildContext context) {
    final lowStockMaterials = ref.watch(lowStockMaterialsProvider);
    final materialsSummary = ref.watch(materialsSummaryProvider);

    // Generate alerts from low stock materials
    final List<Map<String, dynamic>> alerts = _alertsManuallyCleared
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
            _generateAlertsFromMaterials(lowStockMaterials),
          );

    // Update local alerts if they have changed
    if (_localAlerts.isEmpty || _haveAlertsChanged(alerts, _localAlerts)) {
      setState(() {
        _localAlerts = List<Map<String, dynamic>>.from(alerts);
        // Reset manual clear flag if new alerts appear
        if (_alertsManuallyCleared && _localAlerts.isNotEmpty) {
          _alertsManuallyCleared = false;
        }
      });
    }

    // Filter alerts based on selected filter
    final filteredAlerts = _filterAlerts(_localAlerts, _selectedFilter);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Alerts'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: 'Mark All as Read',
            onPressed: _markAllAlertsAsRead,
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear All Alerts',
            onPressed: _clearAllAlerts,
          ),
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _selectedFilter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Alerts')),
              const PopupMenuItem(value: 'Critical', child: Text('Critical')),
              const PopupMenuItem(value: 'Warning', child: Text('Warning')),
              const PopupMenuItem(value: 'Info', child: Text('Info')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(_selectedFilter),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary cards
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryCard(
                  'Total Materials',
                  materialsSummary['total']?.toString() ?? '0',
                  Colors.blue,
                ),
                _buildSummaryCard(
                  'Low Stock',
                  materialsSummary['lowStock']?.toString() ?? '0',
                  Colors.orange,
                ),
                _buildSummaryCard(
                  'Critical',
                  materialsSummary['criticalStock']?.toString() ?? '0',
                  Colors.red,
                ),
                _buildSummaryCard(
                  'Out of Stock',
                  materialsSummary['outOfStock']?.toString() ?? '0',
                  Colors.red[900]!,
                ),
              ],
            ),
          ),

          // Alerts list
          Expanded(
            child: filteredAlerts.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No alerts at this time',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'All materials are sufficiently stocked',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredAlerts.length,
                    itemBuilder: (context, index) {
                      final alert = filteredAlerts[index];
                      return _buildAlertCard(alert);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Refresh alerts by invalidating providers
          ref.invalidate(lowStockMaterialsProvider);
          ref.invalidate(materialsSummaryProvider);
          _showSnackBar('Alerts refreshed', Colors.green);
        },
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
      ),
    );
  }

  List<Map<String, dynamic>> _generateAlertsFromMaterials(
    List<material_model.Material> materials,
  ) {
    final alerts = <Map<String, dynamic>>[];

    for (final material in materials) {
      if (material.isOutOfStock) {
        alerts.add({
          'id': 'OUT_${material.id}',
          'type': 'critical',
          'title': '${material.name} Out of Stock',
          'message':
              '${material.name} is completely out of stock. Immediate restocking required.',
          'material': material.name,
          'currentStock': material.remainingQuantity,
          'minRequired': 1,
          'timestamp': DateTime.now(),
          'isRead': false,
          'priority': 'High',
        });
      } else if (material.isCriticalStock) {
        alerts.add({
          'id': 'CRIT_${material.id}',
          'type': 'critical',
          'title': '${material.name} Critical Stock',
          'message':
              '${material.name} stock (${material.remainingQuantity}) is critically low. Restock immediately.',
          'material': material.name,
          'currentStock': material.remainingQuantity,
          'minRequired': 6,
          'timestamp': DateTime.now(),
          'isRead': false,
          'priority': 'High',
        });
      } else if (material.isLowStock) {
        alerts.add({
          'id': 'LOW_${material.id}',
          'type': 'warning',
          'title': '${material.name} Low Stock',
          'message':
              '${material.name} stock (${material.remainingQuantity}) is below minimum threshold. Consider restocking soon.',
          'material': material.name,
          'currentStock': material.remainingQuantity,
          'minRequired': 11,
          'timestamp': DateTime.now(),
          'isRead': false,
          'priority': 'Medium',
        });
      }
    }

    // Sort by priority (Critical first, then Warning)
    alerts.sort((a, b) {
      final priorityOrder = {'High': 0, 'Medium': 1, 'Low': 2};
      final aPriority = priorityOrder[a['priority']] ?? 2;
      final bPriority = priorityOrder[b['priority']] ?? 2;
      return aPriority.compareTo(bPriority);
    });

    return alerts;
  }

  List<Map<String, dynamic>> _filterAlerts(
    List<Map<String, dynamic>> alerts,
    String filter,
  ) {
    if (filter == 'All') return alerts;

    return alerts.where((alert) {
      switch (filter) {
        case 'Critical':
          return alert['type'] == 'critical';
        case 'Warning':
          return alert['type'] == 'warning';
        case 'Info':
          return alert['type'] == 'info';
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 12, color: color),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final color = _getAlertColor(alert['type']);
    final icon = _getAlertIcon(alert['type']);
    final isRead = alert['isRead'] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      color: isRead ? Colors.grey[50] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    alert['title'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                      decoration: isRead ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    alert['priority'],
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              alert['message'],
              style: TextStyle(
                fontSize: 14,
                color: isRead ? Colors.grey[600] : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current: ${alert['currentStock']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isRead ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
                Text(
                  'Min Required: ${alert['minRequired']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isRead ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
                Text(
                  _formatTimestamp(alert['timestamp']),
                  style: TextStyle(
                    fontSize: 12,
                    color: isRead ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isRead)
                  TextButton.icon(
                    onPressed: () => _markAlertAsRead(alert['id']),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Mark as Read'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green[700],
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                TextButton.icon(
                  onPressed: () => _deleteAlert(alert['id']),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red[700],
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getAlertColor(String type) {
    switch (type) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getAlertIcon(String type) {
    switch (type) {
      case 'critical':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      case 'info':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  bool _haveAlertsChanged(
    List<Map<String, dynamic>> newAlerts,
    List<Map<String, dynamic>> currentAlerts,
  ) {
    if (newAlerts.length != currentAlerts.length) return true;

    for (int i = 0; i < newAlerts.length; i++) {
      if (newAlerts[i]['id'] != currentAlerts[i]['id'] ||
          newAlerts[i]['currentStock'] != currentAlerts[i]['currentStock']) {
        return true;
      }
    }
    return false;
  }

  void _markAllAlertsAsRead() {
    setState(() {
      for (var alert in _localAlerts) {
        alert['isRead'] = true;
      }
      _showSnackBar('All alerts marked as read', Colors.green);
    });
  }

  void _clearAllAlerts() {
    setState(() {
      _localAlerts.clear();
      _alertsManuallyCleared = true;
      _showSnackBar('All alerts cleared', Colors.red);
    });
  }

  void _markAlertAsRead(String alertId) {
    setState(() {
      final alert = _localAlerts.firstWhere((a) => a['id'] == alertId);
      alert['isRead'] = true;
      _showSnackBar('Alert marked as read', Colors.green);
    });
  }

  void _deleteAlert(String alertId) {
    setState(() {
      _localAlerts.removeWhere((alert) => alert['id'] == alertId);
      _showSnackBar('Alert deleted', Colors.red);
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
