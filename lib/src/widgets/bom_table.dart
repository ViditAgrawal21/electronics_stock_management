import 'package:flutter/material.dart';
import '../models/bom.dart';

class BomTable extends StatelessWidget {
  final List<BOMItem> bomItems;
  final Function(int, BOMItem)? onItemEdit;
  final Function(int)? onItemDelete;
  final bool isEditable;

  const BomTable({
    super.key,
    required this.bomItems,
    this.onItemEdit,
    this.onItemDelete,
    this.isEditable = true,
  });

  @override
  Widget build(BuildContext context) {
    if (bomItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: Text('No BOM items to display')),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DataTable(
          columnSpacing: 16,
          headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
          columns: const [
            DataColumn(
              label: Text(
                'Sr.No',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Reference',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Value',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Footprint',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text(
                'Layer',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Actions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: bomItems.asMap().entries.map((entry) {
            int index = entry.key;
            BOMItem item = entry.value;
            return _buildDataRow(context, index, item);
          }).toList(),
        ),
      ),
    );
  }

  DataRow _buildDataRow(BuildContext context, int index, BOMItem item) {
    return DataRow(
      cells: [
        DataCell(Text(item.serialNumber.toString())),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              item.reference,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.blue[700],
              ),
            ),
          ),
        ),
        DataCell(
          Container(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              item.value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(item.footprint, style: const TextStyle(fontSize: 11)),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              item.quantity.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ),
        ),
        DataCell(
          Chip(
            label: Text(
              item.layer.toUpperCase(),
              style: const TextStyle(fontSize: 10),
            ),
            backgroundColor: item.layer.toLowerCase() == 'top'
                ? Colors.orange[100]
                : Colors.purple[100],
            labelStyle: TextStyle(
              color: item.layer.toLowerCase() == 'top'
                  ? Colors.orange[700]
                  : Colors.purple[700],
            ),
          ),
        ),
        DataCell(
          isEditable
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onItemEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16),
                        onPressed: () => _showEditDialog(context, index, item),
                        tooltip: 'Edit',
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: const EdgeInsets.all(4),
                      ),
                    if (onItemDelete != null)
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          size: 16,
                          color: Colors.red[600],
                        ),
                        onPressed: () =>
                            _showDeleteDialog(context, index, item),
                        tooltip: 'Delete',
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: const EdgeInsets.all(4),
                      ),
                  ],
                )
              : const SizedBox(),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context, int index, BOMItem item) {
    final serialController = TextEditingController(
      text: item.serialNumber.toString(),
    );
    final referenceController = TextEditingController(text: item.reference);
    final materialController = TextEditingController(text: item.materialName);
    final footprintController = TextEditingController(text: item.footprint);
    final quantityController = TextEditingController(
      text: item.quantity.toString(),
    );

    // Fix: Ensure the layer value is valid
    String selectedLayer = item.layer.toLowerCase();
    if (!['top', 'bottom'].contains(selectedLayer)) {
      selectedLayer = 'top'; // Default to 'top' if invalid
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit BOM Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: serialController,
                  decoration: const InputDecoration(labelText: 'Serial Number'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: referenceController,
                  decoration: const InputDecoration(labelText: 'Reference'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: materialController,
                  decoration: const InputDecoration(labelText: 'Material Name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: footprintController,
                  decoration: const InputDecoration(labelText: 'Footprint'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedLayer,
                  decoration: const InputDecoration(labelText: 'Layer'),
                  items: const [
                    DropdownMenuItem(value: 'top', child: Text('Top')),
                    DropdownMenuItem(value: 'bottom', child: Text('Bottom')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedLayer = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final updatedItem = item.copyWith(
                  serialNumber:
                      int.tryParse(serialController.text) ?? item.serialNumber,
                  reference: referenceController.text.trim(),
                  materialName: materialController.text.trim(),
                  footprint: footprintController.text.trim(),
                  quantity:
                      int.tryParse(quantityController.text) ?? item.quantity,
                  layer: selectedLayer,
                );

                onItemEdit?.call(index, updatedItem);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, int index, BOMItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete BOM Item'),
        content: Text(
          'Are you sure you want to delete "${item.reference} - ${item.materialName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onItemDelete?.call(index);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class BomSummaryCard extends StatelessWidget {
  final BOM bom;

  const BomSummaryCard({super.key, required this.bom});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BOM Summary',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Components',
                    bom.totalComponents.toString(),
                    Icons.inventory,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Unique Parts',
                    bom.uniqueComponents.toString(),
                    Icons.category,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Top Layer',
                    bom.getComponentsByLayer('top').length.toString(),
                    Icons.layers,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Bottom Layer',
                    bom.getComponentsByLayer('bottom').length.toString(),
                    Icons.layers,
                    Colors.purple,
                  ),
                ),
              ],
            ),
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
      margin: const EdgeInsets.only(right: 8),
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
              fontSize: 18,
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
}
