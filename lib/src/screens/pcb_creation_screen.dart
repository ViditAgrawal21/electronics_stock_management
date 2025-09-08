import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_string.dart';
import '../models/devices.dart';
import '../models/pcb.dart';
import '../providers/device_providers.dart';
import '../widgets/custom_button.dart';
import '../screens/bom_upload_screen.dart';

class PcbCreationScreen extends ConsumerStatefulWidget {
  const PcbCreationScreen({super.key});

  @override
  ConsumerState<PcbCreationScreen> createState() => _PcbCreationScreenState();
}

class _PcbCreationScreenState extends ConsumerState<PcbCreationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  List<SubComponent> _subComponents = [];
  List<PCB> _pcbs = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _deviceNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.pcbCreationTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Help',
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
              // Device Information Section
              _buildSectionHeader('Device Information', Icons.memory),
              const SizedBox(height: 16),
              _buildDeviceInfoSection(),
              const SizedBox(height: 24),

              // Sub Components Section
              _buildSectionHeader('Sub Components', Icons.category),
              const SizedBox(height: 16),
              _buildSubComponentsSection(),
              const SizedBox(height: 24),

              // PCB Boards Section
              _buildSectionHeader('PCB Boards', Icons.developer_board),
              const SizedBox(height: 16),
              _buildPcbBoardsSection(),
              const SizedBox(height: 32),

              // Create Device Button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: AppStrings.createDevice,
                  onPressed: _isLoading ? null : _handleCreateDevice,
                  isLoading: _isLoading,
                  icon: Icons.add_circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _deviceNameController,
              decoration: const InputDecoration(
                labelText: 'Device Name *',
                hintText: 'e.g., Air Leak Tester, PCB Test Fixture',
                prefixIcon: Icon(Icons.devices),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter device name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Brief description of the device',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubComponentsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Components (${_subComponents.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                CustomButton(
                  text: 'Add Component',
                  onPressed: _showAddSubComponentDialog,
                  icon: Icons.add,
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_subComponents.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.category, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No components added yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add components like enclosure, display, SMPS, etc.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Column(
                children: _subComponents.asMap().entries.map((entry) {
                  int index = entry.key;
                  SubComponent component = entry.value;
                  return _buildSubComponentCard(component, index);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubComponentCard(SubComponent component, int index) {
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quantity: ${component.quantity}'),
            if (component.description != null)
              Text(
                component.description!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: const Row(
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
              onTap: () => _showEditSubComponentDialog(component, index),
            ),
            PopupMenuItem(
              value: 'delete',
              child: const Row(
                children: [
                  Icon(Icons.delete, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
              onTap: () => _removeSubComponent(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPcbBoardsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PCB Boards (${_pcbs.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    CustomButton(
                      text: 'Add PCB',
                      onPressed: _showAddPcbDialog,
                      icon: Icons.add,
                    ),
                    const SizedBox(width: 8),
                    if (_pcbs.isNotEmpty)
                      CustomOutlinedButton(
                        text: 'Upload BOMs',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BomUploadScreen(),
                            ),
                          );
                        },
                        icon: Icons.upload_file,
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_pcbs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.developer_board,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No PCB boards added yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add PCB boards like cape board, DIDO board, LED board',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Column(
                children: _pcbs.asMap().entries.map((entry) {
                  int index = entry.key;
                  PCB pcb = entry.value;
                  return _buildPcbCard(pcb, index);
                }).toList(),
              ),
          ],
        ),
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pcb.hasBOM
                  ? 'BOM: ${pcb.uniqueComponents} components'
                  : 'No BOM uploaded',
              style: TextStyle(
                color: pcb.hasBOM ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (pcb.description != null)
              Text(
                pcb.description!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            if (!pcb.hasBOM)
              PopupMenuItem(
                value: 'upload_bom',
                child: const Row(
                  children: [
                    Icon(Icons.upload_file, size: 16),
                    SizedBox(width: 8),
                    Text('Upload BOM'),
                  ],
                ),
                onTap: () => _navigateToBomUpload(pcb),
              ),
            PopupMenuItem(
              value: 'edit',
              child: const Row(
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
              onTap: () => _showEditPcbDialog(pcb, index),
            ),
            PopupMenuItem(
              value: 'delete',
              child: const Row(
                children: [
                  Icon(Icons.delete, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
              onTap: () => _removePcb(index),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSubComponentDialog() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Sub Component'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Component Name *',
                hintText: 'e.g., Enclosure, Display, SMPS',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity *'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Add',
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final component = SubComponent(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  quantity: int.tryParse(quantityController.text) ?? 1,
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                );

                setState(() {
                  _subComponents.add(component);
                });

                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showEditSubComponentDialog(SubComponent component, int index) {
    final nameController = TextEditingController(text: component.name);
    final quantityController = TextEditingController(
      text: component.quantity.toString(),
    );
    final descriptionController = TextEditingController(
      text: component.description ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Sub Component'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Component Name *'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity *'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Update',
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final updatedComponent = component.copyWith(
                  name: nameController.text.trim(),
                  quantity: int.tryParse(quantityController.text) ?? 1,
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                );

                setState(() {
                  _subComponents[index] = updatedComponent;
                });

                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _removeSubComponent(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Component'),
        content: Text(
          'Are you sure you want to remove "${_subComponents[index].name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Remove',
            backgroundColor: Colors.red,
            onPressed: () {
              setState(() {
                _subComponents.removeAt(index);
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showAddPcbDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add PCB Board'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'PCB Name *',
                hintText: 'e.g., Cape Board, DIDO Board, LED Board',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Add',
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final pcb = PCB(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  deviceId: '', // Will be set when device is created
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                );

                setState(() {
                  _pcbs.add(pcb);
                });

                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showEditPcbDialog(PCB pcb, int index) {
    final nameController = TextEditingController(text: pcb.name);
    final descriptionController = TextEditingController(
      text: pcb.description ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit PCB Board'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'PCB Name *'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Update',
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final updatedPcb = pcb.copyWith(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                  updatedAt: DateTime.now(),
                );

                setState(() {
                  _pcbs[index] = updatedPcb;
                });

                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _removePcb(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove PCB Board'),
        content: Text(
          'Are you sure you want to remove "${_pcbs[index].name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Remove',
            backgroundColor: Colors.red,
            onPressed: () {
              setState(() {
                _pcbs.removeAt(index);
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _navigateToBomUpload(PCB pcb) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BomUploadScreen(pcbId: pcb.id, pcbName: pcb.name),
      ),
    );
  }

  Future<void> _handleCreateDevice() async {
    if (!_formKey.currentState!.validate()) return;

    if (_subComponents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one sub component'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_pcbs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one PCB board'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

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

      ref.read(deviceProvider.notifier).addDevice(device);

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
          SnackBar(
            content: Text('Failed to create device: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog(Device device) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Device Created Successfully!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${device.name} has been created with:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.category, size: 16),
                        const SizedBox(width: 8),
                        Text('${device.totalSubComponents} sub components'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.developer_board, size: 16),
                        const SizedBox(width: 8),
                        Text('${device.totalPcbs} PCB boards'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          device.isReadyForProduction
                              ? Icons.check_circle
                              : Icons.pending,
                          size: 16,
                          color: device.isReadyForProduction
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          device.isReadyForProduction
                              ? 'Ready for production'
                              : 'Needs BOM upload',
                          style: TextStyle(
                            color: device.isReadyForProduction
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (!device.isReadyForProduction)
              Text(
                'Next: Upload BOM files for your PCB boards to enable production',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
          ],
        ),
        actions: [
          if (!device.isReadyForProduction)
            CustomOutlinedButton(
              text: 'Upload BOM',
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BomUploadScreen(),
                  ),
                );
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

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PCB Creation Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How to create a device:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Enter device name and description'),
              SizedBox(height: 4),
              Text('2. Add sub components (enclosure, display, SMPS, etc.)'),
              SizedBox(height: 4),
              Text('3. Add PCB boards (cape board, DIDO board, LED board)'),
              SizedBox(height: 4),
              Text('4. Upload BOM files for each PCB board'),
              SizedBox(height: 12),
              Text(
                'Example: Air Leak Tester',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Sub Components:'),
              Text('• Enclosure (1x)'),
              Text('• Display (1x)'),
              Text('• SMPS (1x)'),
              Text('• Manifold (1x)'),
              Text('• DP Sensor (1x)'),
              SizedBox(height: 8),
              Text('PCB Boards:'),
              Text('• Cape Board'),
              Text('• DIDO Board'),
              Text('• LED Board'),
            ],
          ),
        ),
        actions: [
          CustomButton(
            text: 'Got it',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
