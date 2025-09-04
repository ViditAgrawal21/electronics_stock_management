import 'package:flutter/material.dart';
import '../models/materials.dart' as model;
import '../theme/app_theme.dart';
import '../theme/text_styles.dart';

class MaterialsCard extends StatefulWidget {
  final model.Material material;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(int)? onQuantityUpdate;

  const MaterialsCard({
    super.key,
    required this.material,
    this.onEdit,
    this.onDelete,
    this.onQuantityUpdate,
  });

  @override
  State<MaterialsCard> createState() => _MaterialsCardState();
}

class _MaterialsCardState extends State<MaterialsCard> {
  final TextEditingController _quantityController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _quantityController.text = widget.material.remainingQuantity.toString();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final material = widget.material;
    final statusColor = AppTheme.getStockStatusColor(material.stockStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with name and status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        material.name,
                        style: AppTextStyles.cardTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (material.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          material.description!,
                          style: AppTextStyles.cardSubtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildStatusChip(material.stockStatus, statusColor),
              ],
            ),
            const SizedBox(height: 16),

            // Quantity information
            Row(
              children: [
                Expanded(
                  child: _buildQuantityInfo(
                    'Initial',
                    material.initialQuantity,
                    Colors.blue,
                    Icons.inventory_2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuantityInfo(
                    'Remaining',
                    material.remainingQuantity,
                    statusColor,
                    Icons.store,
                    isEditable: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuantityInfo(
                    'Used',
                    material.calculatedUsedQuantity,
                    Colors.grey,
                    Icons.remove_circle_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress bar
            _buildProgressBar(),
            const SizedBox(height: 16),

            // Action buttons and last used info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Last Used', style: AppTextStyles.dateText),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(material.lastUsedAt),
                        style: AppTextStyles.dateText.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildActionButtons(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(status, style: AppTextStyles.chipText.copyWith(color: color)),
    );
  }

  Widget _buildQuantityInfo(
    String label,
    int quantity,
    Color color,
    IconData icon, {
    bool isEditable = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (isEditable && _isEditing)
            SizedBox(
              height: 30,
              child: TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                style: AppTextStyles.quantityText.copyWith(color: color),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                  isDense: true,
                ),
                onFieldSubmitted: _handleQuantitySubmit,
              ),
            )
          else
            GestureDetector(
              onTap: isEditable
                  ? () => setState(() => _isEditing = true)
                  : null,
              child: Text(
                quantity.toString(),
                style: AppTextStyles.quantityText.copyWith(color: color),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final material = widget.material;
    double progress = material.initialQuantity > 0
        ? (material.initialQuantity - material.remainingQuantity) /
              material.initialQuantity
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Usage Progress',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            AppTheme.getStockQuantityColor(
              material.remainingQuantity,
              material.initialQuantity,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isEditing) ...[
          // Save and cancel buttons when editing
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () => _handleQuantitySubmit(_quantityController.text),
            tooltip: 'Save',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: const EdgeInsets.all(4),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: _cancelEdit,
            tooltip: 'Cancel',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: const EdgeInsets.all(4),
          ),
        ] else ...[
          // Regular action buttons
          if (widget.onEdit != null)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue[600]),
              onPressed: widget.onEdit,
              tooltip: 'Edit',
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: const EdgeInsets.all(4),
            ),
          if (widget.onDelete != null)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red[600]),
              onPressed: widget.onDelete,
              tooltip: 'Delete',
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: const EdgeInsets.all(4),
            ),
        ],
      ],
    );
  }

  void _handleQuantitySubmit(String value) {
    final newQuantity = int.tryParse(value);
    if (newQuantity != null &&
        newQuantity >= 0 &&
        newQuantity <= widget.material.initialQuantity) {
      widget.onQuantityUpdate?.call(newQuantity);
      setState(() {
        _isEditing = false;
      });
    } else {
      // Reset to original value if invalid
      _quantityController.text = widget.material.remainingQuantity.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid quantity. Please enter a valid number.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cancelEdit() {
    _quantityController.text = widget.material.remainingQuantity.toString();
    setState(() {
      _isEditing = false;
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
