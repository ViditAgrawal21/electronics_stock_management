import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_string.dart';
import '../models/bom.dart';
import '../models/devices.dart';
import '../models/pcb.dart';
import '../providers/device_providers.dart';
import '../providers/materials_providers.dart';
import '../services/excel_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/bom_table.dart';

class BomUploadScreen extends ConsumerStatefulWidget {
  final String? pcbId;
  final String? pcbName;

  const BomUploadScreen({super.key, this.pcbId, this.pcbName});

  @override
  ConsumerState<BomUploadScreen> createState() => _BomUploadScreenState();
}

class _BomUploadScreenState extends ConsumerState<BomUploadScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<BOMItem> _currentBomItems = [];
  String? _selectedPcbId;
  String? _selectedDeviceId;
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedPcbId = widget.pcbId;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(deviceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.bomUploadTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Help',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'template':
                  await _downloadTemplate();
                  break;
                case 'clear':
                  _clearCurrentBOM();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'template',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Download Template'),
                  ],
                ),
              ),
              if (_currentBomItems.isNotEmpty)
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all),
                      SizedBox(width: 8),
                      Text('Clear BOM'),
                    ],
                  ),
                ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.upload_file), text: 'Upload BOM'),
            Tab(
              icon: Icon(Icons.production_quantity_limits),
              text: 'Batch Calculator',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUploadTab(devicesAsync),
          _buildBatchCalculatorTab(devicesAsync),
        ],
      ),
    );
  }

  Widget _buildUploadTab(AsyncValue<List<Device>> devicesAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PCB Selection Section
          _buildPcbSelectionSection(devicesAsync),
          const SizedBox(height: 24),

          // BOM Format Information
          _buildFormatInfoSection(),
          const SizedBox(height: 24),

          // Upload Section
          _buildUploadSection(),
          const SizedBox(height: 24),

          // BOM Preview/Edit Section
          if (_currentBomItems.isNotEmpty) ...[
            _buildBomPreviewSection(),
            const SizedBox(height: 24),
            _buildSaveSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildPcbSelectionSection(AsyncValue<List<Device>> devicesAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.developer_board,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Select PCB Board',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            devicesAsync.when(
              data: (devices) => _buildPcbDropdown(devices),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error loading devices: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPcbDropdown(List<Device> devices) {
    List<DropdownMenuItem<String>> items = [];

    // Debug: Print available devices
    print('Available devices: ${devices.length}');
    for (Device device in devices) {
      print('Device: ${device.name} with ${device.pcbs.length} PCBs');
    }

    for (Device device in devices) {
      for (PCB pcb in device.pcbs) {
        items.add(
          DropdownMenuItem(
            value: pcb.id,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${device.name} - ${pcb.name}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  pcb.hasBOM
                      ? 'Has BOM (${pcb.uniqueComponents} components)'
                      : 'No BOM',
                  style: TextStyle(
                    fontSize: 12,
                    color: pcb.hasBOM ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    if (items.isEmpty) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.orange[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No PCB boards found',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                      const Text(
                        'Create devices with PCB boards first in PCB Creation',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Go to PCB Creation',
            onPressed: () {
              Navigator.pop(context);
              // Navigate to PCB creation
            },
            icon: Icons.add_circle,
          ),
        ],
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedPcbId,
      decoration: const InputDecoration(
        labelText: 'Select PCB Board',
        prefixIcon: Icon(Icons.developer_board),
      ),
      items: items,
      onChanged: (value) {
        setState(() {
          _selectedPcbId = value;
          _selectedDeviceId = _findDeviceIdForPcb(devices, value);
          _currentBomItems.clear();
          _hasUnsavedChanges = false;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a PCB board';
        }
        return null;
      },
    );
  }

  String? _findDeviceIdForPcb(List<Device> devices, String? pcbId) {
    if (pcbId == null) return null;

    for (Device device in devices) {
      if (device.pcbs.any((pcb) => pcb.id == pcbId)) {
        return device.id;
      }
    }
    return null;
  }

  Widget _buildFormatInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'BOM File Format',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Required Excel columns (in order):',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('1. Sr.No - Serial number'),
                  const Text(
                    '2. Reference - Component reference (e.g., C1, R1, U1)',
                  ),
                  const Text(
                    '3. Value - Raw material name (must match materials list)',
                  ),
                  const Text(
                    '4. Footprint - Component footprint (e.g., 0805, LQFP64)',
                  ),
                  const Text('5. Qty - Quantity required'),
                  const Text('6. Top/Bottom - PCB layer (top or bottom)'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        size: 16,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Value column must exactly match material names in your inventory',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_upload, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Upload BOM File',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: AppStrings.uploadBom,
                    onPressed: (_selectedPcbId != null && !_isLoading)
                        ? _handleBomUpload
                        : null,
                    isLoading: _isLoading,
                    icon: Icons.upload_file,
                  ),
                ),
                const SizedBox(width: 12),
                CustomOutlinedButton(
                  text: 'Template',
                  onPressed: _downloadTemplate,
                  icon: Icons.download,
                ),
              ],
            ),

            if (_selectedPcbId == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Please select a PCB board first',
                  style: TextStyle(color: Colors.orange[700], fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBomPreviewSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.preview, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'BOM Preview',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Chip(
                  label: Text('${_currentBomItems.length} components'),
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withOpacity(0.1),
                ),
              ],
            ),
            const SizedBox(height: 16),

            BomTable(
              bomItems: _currentBomItems,
              onItemEdit: _handleBomItemEdit,
              onItemDelete: _handleBomItemDelete,
            ),

            const SizedBox(height: 16),
            _buildMaterialValidationSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialValidationSection() {
    final materialsAsync = ref.watch(materialsProvider);

    return materialsAsync.when(
      data: (materials) {
        List<String> missingMaterials = [];
        List<String> availableMaterials = [];

        for (BOMItem item in _currentBomItems) {
          bool materialExists = materials.any(
            (m) => m.name.toLowerCase() == item.value.toLowerCase(),
          );

          if (materialExists) {
            availableMaterials.add(item.value);
          } else {
            missingMaterials.add(item.value);
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Material Validation',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (availableMaterials.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${availableMaterials.length} materials found in inventory',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            if (missingMaterials.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error, color: Colors.red[600], size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '${missingMaterials.length} materials not found in inventory:',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      missingMaterials.take(5).join(', ') +
                          (missingMaterials.length > 5 ? '...' : ''),
                      style: TextStyle(color: Colors.red[600], fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildSaveSection() {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.save, color: Colors.green[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ready to Save',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'BOM will be associated with selected PCB board',
                    style: TextStyle(fontSize: 12, color: Colors.green[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            CustomButton(
              text: AppStrings.saveBom,
              onPressed: _handleSaveBom,
              isLoading: _isLoading,
              backgroundColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchCalculatorTab(AsyncValue<List<Device>> devicesAsync) {
    return devicesAsync.when(
      data: (devices) => _buildBatchCalculatorContent(devices),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchCalculatorContent(List<Device> devices) {
    List<Device> readyDevices = devices
        .where((d) => d.isReadyForProduction)
        .toList();

    if (readyDevices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.production_quantity_limits,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text('No devices ready for production'),
            const SizedBox(height: 8),
            const Text(
              'Upload BOM files for your PCB boards first',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: readyDevices
            .map((device) => _buildDeviceBatchCard(device))
            .toList(),
      ),
    );
  }

  Widget _buildDeviceBatchCard(Device device) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    device.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text('${device.totalPcbs} PCBs'),
                  backgroundColor: Colors.green.withOpacity(0.1),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity to Produce',
                      suffixText: 'units',
                    ),
                    onChanged: (value) {
                      int? quantity = int.tryParse(value);
                      if (quantity != null && quantity > 0) {
                        setState(() {});
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                CustomButton(
                  text: 'Calculate',
                  onPressed: () =>
                      _showBatchCalculation(device, 5), // Default 5 units
                  icon: Icons.calculate,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBomUpload() async {
    if (_selectedPcbId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      List<BOMItem> bomItems = await ExcelService.importBOM(_selectedPcbId!);

      setState(() {
        _currentBomItems = bomItems;
        _hasUnsavedChanges = true;
        _isLoading = false;
      });

      if (mounted && bomItems.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'BOM imported successfully: ${bomItems.length} components',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSaveBom() async {
    if (_selectedPcbId == null || _selectedDeviceId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create BOM object
      final bom = BOM(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'BOM_${DateTime.now().millisecondsSinceEpoch}',
        pcbId: _selectedPcbId!,
        items: _currentBomItems,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save BOM to device
      ref
          .read(deviceProvider.notifier)
          .updatePcbBOM(_selectedDeviceId!, _selectedPcbId!, bom);

      setState(() {
        _isLoading = false;
        _hasUnsavedChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.bomSaved),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleBomItemEdit(int index, BOMItem updatedItem) {
    setState(() {
      _currentBomItems[index] = updatedItem;
      _hasUnsavedChanges = true;
    });
  }

  void _handleBomItemDelete(int index) {
    setState(() {
      _currentBomItems.removeAt(index);
      _hasUnsavedChanges = true;
    });
  }

  void _clearCurrentBOM() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear BOM'),
        content: const Text(
          'Are you sure you want to clear the current BOM? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Clear',
            backgroundColor: Colors.red,
            onPressed: () {
              setState(() {
                _currentBomItems.clear();
                _hasUnsavedChanges = false;
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _downloadTemplate() async {
    try {
      bool success = await ExcelService.createBOMTemplate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'BOM template downloaded successfully'
                  : 'Failed to download template',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBatchCalculation(Device device, int quantity) {
    final materialsAsync = ref.read(materialsProvider);

    materialsAsync.when(
      data: (materials) {
        final feasibility = ref
            .read(deviceProvider.notifier)
            .checkProductionFeasibility(device.id, quantity, materials);

        showDialog(
          context: context,
          builder: (context) =>
              _buildBatchCalculationDialog(device, quantity, feasibility),
        );
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  Widget _buildBatchCalculationDialog(
    Device device,
    int quantity,
    Map<String, dynamic> feasibility,
  ) {
    bool canProduce = feasibility['canProduce'];
    Map<String, int> requirements = feasibility['requirements'];
    Map<String, int> shortages = feasibility['shortages'];

    return AlertDialog(
      title: Text('Batch Calculation: ${device.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quantity: $quantity units'),
            const SizedBox(height: 16),

            Row(
              children: [
                Icon(
                  canProduce ? Icons.check_circle : Icons.error,
                  color: canProduce ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  canProduce ? 'Production Feasible' : 'Insufficient Materials',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: canProduce ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text(
              'Material Requirements:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...requirements.entries.map((entry) {
              String material = entry.key;
              int required = entry.value;
              int shortage = shortages[material] ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(material)),
                    Text('$required units'),
                    if (shortage > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-$shortage',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (canProduce)
          CustomButton(
            text: 'Proceed to Production',
            onPressed: () {
              Navigator.pop(context);
              // Navigate to production screen or handle production
            },
          ),
      ],
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('BOM Upload Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How to upload BOM:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Select the PCB board from dropdown'),
              Text('2. Download the Excel template'),
              Text('3. Fill in your BOM data following the format'),
              Text('4. Upload the Excel file'),
              Text('5. Review and edit if needed'),
              Text('6. Save the BOM'),
              SizedBox(height: 12),
              Text(
                'Important Notes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                '• Value column must match exact material names in inventory',
              ),
              Text('• Use "top" or "bottom" for layer column'),
              Text('• All columns are required'),
              Text('• Quantity must be positive numbers'),
            ],
          ),
        ),
        actions: [
          CustomButton(text: 'Got it', onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}
