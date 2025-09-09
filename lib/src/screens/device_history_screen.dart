import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_string.dart';
import '../models/devices.dart';
import '../providers/device_providers.dart';
import '../theme/app_theme.dart';
import '../theme/text_styles.dart';
import '../widgets/custom_button.dart';
import '../services/pdf_services.dart';

class DeviceHistoryScreen extends ConsumerStatefulWidget {
  const DeviceHistoryScreen({super.key});

  @override
  ConsumerState<DeviceHistoryScreen> createState() =>
      _DeviceHistoryScreenState();
}

class _DeviceHistoryScreenState extends ConsumerState<DeviceHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productionHistory = ref.watch(productionHistoryProvider);
    final productionStats = ref.watch(productionStatisticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.deviceHistoryTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => _showStatisticsDialog(productionStats),
            tooltip: 'Statistics',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history),
                  const SizedBox(width: 4),
                  Text('History (${productionHistory.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.analytics),
                  const SizedBox(width: 4),
                  const Text('Analytics'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistoryTab(productionHistory),
          _buildAnalyticsTab(productionStats),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(List<ProductionRecord> history) {
    final devicesAsync = ref.watch(deviceProvider);

    return devicesAsync.when(
      data: (devices) {
        if (devices.isEmpty && history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No devices created yet',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create devices in PCB Creation to see them here',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Create Device',
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icons.add,
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // Show created devices with detailed breakdown
              if (devices.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Created Devices (${devices.length})',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf),
                        onPressed: () => _generateAllDevicesPDF(devices),
                        tooltip: 'Export All Devices to PDF',
                      ),
                      IconButton(
                        icon: const Icon(Icons.analytics),
                        onPressed: () => _generateProductionReportPDF(devices),
                        tooltip: 'Generate Production Report',
                      ),
                    ],
                  ),
                ),
                ...devices
                    .map((device) => _buildEnhancedDeviceCard(device))
                    .toList(),
              ],

              // Show production history
              if (history.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Production History (${history.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...history
                    .map((record) => _buildProductionRecordCard(record))
                    .toList(),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Retry',
              onPressed: () => ref.invalidate(deviceProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedDeviceCard(Device device) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: device.isReadyForProduction
                  ? Colors.green[50]
                  : Colors.orange[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: device.isReadyForProduction
                      ? Colors.green
                      : Colors.orange,
                  child: Icon(
                    device.isReadyForProduction ? Icons.check : Icons.pending,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (device.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          device.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Created: ${_formatDateTime(device.createdAt)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf),
                      onPressed: () => _generateSingleDevicePDF(device),
                      tooltip: 'Export to PDF',
                    ),
                    Text(
                      device.isReadyForProduction ? 'Ready' : 'Pending',
                      style: TextStyle(
                        fontSize: 12,
                        color: device.isReadyForProduction
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Quick Stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildQuickStat(
                    'Components',
                    device.subComponents.length.toString(),
                    Icons.category,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildQuickStat(
                    'PCB Boards',
                    device.pcbs.length.toString(),
                    Icons.developer_board,
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildQuickStat(
                    'Total BOM Items',
                    device.totalBomItems.toString(),
                    Icons.list_alt,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ),

          // Detailed Breakdown Sections
          _buildComponentsSection(device),
          _buildPcbSection(device),
        ],
      ),
    );
  }

  Widget _buildQuickStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildComponentsSection(Device device) {
    return ExpansionTile(
      title: Row(
        children: [
          Icon(Icons.category, color: Colors.blue[600]),
          const SizedBox(width: 8),
          Text(
            'Components (${device.subComponents.length})',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            children: device.subComponents.map((component) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.inventory_2,
                        size: 16,
                        color: Colors.blue[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            component.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (component.description != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              component.description!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[600],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${component.quantity}x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPcbSection(Device device) {
    return ExpansionTile(
      title: Row(
        children: [
          Icon(Icons.developer_board, color: Colors.purple[600]),
          const SizedBox(width: 8),
          Text(
            'PCB Boards (${device.pcbs.length})',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple[200]!),
          ),
          child: Column(
            children: device.pcbs.map((pcb) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PCB Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: pcb.hasBOM
                                ? Colors.green[100]
                                : Colors.orange[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            pcb.hasBOM ? Icons.check_circle : Icons.pending,
                            size: 16,
                            color: pcb.hasBOM
                                ? Colors.green[600]
                                : Colors.orange[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pcb.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              if (pcb.description != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  pcb.description!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: pcb.hasBOM
                                ? Colors.green[600]
                                : Colors.orange[600],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            pcb.hasBOM
                                ? '${pcb.uniqueComponents} components'
                                : 'No BOM',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // BOM Details
                    if (pcb.hasBOM && pcb.bom != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.list_alt,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'BOM Components:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...pcb.bom!.items.take(5).map((bomItem) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.purple[400],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${bomItem.reference}: ${bomItem.value}',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                    Text(
                                      '${bomItem.quantity}x',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        bomItem.footprint,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            if (pcb.bom!.items.length > 5) ...[
                              const SizedBox(height: 4),
                              Text(
                                '... and ${pcb.bom!.items.length - 5} more components',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // PDF Generation Methods
  Future<void> _generateSingleDevicePDF(Device device) async {
    bool success = await PDFService.generateSingleDevicePDF(device);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'PDF generated successfully for ${device.name}'
                : 'Failed to generate PDF for ${device.name}',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _generateAllDevicesPDF(List<Device> devices) async {
    bool success = await PDFService.generateMultipleDevicesPDF(devices);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'PDF generated successfully for all ${devices.length} devices'
                : 'Failed to generate PDF for devices',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _generateProductionReportPDF(List<Device> devices) async {
    final stats = {
      'totalDevices': devices.length,
      'readyDevices': devices.where((d) => d.isReadyForProduction).length,
      'totalComponents': devices.fold<int>(
        0,
        (sum, d) => sum + d.subComponents.length,
      ),
      'totalPcbs': devices.fold<int>(0, (sum, d) => sum + d.pcbs.length),
    };

    bool success = await PDFService.generateProductionReportPDF(devices, stats);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Production report generated successfully'
                : 'Failed to generate production report',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Widget _buildProductionRecordCard(ProductionRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with device name and date
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(record.deviceName, style: AppTextStyles.cardTitle),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(record.productionDate),
                        style: AppTextStyles.cardSubtitle,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${record.quantityProduced} units',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Production summary
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Materials Used',
                    record.uniqueMaterialsUsed.toString(),
                    Icons.inventory,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryItem(
                    'Total Quantity',
                    record.totalMaterialsUsed.toString(),
                    Icons.numbers,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryItem(
                    'Cost',
                    '\${record.totalCost.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Materials breakdown
            ExpansionTile(
              title: const Text(
                'Materials Breakdown',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              leading: const Icon(Icons.expand_more),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: record.materialsUsed.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${entry.value} units',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),

            // Notes if available
            if (record.notes != null && record.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.note, size: 16, color: Colors.blue[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Notes',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.notes!,
                      style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(Map<String, dynamic> stats) {
    final deviceProduction = stats['deviceProduction'] as Map<String, int>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall statistics
          Text(
            'Production Overview',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatsCard(
                  'Total Produced',
                  stats['totalProduced'].toString(),
                  'units',
                  Icons.production_quantity_limits,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatsCard(
                  'Total Cost',
                  '\$${stats['totalCost'].toStringAsFixed(2)}',
                  '',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatsCard(
                  'Production Runs',
                  stats['totalRecords'].toString(),
                  'batches',
                  Icons.repeat,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatsCard(
                  'Avg per Batch',
                  stats['totalRecords'] > 0
                      ? (stats['totalProduced'] / stats['totalRecords'])
                            .toStringAsFixed(1)
                      : '0',
                  'units',
                  Icons.analytics,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Device breakdown
          if (deviceProduction.isNotEmpty) ...[
            Text(
              'Device Breakdown',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Column(
              children: deviceProduction.entries.map((entry) {
                double percentage = stats['totalProduced'] > 0
                    ? (entry.value / stats['totalProduced']) * 100
                    : 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${entry.value} units (${percentage.toStringAsFixed(1)}%)',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (unit.isNotEmpty)
            Text(
              unit,
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.7)),
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showStatisticsDialog(Map<String, dynamic> stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Production Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow(
              'Total Units Produced:',
              stats['totalProduced'].toString(),
            ),
            _buildStatRow(
              'Total Production Cost:',
              '\$${stats['totalCost'].toStringAsFixed(2)}',
            ),
            _buildStatRow(
              'Number of Production Runs:',
              stats['totalRecords'].toString(),
            ),
            if (stats['totalRecords'] > 0)
              _buildStatRow(
                'Average Units per Run:',
                (stats['totalProduced'] / stats['totalRecords'])
                    .toStringAsFixed(2),
              ),
            if (stats['totalProduced'] > 0)
              _buildStatRow(
                'Average Cost per Unit:',
                '\$${(stats['totalCost'] / stats['totalProduced']).toStringAsFixed(2)}',
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
