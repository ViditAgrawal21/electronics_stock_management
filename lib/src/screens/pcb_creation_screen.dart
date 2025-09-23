import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import '../constants/app_string.dart';
import '../models/devices.dart';
import '../models/pcb.dart';
import '../providers/device_providers.dart';
import '../providers/materials_providers.dart';
import '../providers/pcb_creation_provider.dart';
import '../widgets/custom_button.dart';
import 'bom_upload_screen.dart';

class PcbCreationScreen extends ConsumerStatefulWidget {
  final Device? deviceToEdit;

  const PcbCreationScreen({super.key, this.deviceToEdit});

  @override
  ConsumerState<PcbCreationScreen> createState() => _PcbCreationScreenState();
}

class _PcbCreationScreenState extends ConsumerState<PcbCreationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _deviceNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  bool _isLoading = false;
  Map<String, int> _materialRequirements = {};
  Map<String, dynamic> _productionFeasibility = {};
  bool _showMaterialAnalysis = false;

  // Getters for provider state
  List<SubComponent> get _subComponents =>
      ref.watch(pcbCreationProvider).subComponents;
  List<PCB> get _pcbs => ref.watch(pcbCreationProvider).pcbs;
  String? get _currentDeviceId =>
      ref.watch(pcbCreationProvider).currentDeviceId;

  static const _preloadedComponents = [
    'Enclosure',
    'Display',
    'SMPS',
    'Manifold',
    'DP sensor',
    'Restkit',
    'Regulator',
    'Filter',
    'Calport',
    'Nut',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.deviceToEdit != null) {
      // Delay provider modification until after widget tree is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(pcbCreationProvider.notifier)
            .initializeForEdit(widget.deviceToEdit!);
        _updateMaterialRequirements(); // Analyze existing device
      });
    } else {
      // Delay provider modification until after widget tree is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(pcbCreationProvider.notifier).initializeForCreate();
      });
    }
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.deviceToEdit == null
              ? AppStrings.pcbCreationTitle
              : 'Edit Device',
        ),
        actions: [
          if (_materialRequirements.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.analytics,
                color: _productionFeasibility['canProduce'] == true
                    ? Colors.green
                    : Colors.orange,
              ),
              onPressed: () => _showProductionPlanningDialog(),
              tooltip: 'Production Planning',
            ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDeviceSection(),
              const SizedBox(height: 24),
              _buildComponentsSection(),
              const SizedBox(height: 24),
              _buildPcbSection(),
              const SizedBox(height: 24),
              if (_showMaterialAnalysis) _buildMaterialRequirementsSection(),
              const SizedBox(height: 32),
              _buildCreateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceSection() {
    final pcbCreationState = ref.watch(pcbCreationProvider);

    return _buildCard('Device Information', Icons.memory, [
      TextFormField(
        controller: _deviceNameController,
        decoration: const InputDecoration(
          labelText: 'Device Name *',
          prefixIcon: Icon(Icons.devices),
          hintText: 'Enter device name',
        ),
        validator: (value) => value == null || value.trim().isEmpty
            ? 'Please enter device name'
            : null,
        onChanged: (value) {
          ref.read(pcbCreationProvider.notifier).updateDeviceName(value);
          _updateMaterialRequirements();
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        initialValue: pcbCreationState.description,
        decoration: const InputDecoration(
          labelText: 'Description (Optional)',
          prefixIcon: Icon(Icons.description),
        ),
        maxLines: 3,
        onChanged: (value) {
          ref.read(pcbCreationProvider.notifier).updateDescription(value);
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        initialValue: pcbCreationState.quantity,
        decoration: const InputDecoration(
          labelText: 'Quantity to Produce *',
          prefixIcon: Icon(Icons.production_quantity_limits),
          hintText: 'Enter number of devices to create',
        ),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter quantity';
          }
          final quantity = int.tryParse(value.trim());
          if (quantity == null || quantity <= 0) {
            return 'Please enter a valid positive number';
          }
          return null;
        },
        onChanged: (value) {
          ref.read(pcbCreationProvider.notifier).updateQuantity(value);
          _updateMaterialRequirements();
        },
      ),
    ]);
  }

  Widget _buildComponentsSection() {
    return _buildCard(
      'Components (${_subComponents.length}) - Optional',
      Icons.category,
      [
        Row(
          children: [
            Expanded(
              child: CustomOutlinedButton(
                text: 'Upload Excel',
                onPressed: _handleExcelUpload,
                icon: Icons.upload_file,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CustomButton(
                text: 'Custom',
                onPressed: () => _showComponentDialog(),
                icon: Icons.add,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _subComponents.isEmpty
            ? _buildEmptyState(
                'No components added',
                'Components are optional. Add them if needed.',
                Icons.category,
              )
            : _buildItemsList(_subComponents, _buildComponentCard),
      ],
    );
  }

  Widget _buildPcbSection() {
    return _buildCard('PCB Boards (${_pcbs.length})', Icons.developer_board, [
      Align(
        alignment: Alignment.centerRight,
        child: CustomButton(
          text: 'Add PCB',
          onPressed: () => _showPcbDialog(),
          icon: Icons.add,
        ),
      ),
      const SizedBox(height: 16),
      _pcbs.isEmpty
          ? _buildEmptyState(
              'No PCB boards added',
              'Add PCB boards for your device',
              Icons.developer_board,
            )
          : _buildItemsList(_pcbs, _buildPcbCard),
    ]);
  }

  Widget _buildCard(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList<T>(
    List<T> items,
    Widget Function(T, int) itemBuilder,
  ) {
    return Column(
      children: items
          .asMap()
          .entries
          .map((entry) => itemBuilder(entry.value, entry.key))
          .toList(),
    );
  }

  Widget _buildComponentCard(SubComponent component, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(component.name),
        subtitle: Text(
          'Quantity: ${component.quantity}${component.description != null ? '\n${component.description}' : ''}',
        ),
        trailing: _buildPopupMenu([
          _buildMenuItem(
            'Edit',
            Icons.edit,
            () => _showComponentDialog(component, index),
          ),
          _buildMenuItem(
            'Delete',
            Icons.delete,
            () => _removeItem(index, _subComponents, 'component'),
            isDestructive: true,
          ),
        ]),
      ),
    );
  }

  Widget _buildPcbCard(PCB pcb, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: pcb.hasBOM
              ? Colors.green.withOpacity(0.1)
              : Colors.orange.withOpacity(0.1),
          child: Icon(
            pcb.hasBOM ? Icons.check_circle : Icons.pending,
            color: pcb.hasBOM ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(pcb.name),
        subtitle: Text(
          pcb.hasBOM
              ? 'BOM: ${pcb.uniqueComponents} components'
              : 'No BOM uploaded',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                pcb.hasBOM ? Icons.edit : Icons.upload_file,
                color: pcb.hasBOM ? Colors.blue : Colors.orange,
              ),
              onPressed: () => _navigateToBomUpload(pcb, index),
              tooltip: pcb.hasBOM ? 'Edit BOM' : 'Upload BOM',
            ),
            _buildPopupMenu([
              _buildMenuItem(
                'Edit PCB',
                Icons.edit,
                () => _showPcbDialog(pcb, index),
              ),
              _buildMenuItem(
                'Delete',
                Icons.delete,
                () => _removeItem(index, _pcbs, 'PCB'),
                isDestructive: true,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupMenu(List<PopupMenuItem> items) {
    return PopupMenuButton(itemBuilder: (context) => items);
  }

  PopupMenuItem _buildMenuItem(
    String text,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return PopupMenuItem(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: isDestructive ? Colors.red : null),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: isDestructive ? Colors.red : null),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: widget.deviceToEdit == null
            ? AppStrings.createDevice
            : 'Update Device',
        onPressed: _isLoading
            ? null
            : (widget.deviceToEdit == null
                  ? _handleCreateDevice
                  : _handleUpdateDevice),
        isLoading: _isLoading,
        icon: Icons.add_circle,
      ),
    );
  }

  Future<void> _handleUpdateDevice() async {
    final pcbCreationState = ref.read(pcbCreationProvider);

    if (!_formKey.currentState!.validate() ||
        pcbCreationState.deviceName.trim().isEmpty ||
        _pcbs.isEmpty) {
      String errorMessage = 'Please fill all required fields';
      if (pcbCreationState.deviceName.trim().isEmpty) {
        errorMessage = 'Device name is required';
      } else if (_pcbs.isEmpty) {
        errorMessage = 'At least one PCB board is required';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedDevice = widget.deviceToEdit!.copyWith(
        name: pcbCreationState.deviceName.trim(),
        subComponents: _subComponents,
        pcbs: _pcbs,
        updatedAt: DateTime.now(),
        description: pcbCreationState.description.trim().isEmpty
            ? null
            : pcbCreationState.description.trim(),
      );

      await ref.read(deviceProvider.notifier).updateDevice(updatedDevice);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update device: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Show production planning dialog
  void _showProductionPlanningDialog() {
    final pcbCreationState = ref.read(pcbCreationProvider);
    final quantity = int.tryParse(pcbCreationState.quantity) ?? 1;

    // Compute missing materials outside the widget tree
    final missingMaterials = _productionFeasibility['missingMaterials'] != null
        ? List.from(
            _productionFeasibility['missingMaterials'] as List<dynamic>,
          ).map((e) => e.toString()).toList()
        : <String>[];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Production Planning'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Production summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _productionFeasibility['canProduce'] == true
                        ? Colors.green[50]
                        : Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _productionFeasibility['canProduce'] == true
                          ? Colors.green[200]!
                          : Colors.orange[200]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _productionFeasibility['canProduce'] == true
                                ? Icons.check_circle
                                : Icons.warning,
                            color: _productionFeasibility['canProduce'] == true
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Production Analysis',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Requested Quantity: $quantity units'),
                      Text(
                        'Device Name: ${pcbCreationState.deviceName.trim()}',
                      ),
                      if (_productionFeasibility['maxProducible'] != null)
                        Text(
                          'Max Producible: ${_productionFeasibility['maxProducible']} units',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Material requirements
                if (_materialRequirements.isNotEmpty) ...[
                  const Text(
                    'Material Requirements:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._materialRequirements.entries.map((entry) {
                    final available =
                        _productionFeasibility['available']
                            as Map<String, int>? ??
                        {};
                    final shortages =
                        _productionFeasibility['shortages']
                            as Map<String, int>? ??
                        {};

                    final materialName = entry.key;
                    final required = entry.value;
                    final availableQty = available[materialName] ?? 0;
                    final shortage = shortages[materialName] ?? 0;
                    final hasShortage = shortage > 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: hasShortage ? Colors.red[50] : Colors.green[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: hasShortage
                              ? Colors.red[200]!
                              : Colors.green[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              materialName,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Text(
                            'Need: $required | Have: $availableQty',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (hasShortage) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Short: $shortage',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.red,
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

                // Missing materials
                if (missingMaterials.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Missing Materials:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      missingMaterials.join(', '),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
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
          if (_productionFeasibility['canProduce'] == true)
            CustomButton(
              text: 'Create & Produce',
              onPressed: () {
                Navigator.pop(context);
                _handleCreateDeviceWithProduction();
              },
            ),
        ],
      ),
    );
  }

  // Dialogs
  // Removed _showQuickAddDialog as Quick Add is replaced by Excel upload

  void _showComponentDialog([SubComponent? component, int? index]) {
    _showFormDialog(
      title: component == null ? 'Add Component' : 'Edit Component',
      fields: {
        'name': component?.name ?? '',
        'quantity': component?.quantity.toString() ?? '1',
        'description': component?.description ?? '',
      },
      onSave: (data) {
        final newComponent = SubComponent(
          id: component?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: data['name']!,
          quantity: int.tryParse(data['quantity']!) ?? 1,
          description: data['description']!.isEmpty
              ? null
              : data['description'],
        );
        if (index != null) {
          ref
              .read(pcbCreationProvider.notifier)
              .updateSubComponent(index, newComponent);
        } else {
          ref.read(pcbCreationProvider.notifier).addSubComponent(newComponent);
        }
        setState(() {});
        _updateMaterialRequirements(); // Update analysis
      },
    );
  }

  void _showPcbDialog([PCB? pcb, int? index]) {
    _showFormDialog(
      title: pcb == null ? 'Add PCB Board' : 'Edit PCB Board',
      fields: {'name': pcb?.name ?? '', 'description': pcb?.description ?? ''},
      onSave: (data) {
        final newPcb = PCB(
          id: pcb?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: data['name']!,
          deviceId: _currentDeviceId!,
          bom: pcb?.bom,
          createdAt: pcb?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
          description: data['description']!.isEmpty
              ? null
              : data['description'],
        );
        if (index != null) {
          ref.read(pcbCreationProvider.notifier).updatePcb(index, newPcb);
        } else {
          ref.read(pcbCreationProvider.notifier).addPcb(newPcb);
        }
        setState(() {});
        _updateMaterialRequirements(); // Update analysis
      },
    );
  }

  void _showFormDialog({
    required String title,
    required Map<String, String> fields,
    required Function(Map<String, String>) onSave,
  }) {
    final controllers = fields.map(
      (key, value) => MapEntry(key, TextEditingController(text: value)),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: controllers.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                controller: entry.value,
                decoration: InputDecoration(
                  labelText:
                      '${entry.key.substring(0, 1).toUpperCase()}${entry.key.substring(1)} ${entry.key == 'description' ? '(Optional)' : '*'}',
                ),
                maxLines: entry.key == 'description' ? 2 : 1,
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: title.contains('Add') ? 'Add' : 'Update',
            onPressed: () {
              if (controllers['name']!.text.trim().isNotEmpty) {
                final data = controllers.map(
                  (key, controller) => MapEntry(key, controller.text.trim()),
                );
                onSave(data);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  // Helper methods
  void _addComponent(String name, [int? quantity]) {
    setState(() {
      _subComponents.add(
        SubComponent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          quantity: quantity ?? 1,
        ),
      );
    });
    _updateMaterialRequirements(); // Update analysis
  }

  Future<void> _handleExcelUpload() async {
    try {
      // Pick Excel file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xls', 'xlsx'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        // User cancelled
        return;
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid file selected'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Read file bytes
      final bytes = await File(filePath).readAsBytes();
      final excelFile = excel.Excel.decodeBytes(bytes);

      Map<String, int> materialsToUse = {};

      // Iterate sheets and rows
      for (final sheetName in excelFile.tables.keys) {
        final sheet = excelFile.tables[sheetName];
        if (sheet == null) continue;

        // Skip header row, start from row 1 (assuming row 0 is header)
        for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
          final row = sheet.row(rowIndex);
          if (row.isEmpty) continue;

          // Columns: A=0 Sr no, B=1 Description, C=2 Make, D=3 Series, E=4 Qty
          final descriptionCell = row.length > 1 ? row[1] : null;
          final qtyCell = row.length > 4 ? row[4] : null;

          final description = descriptionCell?.value?.toString().trim() ?? '';
          final qtyStr = qtyCell?.value?.toString().trim() ?? '0';
          final qty = int.tryParse(qtyStr) ?? 0;

          if (description.isNotEmpty && qty > 0) {
            materialsToUse[description] =
                (materialsToUse[description] ?? 0) + qty;
          }
        }
      }

      if (materialsToUse.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No valid materials found in Excel'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Do NOT deduct materials here on Excel upload, only analyze and update UI
      // await ref
      //     .read(materialsProvider.notifier)
      //     .useMaterialsByNames(materialsToUse);

      // Convert materialsToUse map to SubComponent list and update provider
      final subComponents = materialsToUse.entries.map((entry) {
        return SubComponent(
          id: DateTime.now().millisecondsSinceEpoch.toString() + entry.key,
          name: entry.key,
          quantity: entry.value,
        );
      }).toList();

      // Replace all subComponents with new ones from Excel
      ref.read(pcbCreationProvider.notifier).setSubComponents(subComponents);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Excel data processed. Material deduction will occur on device creation.',
          ),
          backgroundColor: Colors.blue,
        ),
      );

      // Update UI to reflect new material data immediately
      _updateMaterialRequirements();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to process Excel file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeItem<T>(int index, List<T> list, String itemType) {
    final itemName = list[index] is SubComponent
        ? (list[index] as SubComponent).name
        : (list[index] as PCB).name;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove $itemType'),
        content: Text('Remove "$itemName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Remove',
            backgroundColor: Colors.red,
            onPressed: () {
              setState(() => list.removeAt(index));
              Navigator.pop(context);
              _updateMaterialRequirements(); // Update analysis
            },
          ),
        ],
      ),
    );
  }

  /// Navigates to the BOM upload screen while preserving the current device state.
  ///
  /// This method ensures that the state of subComponents and PCBs remains intact
  /// across navigation. A temporary device is created with the current state
  /// (_subComponents, _pcbs, device name, description) and passed to the BOM upload screen.
  /// On return, if a PCB is updated, it replaces the corresponding PCB in the list
  /// and material requirements are recalculated.
  ///
  /// State persistence is maintained because:
  /// - The StatefulWidget retains _subComponents and _pcbs lists in memory
  /// - Navigation doesn't destroy the widget instance
  /// - BOM upload screen has WillPopScope to prevent accidental state loss
  /// - Only explicit saves update the state
  void _navigateToBomUpload(PCB pcb, int pcbIndex) async {
    final pcbCreationState = ref.read(pcbCreationProvider);

    // Create a temporary device with current state to pass to BOM upload
    // This ensures BOM upload has access to all current subComponents and PCBs
    final tempDevice = widget.deviceToEdit != null
        ? widget.deviceToEdit!.copyWith(
            name: pcbCreationState.deviceName.trim().isNotEmpty
                ? pcbCreationState.deviceName.trim()
                : widget.deviceToEdit!.name,
            subComponents: _subComponents,
            pcbs: _pcbs,
            updatedAt: DateTime.now(),
            description: pcbCreationState.description.trim().isEmpty
                ? null
                : pcbCreationState.description.trim(),
          )
        : Device(
            id: _currentDeviceId!,
            name: pcbCreationState.deviceName.trim().isNotEmpty
                ? pcbCreationState.deviceName.trim()
                : 'New Device',
            subComponents: _subComponents,
            pcbs: _pcbs,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

    // Navigate to BOM upload screen with current PCB and device state
    final result = await Navigator.push<PCB>(
      context,
      MaterialPageRoute(
        builder: (context) => BomUploadScreen(
          pcbId: pcb.id,
          pcbName: pcb.name,
          tempDevice: tempDevice,
          pcbIndex: pcbIndex,
        ),
      ),
    );

    // Update the PCB with returned BOM data if available
    // This preserves state by only updating the specific PCB that was modified
    if (result != null) {
      setState(() {
        _pcbs[pcbIndex] = result;
      });
      _updateMaterialRequirements(); // Update analysis after BOM change

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PCB BOM updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handleCreateDevice() async {
    if (!_formKey.currentState!.validate() ||
        _deviceNameController.text.trim().isEmpty ||
        _pcbs.isEmpty) {
      String errorMessage = 'Please fill all required fields';
      if (_deviceNameController.text.trim().isEmpty) {
        errorMessage = 'Device name is required';
      } else if (_pcbs.isEmpty) {
        errorMessage = 'At least one PCB board is required';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.orange),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text) ?? 1;
    setState(() => _isLoading = true);

    try {
      final deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      final device = Device(
        id: deviceId,
        name: _deviceNameController.text.trim(),
        subComponents: _subComponents,
        pcbs: _pcbs.map((pcb) => pcb.copyWith(deviceId: deviceId)).toList(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      // Check if device is ready for production (has complete BOMs) and quantity > 0
      if (device.isReadyForProduction && quantity > 0) {
        // Create device WITH automatic material deduction
        await ref
            .read(deviceProvider.notifier)
            .addDeviceWithProduction(device, quantity);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Device created and $quantity units produced! Materials automatically deducted from inventory.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Create device WITHOUT material deduction
        await ref.read(deviceProvider.notifier).addDevice(device);

        if (mounted) {
          String message = 'Device created successfully! ';
          if (!device.isReadyForProduction) {
            message += 'Upload BOMs to complete setup and enable production.';
          } else if (quantity == 0) {
            message += 'No materials deducted (quantity = 0).';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: device.isReadyForProduction
                  ? Colors.blue
                  : Colors.orange,
            ),
          );
        }
      }

      if (mounted) {
        _showSuccessDialog(device);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // NEW: Handle create device with production
  Future<void> _handleCreateDeviceWithProduction() async {
    if (!_formKey.currentState!.validate() ||
        _deviceNameController.text.trim().isEmpty ||
        _pcbs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the device setup first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text) ?? 1;

    setState(() => _isLoading = true);

    try {
      final deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      final device = Device(
        id: deviceId,
        name: _deviceNameController.text.trim(),
        subComponents: _subComponents,
        pcbs: _pcbs.map((pcb) => pcb.copyWith(deviceId: deviceId)).toList(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      // Add device WITH production
      await ref
          .read(deviceProvider.notifier)
          .addDeviceWithProduction(device, quantity);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Device created and $quantity units produced successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _showSuccessDialog(device);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(Device device) {
    final componentText = device.subComponents.isEmpty
        ? 'no components'
        : '${device.totalSubComponents} components';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Device Created!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${device.name} created with $componentText and ${device.totalPcbs} PCBs',
            ),
            if (_materialRequirements.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Material analysis available with ${_materialRequirements.length} requirements',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!device.isReadyForProduction)
            CustomOutlinedButton(
              text: 'Upload BOM',
              onPressed: () {
                Navigator.pop(context);
                if (device.pcbs.isNotEmpty) {
                  _navigateToBomUpload(device.pcbs.first, 0);
                }
              },
            ),
          CustomButton(
            text: 'Done',
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
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
        title: const Text('PCB Creation Help'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.deviceToEdit == null
                    ? 'How to create a device:'
                    : 'How to edit a device:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('1. Enter device name (required)'),
              const Text('2. Add or modify components (optional)'),
              const Text('3. Add, edit, or remove PCB boards (required)'),
              const Text('4. Upload or update BOMs for each PCB'),
              const Text('5. Enter quantity to produce'),
              const Text('6. Review material requirements and stock status'),
              const Text('7. Use production planning for detailed analysis'),
              const SizedBox(height: 12),
              const Text(
                'NEW: Production Planning:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                '• Click the analytics icon to view production analysis',
              ),
              const Text('• See material requirements and availability'),
              const Text('• Check stock shortages and missing materials'),
              const Text(
                '• Create device with or without immediate production',
              ),
              const SizedBox(height: 12),
              const Text(
                'Material Requirements:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text('• System analyzes BOM data for material needs'),
              const Text('• Real-time stock validation against inventory'),
              const Text('• Highlights shortages and missing materials'),
              const Text('• Calculates maximum producible quantity'),
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
                      'Smart Features:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text('• Auto-calculates material requirements from BOMs'),
                    Text('• Real-time inventory validation'),
                    Text('• Production feasibility analysis'),
                    Text('• Automatic material deduction after production'),
                    Text('• Material restoration when devices are deleted'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          CustomButton(text: 'Got it', onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  // Update material requirements when device structure changes
  void _updateMaterialRequirements() {
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    if (quantity <= 0) {
      setState(() {
        _materialRequirements = {};
        _productionFeasibility = {};
        _showMaterialAnalysis = false;
      });
      return;
    }

    // Calculate material requirements from current PCBs
    Map<String, int> requirements = {};

    for (PCB pcb in _pcbs) {
      if (pcb.bom != null) {
        for (var item in pcb.bom!.items) {
          String materialName = item.value.trim();
          int requiredPerPcb = item.quantity;
          int totalRequired = requiredPerPcb * quantity;

          requirements[materialName] =
              (requirements[materialName] ?? 0) + totalRequired;
        }
      }
    }

    _materialRequirements = requirements;

    // Get production feasibility if we have requirements
    if (_materialRequirements.isNotEmpty) {
      final materialsNotifier = ref.read(materialsProvider.notifier);
      _productionFeasibility = materialsNotifier.analyzeMaterialRequirements(
        _materialRequirements,
      );
      _showMaterialAnalysis = true;
    } else {
      _productionFeasibility = {};
      _showMaterialAnalysis = false;
    }

    setState(() {});
  }

  // Build material requirements section
  Widget _buildMaterialRequirementsSection() {
    if (_materialRequirements.isEmpty) {
      return const SizedBox.shrink();
    }

    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final canProduce = _productionFeasibility['canProduce'] ?? true;
    final shortages =
        _productionFeasibility['shortages'] as Map<String, int>? ?? {};
    final available =
        _productionFeasibility['availableQuantities'] as Map<String, int>? ??
        {};
    final missingMaterials =
        _productionFeasibility['missingMaterials'] as List<String>? ?? [];

    return _buildCard('Production Analysis (${quantity}x)', Icons.analytics, [
      // Summary
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
              color: canProduce ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                canProduce
                    ? 'All materials available for production'
                    : missingMaterials.isNotEmpty
                    ? 'Some materials missing from inventory'
                    : 'Some materials have insufficient stock',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: canProduce ? Colors.green[700] : Colors.orange[700],
                ),
              ),
            ),
            CustomOutlinedButton(
              text: 'Details',
              onPressed: _showProductionPlanningDialog,
              icon: Icons.analytics,
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Quick material overview (first 3 items)
      ..._materialRequirements.entries.take(3).map((entry) {
        final materialName = entry.key;
        final requiredQty = entry.value;
        final availableQty = available[materialName] ?? 0;
        final shortageQty = shortages[materialName] ?? 0;
        final isShort = shortageQty > 0;
        final isMissing = missingMaterials.contains(materialName);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMissing
                ? Colors.red[50]
                : isShort
                ? Colors.orange[50]
                : Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isMissing
                  ? Colors.red[200]!
                  : isShort
                  ? Colors.orange[200]!
                  : Colors.green[200]!,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      materialName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isMissing
                          ? 'Material not found in inventory'
                          : 'Required: $requiredQty | Available: $availableQty',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
              if (isShort || isMissing)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isMissing ? Colors.red[100] : Colors.orange[100],
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Text(
                    isMissing ? 'Missing' : 'Short: $shortageQty',
                    style: TextStyle(
                      color: isMissing ? Colors.red[700] : Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      }),

      // Show more indicator if there are more materials
      if (_materialRequirements.length > 3) ...[
        const SizedBox(height: 8),
        Center(
          child: Text(
            '... and ${_materialRequirements.length - 3} more materials',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    ]);
  }
}
