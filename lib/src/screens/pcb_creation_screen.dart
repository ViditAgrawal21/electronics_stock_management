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

  // Mock data for available PCBs
  final List<Map<String, dynamic>> _availablePcbs = [
    {'name': 'Cape Board', 'components': 25, 'type': 'main'},
    {'name': 'DIDO Board', 'components': 18, 'type': 'io'},
    {'name': 'LED Board', 'components': 12, 'type': 'display'},
    {'name': 'Power Board', 'components': 15, 'type': 'power'},
    {'name': 'Sensor Board', 'components': 20, 'type': 'sensor'},
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
        (item) => item['name'] == component['name']
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
        (item) => item['name'] == pcb['name']
      );
      
      if (index >= 0) {
        _selectedPcbs.removeAt(index);
      } else {
        _selectedPcbs.add(Map.from(pcb));
      }
    });
  }

  void _updateComponentQuantity(int index, int newQty) {
    setState(() {
      _selectedComponents[index]['qty'] = newQty;
    });
  }

  Future<void> _checkMaterialAvailability() async {
    if (_selectedPcbs.isEmpty) {
      _showSnackBar('Please select at least one PCB', Colors.red);
      return;
    }

    final quantity = int.tryParse(_quantityController.text) ?? 1;
    
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);

    // Mock material availability check
    final bool hasEnoughMaterials = quantity <= 10; // Mock condition
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              hasEnoughMaterials ? Icons.check_circle : Icons.error,
              color: hasEnoughMaterials ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(hasEnoughMaterials ? 'Materials Available' : 'Insufficient Materials'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quantity to build: $quantity units'),
            const SizedBox(height: 8),
            Text('Selected PCBs: ${_selectedPcbs.length}'),
            const SizedBox(height: 8),
            Text(
              hasEnoughMaterials 
                ? 'All required materials are available in stock.'
                : 'Some materials are insufficient for the requested quantity.',
              style: TextStyle(
                color: hasEnoughMaterials ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          if (hasEnoughMaterials)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _createDevice();
              },
              child: const Text('Proceed'),
            ),
        ],
      ),
    );
  }

  Future<void> _createDevice() async {
    if (_deviceNameController.text.trim().isEmpty) {
      _showSnackBar('Please enter device name', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);

    _showSnackBar('Device created successfully!', Colors.green);
    
    // Reset form
    setState(() {
      _deviceNameController.clear();
      _quantityController.text = '1';
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
            // Device Information
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
                        prefixIcon: const Icon(Icons.production_quantity_limits),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sub Components Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sub Components',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select mechanical and electrical components',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableComponents.map((component) {
                        final isSelected = _selectedComponents.any(
                          (item) => item['name'] == component['name']
                        );
                        
                        return FilterChip(
                          selected: isSelected,
                          label: Text(component['name']),
                          avatar: Icon(
                            _getComponentIcon(component['type']),
                            size: 18,
                          ),
                          onSelected: (_) => _toggleComponent(component),
                        );
                      }).toList(),
                    ),

                    // Selected Components with Quantity
                    if (_selectedComponents.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Selected Components (${_selectedComponents.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._selectedComponents.asMap().entries.map((entry) {
                        final index = entry.key;
                        final component = entry.value;
                        
                        return ListTile(
                          dense: true,
                          leading: Icon(_getComponentIcon(component['type'])),
                          title: Text(component['name']),
                          trailing: SizedBox(
                            width: 80,
                            child: TextFormField(
                              initialValue: component['qty'].toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Qty',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                              ),
                              onChanged: (value) {
                                final qty = int.tryParse(value) ?? 1;
                                _updateComponentQuantity(index, qty);
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ],
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
                      'PCB Boards',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select PCB boards required for this device',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    
                    ...._availablePcbs.map((pcb) {
                      final isSelected = _selectedPcbs.any(
                        (item) => item['name'] == pcb['name']
                      );
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isSelected ? Colors.purple[50] : null,
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (_) => _togglePcb(pcb),
                          title: Text(
                            pcb['name'],
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text('${pcb['components']} components'),
                          secondary: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getPcbTypeColor(pcb['type']),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              pcb['type'].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _checkMaterialAvailability,
                    icon: _isLoading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.inventory_2),
                    label: Text(_isLoading ? 'Checking...' : 'Check Material Availability'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _createDevice,
                    icon: const Icon(Icons.add_circle),
                    label: const Text('Create Device'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getComponentIcon(String type) {
    switch (type) {
      case 'mechanical':
        return Icons.precision_manufacturing;
      case 'display':
        return Icons.monitor;
      case 'power':
        return Icons.power;
      case 'sensor':
        return Icons.sensors;
      default:
        return Icons.category;
    }
  }

  Color _getPcbTypeColor(String type) {
    switch (type) {
      case 'main':
        return Colors.blue;
      case 'io':
        return Colors.green;
      case 'display':
        return Colors.orange;
      case 'power':
        return Colors.red;
      case 'sensor':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}