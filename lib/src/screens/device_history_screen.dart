import 'package:flutter/material.dart';

class DeviceHistoryScreen extends StatefulWidget {
  const DeviceHistoryScreen({Key? key}) : super(key: key);

  @override
  State<DeviceHistoryScreen> createState() => _DeviceHistoryScreenState();
}

class _DeviceHistoryScreenState extends State<DeviceHistoryScreen> {
  String _selectedFilter = 'All';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Mock production history data
  final List<Map<String, dynamic>> _productionHistory = [
    {
      'id': 'PRD001',
      'deviceName': 'Air Leak Tester',
      'quantity': 5,
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'status': 'Completed',
      'pcbs': [
        {'name': 'Cape Board', 'qty': 5},
        {'name': 'DIDO Board', 'qty': 5},
        {'name': 'LED Board', 'qty': 5},
      ],
      'components': [
        {'name': 'Enclosure', 'qty': 5},
        {'name': 'Display', 'qty': 5},
        {'name': 'SMPS', 'qty': 5},
        {'name': 'Manifold', 'qty': 5},
      ],
      'materialsUsed': 75,
      'totalCost': 25000,
    },
    {
      'id': 'PRD002',
      'deviceName': 'Pressure Sensor Module',
      'quantity': 10,
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'status': 'Completed',
      'pcbs': [
        {'name': 'Sensor Board', 'qty': 10},
        {'name': 'Power Board', 'qty': 10},
      ],
      'components': [
        {'name': 'DP Sensor', 'qty': 10},
        {'name': 'Regulator', 'qty': 10},
        {'name': 'Filter', 'qty': 10},
      ],
      'materialsUsed': 120,
      'totalCost': 18000,
    },
    {
      'id': 'PRD003',
      'deviceName': 'Control Unit',
      'quantity': 3,
      'date': DateTime.now().subtract(const Duration(days: 8)),
      'status': 'In Progress',
      'pcbs': [
        {'name': 'Cape Board', 'qty': 3},
        {'name': 'DIDO Board', 'qty': 3},
      ],
      'components': [
        {'name': 'Enclosure', 'qty': 3},
        {'name': 'Display', 'qty': 3},
      ],
      'materialsUsed': 45,
      'totalCost': 15000,
    },
  ];

  List<Map<String, dynamic>> get _filteredHistory {
    var history = _productionHistory.where((item) {
      final matchesSearch =
          item['deviceName'].toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          item['id'].toLowerCase().contains(_searchQuery.toLowerCase());

      switch (_selectedFilter) {
        case 'Completed':
          return matchesSearch && item['status'] == 'Completed';
        case 'In Progress':
          return matchesSearch && item['status'] == 'In Progress';
        case 'This Week':
          final weekAgo = DateTime.now().subtract(const Duration(days: 7));
          return matchesSearch && item['date'].isAfter(weekAgo);
        case 'This Month':
          final monthAgo = DateTime.now().subtract(const Duration(days: 30));
          return matchesSearch && item['date'].isAfter(monthAgo);
        default:
          return matchesSearch;
      }
    }).toList();

    // Sort by date (newest first)
    history.sort((a, b) => b['date'].compareTo(a['date']));
    return history;
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

  void _showProductionDetails(Map<String, dynamic> production) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        production['deviceName'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Production ID: ${production['id']}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Quantity',
                    production['quantity'].toString(),
                    Icons.production_quantity_limits,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Materials Used',
                    production['materialsUsed'].toString(),
                    Icons.inventory_2,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Status',
                    production['status'],
                    Icons.info,
                    production['status'] == 'Completed'
                        ? Colors.green
                        : Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Date',
                    _formatDate(production['date']),
                    Icons.calendar_today,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'PCBs Used'),
                        Tab(text: 'Components Used'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // PCBs Tab
                          ListView.builder(
                            padding: const EdgeInsets.only(top: 16),
                            itemCount: production['pcbs'].length,
                            itemBuilder: (context, index) {
                              final pcb = production['pcbs'][index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Colors.green,
                                    child: Icon(
                                      Icons.memory,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(pcb['name']),
                                  trailing: Chip(
                                    label: Text('${pcb['qty']} pcs'),
                                    backgroundColor: Colors.green[100],
                                  ),
                                ),
                              );
                            },
                          ),
                          // Components Tab
                          ListView.builder(
                            padding: const EdgeInsets.only(top: 16),
                            itemCount: production['components'].length,
                            itemBuilder: (context, index) {
                              final component = production['components'][index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Colors.blue,
                                    child: Icon(
                                      Icons.category,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(component['name']),
                                  trailing: Chip(
                                    label: Text('${component['qty']} pcs'),
                                    backgroundColor: Colors.blue[100],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device History'),
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
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
                    hintText: 'Search devices or production ID...',
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        [
                              'All',
                              'Completed',
                              'In Progress',
                              'This Week',
                              'This Month',
                            ]
                            .map(
                              (filter) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(filter),
                                  selected: _selectedFilter == filter,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedFilter = selected
                                          ? filter
                                          : 'All';
                                    });
                                  },
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
            ),
          ),

          // Production History List
          Expanded(
            child: _filteredHistory.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No production history found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredHistory.length,
                    itemBuilder: (context, index) {
                      final production = _filteredHistory[index];
                      final isCompleted = production['status'] == 'Completed';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _showProductionDetails(production),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            production['deviceName'],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'ID: ${production['id']}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
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
                                        color: isCompleted
                                            ? Colors.green
                                            : Colors.orange,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        production['status'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Details Row
                                Row(
                                  children: [
                                    _buildInfoChip(
                                      '${production['quantity']} units',
                                      Icons.production_quantity_limits,
                                      Colors.blue,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildInfoChip(
                                      '${production['pcbs'].length} PCBs',
                                      Icons.memory,
                                      Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildInfoChip(
                                      _formatDate(production['date']),
                                      Icons.calendar_today,
                                      Colors.grey,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Materials Used
                                Row(
                                  children: [
                                    Icon(
                                      Icons.inventory_2,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${production['materialsUsed']} materials used',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
