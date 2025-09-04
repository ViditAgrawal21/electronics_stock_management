import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';

class FilterDialog extends StatefulWidget {
  final String title;
  final String currentFilter;
  final List<String> options;
  final Function(String) onFilterChanged;

  const FilterDialog({
    super.key,
    this.title = 'Filter By',
    required this.currentFilter,
    required this.options,
    required this.onFilterChanged,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late String selectedFilter;

  @override
  void initState() {
    super.initState();
    selectedFilter = widget.currentFilter;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: widget.options.map((option) {
          return RadioListTile<String>(
            title: Text(option),
            value: option,
            groupValue: selectedFilter,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedFilter = value;
                });
              }
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        CustomButton(
          text: 'Apply',
          onPressed: () {
            widget.onFilterChanged(selectedFilter);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class FilterChipGroup extends StatelessWidget {
  final List<FilterOption> options;
  final List<String> selectedFilters;
  final Function(List<String>) onFiltersChanged;
  final bool allowMultiple;

  const FilterChipGroup({
    super.key,
    required this.options,
    required this.selectedFilters,
    required this.onFiltersChanged,
    this.allowMultiple = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: options.map((option) {
        final isSelected = selectedFilters.contains(option.value);

        return FilterChip(
          label: Text(option.label),
          selected: isSelected,
          onSelected: (selected) {
            List<String> newFilters = List.from(selectedFilters);

            if (allowMultiple) {
              if (selected) {
                newFilters.add(option.value);
              } else {
                newFilters.remove(option.value);
              }
            } else {
              newFilters = selected ? [option.value] : [];
            }

            onFiltersChanged(newFilters);
          },
          avatar: option.icon != null ? Icon(option.icon, size: 16) : null,
          backgroundColor: Colors.grey[200],
          selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
          checkmarkColor: Theme.of(context).primaryColor,
        );
      }).toList(),
    );
  }
}

class FilterOption {
  final String label;
  final String value;
  final IconData? icon;
  final Color? color;

  const FilterOption({
    required this.label,
    required this.value,
    this.icon,
    this.color,
  });
}

class AdvancedFilterBottomSheet extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onFiltersChanged;

  const AdvancedFilterBottomSheet({
    super.key,
    required this.currentFilters,
    required this.onFiltersChanged,
  });

  @override
  State<AdvancedFilterBottomSheet> createState() =>
      _AdvancedFilterBottomSheetState();
}

class _AdvancedFilterBottomSheetState extends State<AdvancedFilterBottomSheet> {
  late Map<String, dynamic> filters;
  final TextEditingController _minQuantityController = TextEditingController();
  final TextEditingController _maxQuantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filters = Map.from(widget.currentFilters);
    _minQuantityController.text = filters['minQuantity']?.toString() ?? '';
    _maxQuantityController.text = filters['maxQuantity']?.toString() ?? '';
  }

  @override
  void dispose() {
    _minQuantityController.dispose();
    _maxQuantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Advanced Filters',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _clearAllFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stock Status Filter
          Text(
            'Stock Status',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          FilterChipGroup(
            options: const [
              FilterOption(
                label: 'In Stock',
                value: 'inStock',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
              FilterOption(
                label: 'Low Stock',
                value: 'lowStock',
                icon: Icons.warning,
                color: Colors.orange,
              ),
              FilterOption(
                label: 'Critical',
                value: 'critical',
                icon: Icons.error,
                color: Colors.red,
              ),
              FilterOption(
                label: 'Out of Stock',
                value: 'outOfStock',
                icon: Icons.cancel,
                color: Colors.red,
              ),
            ],
            selectedFilters: List<String>.from(filters['stockStatus'] ?? []),
            onFiltersChanged: (selected) {
              setState(() {
                filters['stockStatus'] = selected;
              });
            },
            allowMultiple: true,
          ),
          const SizedBox(height: 16),

          // Quantity Range
          Text(
            'Quantity Range',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minQuantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Min Quantity',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    filters['minQuantity'] = int.tryParse(value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _maxQuantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Max Quantity',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    filters['maxQuantity'] = int.tryParse(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Usage Status
          Text(
            'Usage Status',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          FilterChipGroup(
            options: const [
              FilterOption(
                label: 'Never Used',
                value: 'neverUsed',
                icon: Icons.new_releases,
              ),
              FilterOption(
                label: 'Recently Used',
                value: 'recentlyUsed',
                icon: Icons.access_time,
              ),
              FilterOption(
                label: 'Frequently Used',
                value: 'frequentlyUsed',
                icon: Icons.trending_up,
              ),
            ],
            selectedFilters: List<String>.from(filters['usageStatus'] ?? []),
            onFiltersChanged: (selected) {
              setState(() {
                filters['usageStatus'] = selected;
              });
            },
            allowMultiple: true,
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: CustomOutlinedButton(
                  text: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  text: 'Apply Filters',
                  onPressed: () {
                    widget.onFiltersChanged(filters);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      filters.clear();
      _minQuantityController.clear();
      _maxQuantityController.clear();
    });
  }
}

// Helper function to show advanced filter bottom sheet
void showAdvancedFilterBottomSheet(
  BuildContext context, {
  required Map<String, dynamic> currentFilters,
  required Function(Map<String, dynamic>) onFiltersChanged,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => AdvancedFilterBottomSheet(
      currentFilters: currentFilters,
      onFiltersChanged: onFiltersChanged,
    ),
  );
}
