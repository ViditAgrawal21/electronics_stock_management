import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/alert_provider.dart';
import '../widgets/notifier.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String _selectedFilter = 'All';

  // Mock alerts data
  final List<Map<String, dynamic>> _alerts = [
    {
      'id': 'ALT001',
      'type': 'critical',
      'title': 'Capacitor 100uF Out of Stock',
      'message':
          'Capacitor 100uF (C001) is completely out of stock. Immediate restocking required.',
      'material': 'Capacitor 100uF',
      'currentStock': 0,
      'minRequired': 30,
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'isRead': false,
      'priority': 'High',
    },
    {
      'id': 'ALT002',
      'type': 'warning',
      'title': 'Resistor 10K Low Stock',
      'message':
          'Resistor 10K (R001) stock is below minimum threshold. Consider restocking soon.',
      'material': 'Resistor 10K',
      'currentStock': 25,
      'minRequired': 50,
      'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
      'isRead': false,
      'priority': 'Medium',
    },
    {
      'id': 'ALT003',
      'type': 'info',
      'title': 'Production Completed',
      'message':
          'Air Leak Tester production batch of 5 units completed successfully.',
      'material': 'Multiple',
      'currentStock': null,
      'minRequired': null,
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'isRead': false,
      'priority': 'Low',
    },
    {
      'id': 'ALT004',
      'type': 'warning',
      'title': 'LED Red 5mm Usage Alert',
      'message':
          'LED Red 5mm has been heavily used in recent productions. Monitor stock levels.',
      'material': 'LED Red 5mm',
      'currentStock': 185,
      'minRequired': 40,
      'timestamp': DateTime.now().subtract(const Duration(days: 2)),
      'isRead': true,
      'priority': 'Medium',
    },
    {
      'id': 'ALT005',
      'type': 'critical',
      'title': 'PCB Material Shortage',
      'message':
          'Multiple PCB components are running low. Check BOM requirements.',
      'material': 'Multiple PCB Components',
      'currentStock': null,
      'minRequired': null,
      'timestamp': DateTime.now().subtract(const Duration(hours: 8)),
      'isRead': false,
      'priority': 'High',
    },
  ];

  List<Map<String, dynamic>> get _filteredAlerts {
    var alerts = _alerts.where((alert) {
      switch (_selectedFilter) {
        case 'Critical':
          return alert['type'] == 'critical';
        case 'Warning':
          return alert['type'] == 'warning';
        case 'Info':
          return alert['type'] == 'info';
        case 'Unread':
          return !alert['isRead'];
        case 'High Priority':
          return alert['priority'] == 'High';
        default:
          return true;
      }
    }).toList();

    // Sort by timestamp (newest first), but unread alerts first
    alerts.sort((a, b) {
      if (a['isRead'] != b['isRead']) {
        return a['isRead'] ? 1 : -1; // Unread first
      }
      return b['timestamp'].compareTo(a['timestamp']); // Then by timestamp
    });

    return alerts;
  }

  void _markAsRead(String alertId) {
    setState(() {
      final index = _alerts.indexWhere((alert) => alert['id'] == alertId);
      if (index >= 0) {
        _alerts[index]['isRead'] = true;
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var alert in _alerts) {
        alert['isRead'] = true;
      }
    });
    _showSnackBar('All alerts marked as read', Colors.green);
  }

  void _deleteAlert(String alertId) {
    setState(() {
      _alerts.removeWhere((alert) => alert['id'] == alertId);
    });
    _showSnackBar('Alert deleted', Colors.orange);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
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

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
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

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildAlertStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _alerts.where((alert) => !alert['isRead']).length;
    final criticalCount = _alerts
        .where((alert) => alert['type'] == 'critical')
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Alerts'),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        actions: [
          if (unreadCount > 0)
            IconButton(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all),
              tooltip: 'Mark All as Read',
            ),
        ],
      ),
      body: Column(
        children: [
          // Alert Summary
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAlertStat('Total', _alerts.length, Colors.blue),
                    _buildAlertStat('Critical', criticalCount, Colors.red),
                    _buildAlertStat('Unread', unreadCount, Colors.orange),
                  ],
                ),
              ),
            ),
          ),

          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    [
                          'All',
                          'Critical',
                          'Warning',
                          'Info',
                          'Unread',
                          'High Priority',
                        ]
                        .map(
                          (filter) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(filter),
                              selected: _selectedFilter == filter,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedFilter = selected ? filter : 'All';
                                });
                              },
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ),

          // Alerts List
          Expanded(
            child: _filteredAlerts.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No alerts to display',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredAlerts.length,
                    itemBuilder: (context, index) {
                      final alert = _filteredAlerts[index];
                      final alertColor = _getAlertColor(alert['type']);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: alert['isRead']
                            ? Colors.white
                            : alertColor.withOpacity(0.05),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: alertColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getAlertIcon(alert['type']),
                              color: alertColor,
                            ),
                          ),
                          title: Row(
                            children: [
                              if (!alert['isRead'])
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: alertColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  alert['title'],
                                  style: TextStyle(
                                    fontWeight: alert['isRead']
                                        ? FontWeight.w500
                                        : FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(
                                    alert['priority'],
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  alert['priority'],
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _getPriorityColor(alert['priority']),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(alert['message']),
                              const SizedBox(height: 8),
                              if (alert['currentStock'] != null) ...[
                                Row(
                                  children: [
                                    Text(
                                      'Current: ${alert['currentStock']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      'Min Required: ${alert['minRequired']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _getTimeAgo(alert['timestamp']),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!alert['isRead'])
                                        GestureDetector(
                                          onTap: () => _markAsRead(alert['id']),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[100],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Mark Read',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.blue[700],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => _deleteAlert(alert['id']),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red[100],
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            'Delete',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.red[700],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showSnackBar('Checking for new alerts...', Colors.blue);
          // Here you would call your alert service to refresh alerts
        },
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
      ),
    );
  }
}
