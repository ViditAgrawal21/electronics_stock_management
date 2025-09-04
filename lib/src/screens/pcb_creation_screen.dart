import 'package:flutter/material.dart';

class PcbCreationScreen extends StatefulWidget {
  const PcbCreationScreen({Key? key}) : super(key: key);

  @override
  State<PcbCreationScreen> createState() => _PcbCreationScreenState();
}

class _PcbCreationScreenState extends State<PcbCreationScreen> {
  final _deviceNameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  bool _isLoading = false;

  List<Map<String, dynamic>> _selectedComponents = [];
  List<Map<String, dynamic>> _selectedPcbs = [];

  // Mock data for available components
  final List<Map<String, dynamic>> _availableComponents = [
    {'name': 'Enclosure', 'qty': 1, 'type': 'mechanical'},
    {'name': 'Display', 'qty': 1, 'type': 'display'},
    {'name': 'SMPS', 'qty': 1, 'type': 'power'},
    {'name': 'Manifold', 'qty': 1, 'type': 'mechanical'},
    {'name': 'DP Sensor', 'qty': 1, 'type': 'sensor'},
    {'name': 'Reskit', 'qty': 1, 'type': 'mechanical'},
    {'name': 'Regulator', 'qty': 1, 'type': 'mechanical'},
    {'name': 'Filter', 'qty': 1, 'type': 'mechanical'},
    {'name': 'Calport', 'qty': 1, 'type': 'mechanical'},
    {'name': 'Nut', 'qty': 1, 'type': 'mechanical'},
  ];

  // Mock data for available PCBs with BOM
  final List<Map<String, dynamic>> _availablePcbs = [
    {'name': 'Cape Board', 'components': 25, 'type': 'main', 'hasBom': true},
    {'name': 'DIDO Board', 'components': 18, 'type': 'io', 'hasBom': true},
    {'name': 'LED Board', 'components': 12, 'type': 'display', 'hasBom': false},
    {'name': 'Power Board', 'components': 15, 'type': 'power', 'hasBom': false},
    {
      'name': 'Sensor Board',
      'components': 20,
      'type': 'sensor',
      'hasBom': true,
    },
  ];

  @override
  void dispose() {
    _deviceNameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _toggleComponent(Map<String, dynamic> component) {
    setState(() {
      final index = _selectedComponents.indexWhere(
        (item) => item['name'] == component['name'],
      );

      if (index >= 0) {
        _selectedComponents.removeAt(index);
      } else {
        _selectedComponents.add(Map.from(component));
      }
    });
  }

  void _togglePcb(Map<String, dynamic> pcb) {
    setState(() {
      final index = _selectedPcbs.indexWhere(
        (item) => item['name'] == pcb['name'],
      );

      if (index >= 0) {
        _selectedPcbs.removeAt(index);
      } else {
        _selectedPcbs.add(Map.from(pcb));
      }
    });
  }

  void _updateComponentQuantity(int index, int newQty) {
    if (newQty > 0) {
      setState(() {
        _selectedComponents[index]['qty'] = newQty;
      });
    }
  }

  Future<void> _checkMaterialRequirements() async {
    if (_deviceNameController.text.trim().isEmpty) {
      _showSnackBar('Please enter device name', Colors.red);
      return;
    }

    final quantity = int.tryParse(_quantityController.text) ?? 1;
    if (quantity <= 0) {
      _showSnackBar('Please enter valid quantity', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    // Mock calculation result
    final totalComponentsNeeded =
        _selectedComponents.fold(0, (sum, comp) => sum + (comp['qty'] as int)) *
        quantity;
    final totalPcbComponentsNeeded =
        _selectedPcbs.fold(0, (sum, pcb) => sum + (pcb['components'] as int)) *
        quantity;

    setState(() => _isLoading = false);

    _showMaterialRequirementsDialog(
      quantity,
      totalComponentsNeeded,
      totalPcbComponentsNeeded,
    );
  }

  void _showMaterialRequirementsDialog(
    int quantity,
    int componentCount,
    int pcbComponentCount,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Material Requirements'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Device: ${_deviceNameController.text}'),
            Text('Quantity to build: $quantity'),
            const Divider(),
            Text('Components needed: $componentCount'),
            Text('PCB components needed: $pcbComponentCount'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600]),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'All materials available in stock',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createDevice();
            },
            child: const Text('Create Device'),
          ),
        ],
      ),
    );
  }

  Future<void> _createDevice() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);

    _showSnackBar('Device created successfully!', Colors.green);

    // Clear form
    _deviceNameController.clear();
    _quantityController.text = '1';
    setState(() {
      _selectedComponents.clear();
      _selectedPcbs.clear();
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PCB Creation'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Device Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _deviceNameController,
                      decoration: InputDecoration(
                        labelText: 'Device Name',
                        hintText: 'e.g., Air Leak Tester',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.devices),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity to Build',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(
                          Icons.production_quantity_limits,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Components Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Components',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableComponents.map((component) {
                        final isSelected = _selectedComponents.any(
                          (item) => item['name'] == component['name'],
                        );
                        return FilterChip(
                          label: Text(component['name']),
                          selected: isSelected,
                          onSelected: (_) => _toggleComponent(component),
                          avatar: Icon(
                            _getComponentIcon(component['type']),
                            size: 16,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // PCB Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select PCBs',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...(_availablePcbs.map((pcb) {
                      final isSelected = _selectedPcbs.any(
                        (item) => item['name'] == pcb['name'],
                      );
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          color: isSelected ? Colors.purple[50] : Colors.white,
                          child: CheckboxListTile(
                            title: Text(pcb['name']),
                            subtitle: Text(
                              '${pcb['components']} components • ${pcb['hasBom'] ? 'BOM Available' : 'No BOM'}',
                            ),
                            secondary: Icon(
                              Icons.memory,
                              color: pcb['hasBom'] ? Colors.green : Colors.grey,
                            ),
                            value: isSelected,
                            onChanged: (_) => _togglePcb(pcb),
                            activeColor: Colors.purple[600],
                          ),
                        ),
                      );
                    }).toList()),
                  ],
                ),
              ),
            ),

            // Summary Section
            if (_selectedComponents.isNotEmpty || _selectedPcbs.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Build Summary',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text('Components: ${_selectedComponents.length}'),
                      Text('PCBs: ${_selectedPcbs.length}'),
                      Text('Quantity: ${_quantityController.text}'),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : _checkMaterialRequirements,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.calculate),
                          label: Text(
                            _isLoading
                                ? 'Calculating...'
                                : 'Check Materials & Create',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to BOM upload
          Navigator.pushNamed(context, '/bom-upload');
        },
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload),
        label: const Text('Upload BOM'),
      ),
    );
  }

  IconData _getComponentIcon(String type) {
    switch (type) {
      case 'mechanical':
        return Icons.build;
      case 'display':
        return Icons.monitor;
      case 'power':
        return Icons.electrical_services;
      case 'sensor':
        return Icons.sensors;
      default:
        return Icons.memory;
    }
  }
}
