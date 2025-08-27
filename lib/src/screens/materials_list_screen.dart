import 'package:flutter/material.dart';

class MaterialListScreen extends StatefulWidget {
  const MaterialListScreen({Key? key}) : super(key: key);

  @override
  State<MaterialListScreen> createState() => _MaterialListScreenState();
}

class _MaterialListScreenState extends State<MaterialListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  bool _isLoading = false;

  // Mock data - will be replaced with actual service calls
  List<Map<String, dynamic>> _allMaterials = [
    {
      'name': 'Resistor 10K',
      'reference': 'R001',
      'quantity': 150,
      'used': 25,
      'remaining': 125,
      'minQuantity': 50,
      'unit': 'pcs',
    },
    {
      'name': 'Capacitor 100uF',
      'reference': 'C001',
      'quantity': 80,
      'used': 60,
      'remaining': 20,
      'minQuantity': 30,
      'unit': 'pcs',
    },
    {
      'name': 'LED Red 5mm',
      'reference': 'LED001',
      'quantity': 200,
      'used': 15,
      'remaining': 185,
      'minQuantity': 40,
      'unit': 'pcs',
    },
  ];

  List<Map<String, dynamic>> get _filteredMaterials {
    var materials = _allMaterials.where((material) {
      final matchesSearch =
          material['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          material['reference'].toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      switch (_selectedFilter) {
        case 'Low Stock':
          return matchesSearch &&
              material['remaining'] < material['minQuantity'];
        case 'Out of Stock':
          return matchesSearch && material['remaining'] == 0;
        case 'High Usage':
          return matchesSearch &&
              material['used'] > (material['quantity'] * 0.5);
        default:
          return matchesSearch;
      }
    }).toList();

    // Sort based on filter
    materials.sort((a, b) {
      switch (_selectedFilter) {
        case 'Alpha Order':
          return a['name'].compareTo(b['name']);
        case 'Min Quantity':
          return a['minQuantity'].compareTo(b['minQuantity']);
        case 'Max Quantity':
          return b['quantity'].compareTo(a['quantity']);
        default:
          return 0;
      }
    });

    return materials;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  Future<void> _importExcel() async {
    setState(() => _isLoading = true);

    // Simulate file picker and import
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Excel file imported successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _updateStock(int index, int newRemaining) {
    setState(() {
      _allMaterials[index]['remaining'] = newRemaining;
      _allMaterials[index]['used'] =
          _allMaterials[index]['quantity'] - newRemaining;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Stock updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showUpdateStockDialog(int index) {
    final material = _allMaterials[index];
    final controller = TextEditingController(
      text: material['remaining'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Stock: ${material['name']}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Remaining Quantity',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newQuantity = int.tryParse(controller.text) ?? 0;
              if (newQuantity >= 0 && newQuantity <= material['quantity']) {
                _updateStock(index, newQuantity);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid quantity!'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raw Materials'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _importExcel,
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import Excel',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search materials...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Chips
                Wrap(
                  spacing: 8,
                  children:
                      [
                            'All',
                            'Low Stock',
                            'Out of Stock',
                            'High Usage',
                            'Alpha Order',
                            'Min Quantity',
                            'Max Quantity',
                          ]
                          .map(
                            (filter) => FilterChip(
                              label: Text(filter),
                              selected: _selectedFilter == filter,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedFilter = selected ? filter : 'All';
                                });
                              },
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ),

          // Materials List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMaterials.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No materials found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredMaterials.length,
                    itemBuilder: (context, index) {
                      final material = _filteredMaterials[index];
                      final originalIndex = _allMaterials.indexOf(material);
                      final isLowStock =
                          material['remaining'] < material['minQuantity'];
                      final isOutOfStock = material['remaining'] == 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          material['name'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Ref: ${material['reference']}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isOutOfStock)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'OUT OF STOCK',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  else if (isLowStock)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'LOW STOCK',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Quantity Info
                              Row(
                                children: [
                                  _buildQuantityInfo(
                                    'Total',
                                    material['quantity'],
                                  ),
                                  _buildQuantityInfo('Used', material['used']),
                                  _buildQuantityInfo(
                                    'Remaining',
                                    material['remaining'],
                                    color: isOutOfStock
                                        ? Colors.red
                                        : isLowStock
                                        ? Colors.orange
                                        : Colors.green,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Update Stock Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _showUpdateStockDialog(originalIndex),
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Update Stock'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[50],
                                    foregroundColor: Colors.blue[700],
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _importExcel,
        backgroundColor: Colors.blue[600],
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Import Excel',
      ),
    );
  }

  Widget _buildQuantityInfo(String label, int value, {Color? color}) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
