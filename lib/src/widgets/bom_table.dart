import 'package:flutter/material.dart';

class MaterialCard extends StatefulWidget {
  final String materialName;
  final String reference;
  final int totalQuantity;
  final int remainingQuantity;
  final int usedQuantity;
  final String? footprint;
  final bool isLowStock;
  final VoidCallback? onEdit;
  final Function(int)? onQuantityUpdate;

  const MaterialCard({
    Key? key,
    required this.materialName,
    required this.reference,
    required this.totalQuantity,
    required this.remainingQuantity,
    required this.usedQuantity,
    this.footprint,
    this.isLowStock = false,
    this.onEdit,
    this.onQuantityUpdate,
  }) : super(key: key);

  @override
  State<MaterialCard> createState() => _MaterialCardState();
}

class _MaterialCardState extends State<MaterialCard> {
  final TextEditingController _quantityController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _quantityController.text = widget.remainingQuantity.toString();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _quantityController.text = widget.remainingQuantity.toString();
      _quantityController.selection = TextSelection.fromPosition(
        TextPosition(offset: _quantityController.text.length),
      );
    });
  }

  void _saveQuantity() {
    final newQuantity =
        int.tryParse(_quantityController.text) ?? widget.remainingQuantity;
    widget.onQuantityUpdate?.call(newQuantity);
    setState(() {
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Stock updated successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _quantityController.text = widget.remainingQuantity.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: widget.isLowStock
            ? const BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with material name and low stock indicator
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.materialName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (widget.isLowStock)
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
            const SizedBox(height: 8),

            // Reference
            Text(
              'Ref: ${widget.reference}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),

            if (widget.footprint != null) ...[
              const SizedBox(height: 4),
              Text(
                'Footprint: ${widget.footprint}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],

            const SizedBox(height: 16),

            // Quantity Information
            Row(
              children: [
                // Total Quantity
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        widget.totalQuantity.toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Used Quantity
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Used',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        widget.usedQuantity.toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),

                // Remaining Quantity (Editable)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Remaining',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      if (_isEditing) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _quantityController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  isDense: true,
                                ),
                                autofocus: true,
                                onSubmitted: (_) => _saveQuantity(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _saveQuantity,
                              icon: const Icon(
                                Icons.check,
                                color: Colors.green,
                              ),
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _cancelEditing,
                              icon: const Icon(Icons.close, color: Colors.red),
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ] else ...[
                        GestureDetector(
                          onTap: _startEditing,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: widget.isLowStock
                                  ? Colors.red[50]
                                  : Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: widget.isLowStock
                                    ? Colors.red
                                    : Colors.blue,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.remainingQuantity.toString(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: widget.isLowStock
                                        ? Colors.red
                                        : Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: widget.isLowStock
                                      ? Colors.red
                                      : Colors.blue,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // Progress Bar
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: widget.totalQuantity > 0
                  ? (widget.totalQuantity - widget.remainingQuantity) /
                        widget.totalQuantity
                  : 0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.isLowStock ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${((widget.totalQuantity - widget.remainingQuantity) / (widget.totalQuantity > 0 ? widget.totalQuantity : 1) * 100).toStringAsFixed(1)}% used',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
