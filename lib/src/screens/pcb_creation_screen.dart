import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_string.dart';
import '../models/devices.dart';
import '../models/pcb.dart';
import '../providers/device_providers.dart';
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

  List<SubComponent> _subComponents = [];
  List<PCB> _pcbs = [];
  bool _isLoading = false;
  String? _currentDeviceId; // Track current device being created

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
      // Populate fields for editing
      _deviceNameController.text = widget.deviceToEdit!.name;
      _descriptionController.text = widget.deviceToEdit!.description ?? '';
      _subComponents = List.from(widget.deviceToEdit!.subComponents);
      _pcbs = List.from(widget.deviceToEdit!.pcbs);
      _currentDeviceId = widget.deviceToEdit!.id;
    } else {
      // Generate a temporary device ID for tracking PCBs during creation
      _currentDeviceId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // @overridecd
  // void initState() {
  //   super.initState();
  //   // Generate a temporary device ID for tracking PCBs during creation
  //   _currentDeviceId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
  // }

  // @override
  // void dispose() {
  //   _descriptionController.dispose();
  //   super.dispose();
  // }

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
              const SizedBox(height: 32),
              _buildCreateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceSection() {
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
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _descriptionController,
        decoration: const InputDecoration(
          labelText: 'Description (Optional)',
          prefixIcon: Icon(Icons.description),
        ),
        maxLines: 3,
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
                text: 'Quick Add',
                onPressed: _showQuickAddDialog,
                icon: Icons.flash_on,
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

    setState(() => _isLoading = true);

    try {
      final updatedDevice = widget.deviceToEdit!.copyWith(
        name: _deviceNameController.text.trim(),
        subComponents: _subComponents,
        pcbs: _pcbs,
        updatedAt: DateTime.now(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
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

  // Dialogs
  void _showQuickAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Add Components'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: _preloadedComponents.length,
            itemBuilder: (context, index) {
              final component = _preloadedComponents[index];
              final isAdded = _subComponents.any((sc) => sc.name == component);
              return CheckboxListTile(
                title: Text(component),
                value: isAdded,
                onChanged: isAdded
                    ? null
                    : (value) {
                        if (value == true) _addComponent(component);
                        Navigator.pop(context);
                      },
                secondary: Icon(
                  isAdded ? Icons.check : Icons.add,
                  color: isAdded ? Colors.green : null,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

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
          _subComponents[index] = newComponent;
        } else {
          _subComponents.add(newComponent);
        }
        setState(() {});
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
          deviceId: _currentDeviceId!, // Use temporary device ID
          bom: pcb?.bom,
          createdAt: pcb?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
          description: data['description']!.isEmpty
              ? null
              : data['description'],
        );
        if (index != null) {
          _pcbs[index] = newPcb;
        } else {
          _pcbs.add(newPcb);
        }
        setState(() {});
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
            },
          ),
        ],
      ),
    );
  }

  void _navigateToBomUpload(PCB pcb, int pcbIndex) async {
    // Create a temporary device with current state to pass to BOM upload
    final tempDevice = widget.deviceToEdit != null
        ? widget.deviceToEdit!.copyWith(
            name: _deviceNameController.text.trim().isNotEmpty
                ? _deviceNameController.text.trim()
                : widget.deviceToEdit!.name,
            subComponents: _subComponents,
            pcbs: _pcbs,
            updatedAt: DateTime.now(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          )
        : Device(
            id: _currentDeviceId!,
            name: _deviceNameController.text.trim().isNotEmpty
                ? _deviceNameController.text.trim()
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
          tempDevice: tempDevice, // Pass the temporary device state
          pcbIndex: pcbIndex, // Pass the PCB index for updating
        ),
      ),
    );

    // Update the PCB with returned BOM data if available
    if (result != null) {
      setState(() {
        _pcbs[pcbIndex] = result;
      });

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
      // Removed _subComponents.isEmpty from here

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

    setState(() => _isLoading = true);

    try {
      final deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      final device = Device(
        id: deviceId,
        name: _deviceNameController.text.trim(),
        subComponents: _subComponents, // This can now be empty
        pcbs: _pcbs.map((pcb) => pcb.copyWith(deviceId: deviceId)).toList(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      await ref.read(deviceProvider.notifier).addDevice(device);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device created successfully!'),
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
        content: Text(
          '${device.name} created with $componentText and ${device.totalPcbs} PCBs',
        ),
        actions: [
          if (!device.isReadyForProduction)
            CustomOutlinedButton(
              text: 'Upload BOM',
              onPressed: () {
                Navigator.pop(context);
                if (device.pcbs.isNotEmpty)
                  _navigateToBomUpload(device.pcbs.first, 0);
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
              const SizedBox(height: 12),
              const Text(
                'Components (Optional):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text('• Use Quick Add for common components'),
              const Text('• Add custom components as needed'),
              const Text('• Components can be added later if needed'),
              const SizedBox(height: 12),
              const Text(
                'Quick Add Components:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text('• Enclosure, Display, SMPS, Manifold'),
              const Text('• DP Sensor, Restkit, Regulator, Filter'),
              const Text('• Calport, Nut'),
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
                      'Requirements:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text('• Device name is required'),
                    Text('• At least one PCB board is required'),
                    Text('• Components are optional'),
                    Text('• BOMs can be uploaded after creating the device'),
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
}
