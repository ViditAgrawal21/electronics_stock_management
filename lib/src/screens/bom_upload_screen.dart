import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'materials_list_screen.dart';

class BomUploadScreen extends ConsumerStatefulWidget {
  final String? pcbId;
  final String? pcbName;
  final Device? tempDevice; // Temporary device state from PCB creation
  final int? pcbIndex; // Index of PCB in the temp device

  const BomUploadScreen({
    super.key,
    this.pcbId,
    this.pcbName,
    this.tempDevice,
    this.pcbIndex,
  });

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
  bool _isWorkingWithTempDevice = false;
  List<PCB> _tempPcbs = []; // Store temp PCBs for display
  Map<String, dynamic> _materialAnalysis = {}; // Store current analysis

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize with passed parameters or temp device
    if (widget.tempDevice != null) {
      _isWorkingWithTempDevice = true;
      _tempPcbs = List.from(widget.tempDevice!.pcbs);
      _selectedPcbId = widget.pcbId;
      _selectedDeviceId = widget.tempDevice!.id;

      // Load existing BOM if PCB has one
      if (widget.pcbIndex != null && widget.pcbIndex! < _tempPcbs.length) {
        final pcb = _tempPcbs[widget.pcbIndex!];
        if (pcb.bom != null) {
          _currentBomItems = List.from(pcb.bom!.items);
          _analyzeMaterials(); // Analyze loaded BOM
        }
      }
    } else {
      _selectedPcbId = widget.pcbId;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // NEW: Analyze materials against current BOM
  void _analyzeMaterials() {
    if (_currentBomItems.isEmpty) {
      _materialAnalysis = {};
      return;
    }

    // Extract material requirements from BOM and subComponents
    Map<String, int> requirements = {};

    // Include subComponents as materials
    if (_isWorkingWithTempDevice && widget.tempDevice != null) {
      for (SubComponent comp in widget.tempDevice!.subComponents) {
        String materialName = comp.name.trim();
        requirements[materialName] =
            (requirements[materialName] ?? 0) + comp.quantity;
      }
    }

    for (BOMItem item in _currentBomItems) {
      String materialName = item.value
          .trim(); // FIXED: Use 'value' not 'materialName'
      requirements[materialName] =
          (requirements[materialName] ?? 0) + item.quantity;
    }

    // Get analysis from materials provider
    final materialsNotifier = ref.read(materialsProvider.notifier);
    _materialAnalysis = materialsNotifier.analyzeMaterialRequirements(
      requirements,
    );

    setState(() {}); // Trigger rebuild to show analysis
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsync = _isWorkingWithTempDevice
        ? AsyncValue.data([widget.tempDevice!])
        : ref.watch(deviceProvider);

    return WillPopScope(
      onWillPop: () async {
        if (_hasUnsavedChanges) {
          return await _showUnsavedChangesDialog() ?? false;
        }
        return true;
      },
      child: Scaffold(
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
                  case 'analyze':
                    _showDetailedMaterialAnalysis();
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
                if (_currentBomItems.isNotEmpty) ...[
                  const PopupMenuItem(
                    value: 'analyze',
                    child: Row(
                      children: [
                        Icon(Icons.analytics, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Detailed Analysis'),
                      ],
                    ),
                  ),
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
      ),
    );
  }

  Widget _buildUploadTab(AsyncValue<List<Device>> devicesAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Working mode indicator
          if (_isWorkingWithTempDevice) _buildTempModeIndicator(),

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
            const SizedBox(height: 16),
            _buildEnhancedMaterialValidationSection(),
            const SizedBox(height: 24),
            _buildSaveSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildTempModeIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Working with Device: ${widget.tempDevice?.name}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                const Text(
                  'Changes will be saved to your device creation process',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
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

    if (_isWorkingWithTempDevice && widget.tempDevice != null) {
      // Show PCBs from temp device
      for (PCB pcb in _tempPcbs) {
        items.add(
          DropdownMenuItem(
            value: pcb.id,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.tempDevice!.name} - ${pcb.name}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
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
          ),
        );
      }
    } else {
      // Show PCBs from existing devices
      for (Device device in devices) {
        for (PCB pcb in device.pcbs) {
          items.add(
            DropdownMenuItem(
              value: pcb.id,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${device.name} - ${pcb.name}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
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
            ),
          );
        }
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
                      Text(
                        _isWorkingWithTempDevice
                            ? 'Add PCB boards in the device creation screen first'
                            : 'Create devices with PCB boards first in PCB Creation',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!_isWorkingWithTempDevice) ...[
            const SizedBox(height: 16),
            CustomButton(
              text: 'Go to PCB Creation',
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icons.add_circle,
            ),
          ],
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
          if (!_isWorkingWithTempDevice) {
            _selectedDeviceId = _findDeviceIdForPcb(devices, value);
          }

          // Load existing BOM if switching PCBs
          _loadExistingBomForPcb(value);
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

  void _loadExistingBomForPcb(String? pcbId) {
    if (pcbId == null) {
      _currentBomItems.clear();
      _materialAnalysis = {};
      return;
    }

    if (_isWorkingWithTempDevice) {
      // Load from temp PCBs
      final pcb = _tempPcbs.firstWhere(
        (p) => p.id == pcbId,
        orElse: () => _tempPcbs.first,
      );

      if (pcb.bom != null) {
        _currentBomItems = List.from(pcb.bom!.items);
        _analyzeMaterials(); // Analyze when loading existing BOM
      } else {
        _currentBomItems.clear();
        _materialAnalysis = {};
      }
    } else {
      // Load from existing devices (existing logic)
      _currentBomItems.clear();
      _materialAnalysis = {};
    }
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
                    '3. Value - Component value (must match materials list exactly)',
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
                          'Value column must exactly match raw material names in your inventory (case-insensitive)',
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
                Row(
                  children: [
                    Chip(
                      label: Text('${_currentBomItems.length} components'),
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withOpacity(0.1),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.analytics, color: Colors.blue),
                      onPressed: _showDetailedMaterialAnalysis,
                      tooltip: 'Detailed Analysis',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            BomTable(
              bomItems: _currentBomItems,
              onItemEdit: _handleBomItemEdit,
              onItemDelete: _handleBomItemDelete,
            ),
          ],
        ),
      ),
    );
  }

  // NEW: Enhanced material validation section with detailed analysis
  Widget _buildEnhancedMaterialValidationSection() {
    if (_materialAnalysis.isEmpty) return const SizedBox.shrink();

    final canProduce = _materialAnalysis['canProduce'] ?? false;
    final availableMaterials =
        _materialAnalysis['availableMaterials'] as List<String>? ?? [];
    final missingMaterials =
        _materialAnalysis['missingMaterials'] as List<String>? ?? [];
    final matchPercentage =
        _materialAnalysis['matchPercentage'] as double? ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  canProduce ? Icons.check_circle : Icons.warning,
                  color: canProduce ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Material Validation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: canProduce ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${matchPercentage.toStringAsFixed(1)}% Match',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: canProduce
                          ? Colors.green[700]
                          : Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Summary status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: canProduce ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: canProduce ? Colors.green[200]! : Colors.orange[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    canProduce ? Icons.check_circle : Icons.warning,
                    color: canProduce ? Colors.green[600] : Colors.orange[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      canProduce
                          ? 'All ${availableMaterials.length} materials found in inventory'
                          : '${missingMaterials.length} materials missing from inventory',
                      style: TextStyle(
                        color: canProduce
                            ? Colors.green[700]
                            : Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (availableMaterials.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check, color: Colors.green[600], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Available Materials (${availableMaterials.length}):',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      availableMaterials.take(5).join(', ') +
                          (availableMaterials.length > 5 ? '...' : ''),
                      style: TextStyle(color: Colors.green[600], fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],

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
                        const SizedBox(width: 4),
                        Text(
                          'Missing Materials (${missingMaterials.length}):',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
                    const SizedBox(height: 4),
                    Text(
                      'Add these materials to inventory or check spelling',
                      style: TextStyle(
                        color: Colors.red[500],
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons
            if (missingMaterials.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomOutlinedButton(
                      text: 'View Details',
                      onPressed: _showDetailedMaterialAnalysis,
                      icon: Icons.analytics,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomOutlinedButton(
                      text: 'Add Missing',
                      onPressed: _showAddMissingMaterialsDialog,
                      icon: Icons.add,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
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
                    _isWorkingWithTempDevice
                        ? 'Ready to Update'
                        : 'Ready to Save',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isWorkingWithTempDevice
                        ? 'BOM will be updated in your device creation'
                        : 'BOM will be associated with selected PCB board',
                    style: TextStyle(fontSize: 12, color: Colors.green[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            CustomButton(
              text: _isWorkingWithTempDevice
                  ? 'Update BOM'
                  : AppStrings.saveBom,
              onPressed: _handleSaveBom,
              isLoading: _isLoading,
              backgroundColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  // NEW: Show detailed material analysis dialog
  void _showDetailedMaterialAnalysis() {
    if (_materialAnalysis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No material analysis available. Upload a BOM first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _buildDetailedAnalysisDialog(),
    );
  }

  Widget _buildDetailedAnalysisDialog() {
    final availableMaterials =
        _materialAnalysis['availableMaterials'] as List<String>? ?? [];
    final missingMaterials =
        _materialAnalysis['missingMaterials'] as List<String>? ?? [];
    final availableQuantities =
        _materialAnalysis['availableQuantities'] as Map<String, int>? ?? {};
    final shortages = _materialAnalysis['shortages'] as Map<String, int>? ?? {};
    final matchPercentage =
        _materialAnalysis['matchPercentage'] as double? ?? 0.0;

    return AlertDialog(
      title: const Text('Detailed Material Analysis'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Summary',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Match Rate: ${matchPercentage.toStringAsFixed(1)}%'),
                    Text('Available: ${availableMaterials.length} materials'),
                    Text('Missing: ${missingMaterials.length} materials'),
                    Text(
                      'Total Required: ${_currentBomItems.length} components',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Available materials
              if (availableMaterials.isNotEmpty) ...[
                const Text(
                  'Available Materials:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                ...availableMaterials.map((material) {
                  int available = availableQuantities[material] ?? 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            material,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          '$available units',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 16),
              ],

              // Missing materials
              if (missingMaterials.isNotEmpty) ...[
                const Text(
                  'Missing Materials:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                ...missingMaterials.map((material) {
                  int shortage = shortages[material] ?? 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            material,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          'Need: $shortage',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (missingMaterials.isNotEmpty)
          CustomButton(
            text: 'Add Missing',
            onPressed: () {
              Navigator.pop(context);
              _showAddMissingMaterialsDialog();
            },
          ),
      ],
    );
  }

  // NEW: Show dialog to add missing materials
  void _showAddMissingMaterialsDialog() {
    final missingMaterials =
        _materialAnalysis['missingMaterials'] as List<String>? ?? [];

    if (missingMaterials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No missing materials to add'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Missing Materials'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The following materials are missing from your inventory:',
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: missingMaterials.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(Icons.add_circle_outline, color: Colors.blue),
                    title: Text(missingMaterials[index]),
                    dense: true,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'You can add these materials to your inventory through the Materials List screen.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Copy All',
            onPressed: () {
              // Copy all missing materials with quantity to clipboard
              final buffer = StringBuffer();
              for (final material in missingMaterials) {
                // Find quantity from _materialAnalysis shortages map
                final shortages =
                    _materialAnalysis['shortages'] as Map<String, int>? ?? {};
                final qty = shortages[material] ?? 1;
                buffer.writeln('$material: $qty');
              }
              Clipboard.setData(ClipboardData(text: buffer.toString()));

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All missing materials copied to clipboard'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
          CustomButton(
            text: 'Go to Materials',
            onPressed: () {
              Navigator.pop(context);
              // Navigate to materials screen with missing materials pre-filled
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MaterialsListScreen(
                    initialMaterialsToAdd: missingMaterials,
                    initialQuantities:
                        _materialAnalysis['shortages'] as Map<String, int>? ??
                        {},
                  ),
                ),
              );
            },
          ),
        ],
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
    final TextEditingController quantityController = TextEditingController();

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
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity to Produce',
                      suffixText: 'units',
                      hintText: 'Enter quantity',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                CustomButton(
                  text: 'Calculate',
                  onPressed: () {
                    int? quantity = int.tryParse(quantityController.text);
                    if (quantity != null && quantity > 0) {
                      _showBatchCalculation(device, quantity);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid quantity'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
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

      // Analyze materials after successful import
      _analyzeMaterials();

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
    if (_selectedPcbId == null) return;

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

      if (_isWorkingWithTempDevice) {
        // Update temp PCB and return to PCB creation
        if (widget.pcbIndex != null && widget.pcbIndex! < _tempPcbs.length) {
          final updatedPcb = _tempPcbs[widget.pcbIndex!].copyWith(bom: bom);

          // Return the updated PCB to PCB creation screen
          Navigator.pop(context, updatedPcb);
          return;
        }
      } else {
        // Save BOM to existing device
        if (_selectedDeviceId != null) {
          ref
              .read(deviceProvider.notifier)
              .updatePcbBOM(_selectedDeviceId!, _selectedPcbId!, bom);
        }
      }

      setState(() {
        _isLoading = false;
        _hasUnsavedChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isWorkingWithTempDevice
                  ? 'BOM updated in device creation!'
                  : 'BOM saved successfully! PCB status updated.',
            ),
            backgroundColor: Colors.green,
          ),
        );

        if (!_isWorkingWithTempDevice) {
          _showBomSavedDialog();
        }
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

  // Rest of the existing methods remain the same...
  Future<bool?> _showUnsavedChangesDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes to your BOM. Do you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Discard',
            backgroundColor: Colors.red,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }

  void _showBomSavedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('BOM Uploaded Successfully!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'BOM has been uploaded for the selected PCB board.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.developer_board,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text('PCB: ${widget.pcbName ?? "Selected PCB"}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.inventory,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text('Components: ${_currentBomItems.length}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          CustomOutlinedButton(
            text: 'Upload Another',
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _selectedPcbId = null;
                _selectedDeviceId = null;
                _currentBomItems.clear();
                _materialAnalysis = {};
                _hasUnsavedChanges = false;
              });
            },
          ),
          CustomButton(
            text: 'Done',
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _handleBomItemEdit(int index, BOMItem updatedItem) {
    setState(() {
      _currentBomItems[index] = updatedItem;
      _hasUnsavedChanges = true;
    });
    // Re-analyze materials after editing
    _analyzeMaterials();
  }

  void _handleBomItemDelete(int index) {
    setState(() {
      _currentBomItems.removeAt(index);
      _hasUnsavedChanges = true;
    });
    // Re-analyze materials after deletion
    _analyzeMaterials();
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
                _materialAnalysis = {};
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
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loading materials data...'),
            backgroundColor: Colors.blue,
          ),
        );
      },
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading materials: $error'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  Widget _buildBatchCalculationDialog(
    Device device,
    int quantity,
    Map<String, dynamic> feasibility,
  ) {
    bool canProduce = feasibility['canProduce'] ?? false;
    Map<String, int> requirements = feasibility['requirements'] ?? {};
    Map<String, int> shortages = feasibility['shortages'] ?? {};
    int maxProducible = feasibility['maxProducible'] ?? 0;

    return AlertDialog(
      title: Text('Batch Calculation: ${device.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  Text(
                    'Production Analysis',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Requested Quantity: $quantity units'),
                  Text('Max Producible: $maxProducible units'),
                  Row(
                    children: [
                      Icon(
                        canProduce ? Icons.check_circle : Icons.error,
                        color: canProduce ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        canProduce
                            ? 'Production Feasible'
                            : 'Insufficient Materials',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: canProduce ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (requirements.isNotEmpty) ...[
              const Text(
                'Material Requirements:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Column(
                    children: requirements.entries.map((entry) {
                      String material = entry.key;
                      int required = entry.value;
                      int shortage = shortages[material] ?? 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: shortage > 0
                              ? Colors.red[50]
                              : Colors.green[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: shortage > 0
                                ? Colors.red[200]!
                                : Colors.green[200]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                material,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              '$required units',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (shortage > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Short: $shortage',
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
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (maxProducible > 0)
          CustomOutlinedButton(
            text: 'Produce $maxProducible',
            onPressed: () {
              Navigator.pop(context);
              _initiateProduction(device, maxProducible);
            },
          ),
        if (canProduce)
          CustomButton(
            text: 'Proceed to Production',
            onPressed: () {
              Navigator.pop(context);
              _initiateProduction(device, quantity);
            },
          ),
      ],
    );
  }

  // NEW: Initiate production process
  void _initiateProduction(Device device, int quantity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Production'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Produce $quantity units of ${device.name}?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'This will deduct materials from your inventory.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Confirm Production',
            onPressed: () async {
              Navigator.pop(context);

              try {
                await ref
                    .read(deviceProvider.notifier)
                    .produceDevice(
                      device.id,
                      quantity,
                      'Batch production from BOM screen',
                    );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Successfully produced $quantity units of ${device.name}',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Production failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('BOM Upload Help'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'How to upload BOM:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('1. Select the PCB board from dropdown'),
              const Text('2. Download the Excel template'),
              const Text('3. Fill in your BOM data following the format'),
              const Text('4. Upload the Excel file'),
              const Text('5. Review material validation'),
              const Text('6. Add missing materials if needed'),
              const Text('7. Save the BOM'),
              const SizedBox(height: 12),
              const Text(
                'Material Matching:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                '• Value column must match exact raw material names in inventory',
              ),
              const Text(
                '• Matching is case-insensitive but spelling must be exact',
              ),
              const Text('• Use detailed analysis to see matching results'),
              const Text('• Add missing materials before production'),
              const SizedBox(height: 12),
              const Text(
                'Batch Calculator:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text('• Enter production quantity to check feasibility'),
              const Text('• System shows maximum producible quantity'),
              const Text('• Material shortages are highlighted'),
              const Text('• Initiate production directly from analysis'),
              if (_isWorkingWithTempDevice) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Device Creation Mode:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text('• Real-time material validation'),
                      Text('• Changes saved to device being created'),
                      Text('• Click "Update BOM" to save changes'),
                      Text('• Return to PCB creation to continue'),
                    ],
                  ),
                ),
              ],
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
