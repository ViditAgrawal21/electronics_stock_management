import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StockSummary extends StatelessWidget {
  final Map<String, int> summary;

  const StockSummary({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stock Overview',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    title: 'Total Materials',
                    count: summary['total'] ?? 0,
                    icon: Icons.inventory_2,
                    color: AppTheme.primaryColor,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    title: 'In Stock',
                    count:
                        (summary['total'] ?? 0) -
                        (summary['lowStock'] ?? 0) -
                        (summary['criticalStock'] ?? 0) -
                        (summary['outOfStock'] ?? 0),
                    icon: Icons.check_circle,
                    color: AppTheme.inStockColor,
                    backgroundColor: AppTheme.inStockColor.withOpacity(0.1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    title: 'Low Stock',
                    count: summary['lowStock'] ?? 0,
                    icon: Icons.warning_amber,
                    color: AppTheme.lowStockColor,
                    backgroundColor: AppTheme.lowStockColor.withOpacity(0.1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    title: 'Critical',
                    count: summary['criticalStock'] ?? 0,
                    icon: Icons.error,
                    color: AppTheme.criticalStockColor,
                    backgroundColor: AppTheme.criticalStockColor.withOpacity(
                      0.1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            if ((summary['outOfStock'] ?? 0) > 0)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 12),
                child: _buildSummaryItem(
                  context,
                  title: 'Out of Stock',
                  count: summary['outOfStock'] ?? 0,
                  icon: Icons.cancel,
                  color: AppTheme.outOfStockColor,
                  backgroundColor: AppTheme.outOfStockColor.withOpacity(0.1),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color.withOpacity(0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
