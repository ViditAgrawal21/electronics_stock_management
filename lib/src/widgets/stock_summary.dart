import 'package:flutter/material.dart';

class StockSummaryWidget extends StatelessWidget {
  final int totalMaterials;
  final int lowStockItems;
  final int outOfStockItems;
  final double totalValue;
  final int recentlyUsed;
  final VoidCallback? onLowStockTap;
  final VoidCallback? onOutOfStockTap;

  const StockSummaryWidget({
    Key? key,
    required this.totalMaterials,
    required this.lowStockItems,
    required this.outOfStockItems,
    this.totalValue = 0.0,
    this.recentlyUsed = 0,
    this.onLowStockTap,
    this.onOutOfStockTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stock Overview',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Main Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildSummaryCard(
                title: 'Total Materials',
                value: totalMaterials.toString(),
                icon: Icons.inventory_2,
                color: Colors.blue,
                onTap: null,
              ),
              _buildSummaryCard(
                title: 'Low Stock',
                value: lowStockItems.toString(),
                icon: Icons.warning_amber,
                color: Colors.orange,
                onTap: onLowStockTap,
                showAlert: lowStockItems > 0,
              ),
              _buildSummaryCard(
                title: 'Out of Stock',
                value: outOfStockItems.toString(),
                icon: Icons.error_outline,
                color: Colors.red,
                onTap: onOutOfStockTap,
                showAlert: outOfStockItems > 0,
              ),
              _buildSummaryCard(
                title: 'Recently Used',
                value: recentlyUsed.toString(),
                icon: Icons.trending_up,
                color: Colors.green,
                onTap: null,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildQuickActions(context),

          const SizedBox(height: 24),

          // Stock Status Indicator
          _buildStockStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    bool showAlert = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  if (showAlert)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context: context,
            title: 'Import Materials',
            icon: Icons.upload_file,
            color: Colors.blue,
            onTap: () {
              // Navigate to import screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigate to Import Materials')),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            context: context,
            title: 'Create PCB',
            icon: Icons.memory,
            color: Colors.green,
            onTap: () {
              // Navigate to PCB creation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigate to PCB Creation')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockStatusIndicator() {
    final healthyCount = totalMaterials - lowStockItems - outOfStockItems;
    final healthyPercentage = totalMaterials > 0
        ? (healthyCount / totalMaterials) * 100
        : 0;
    final lowStockPercentage = totalMaterials > 0
        ? (lowStockItems / totalMaterials) * 100
        : 0;
    final outOfStockPercentage = totalMaterials > 0
        ? (outOfStockItems / totalMaterials) * 100
        : 0;

    Color statusColor;
    String statusText;

    if (outOfStockItems > 0) {
      statusColor = Colors.red;
      statusText = 'Critical - Items out of stock';
    } else if (lowStockItems > 5) {
      statusColor = Colors.orange;
      statusText = 'Warning - Multiple low stock items';
    } else if (lowStockItems > 0) {
      statusColor = Colors.yellow[700]!;
      statusText = 'Caution - Some items low in stock';
    } else {
      statusColor = Colors.green;
      statusText = 'Good - All items in stock';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: statusColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Inventory Health',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText.split(' - ')[0],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress bars
            _buildProgressBar('Healthy Stock', healthyPercentage, Colors.green),
            const SizedBox(height: 8),
            _buildProgressBar('Low Stock', lowStockPercentage, Colors.orange),
            const SizedBox(height: 8),
            _buildProgressBar('Out of Stock', outOfStockPercentage, Colors.red),

            const SizedBox(height: 12),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
        ),
      ],
    );
  }
}
