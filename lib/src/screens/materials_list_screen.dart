import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_string.dart';
import '../constants/app_config.dart';
import 'package:electronics_stock_management/src/models/materials.dart'
    as model;
import '../providers/materials_providers.dart';
import '../widgets/materials_card.dart';
import '../widgets/search_bar.dart' as custom;
import '../widgets/filter.dart';
import '../widgets/custom_button.dart';
import '../utils/notifier.dart';

class MaterialsListScreen extends ConsumerStatefulWidget {
  const MaterialsListScreen({super.key});

  @override
  ConsumerState<MaterialsListScreen> createState() =>
      _MaterialsListScreenState();
}

class _MaterialsListScreenState extends ConsumerState<MaterialsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _currentFilter = 'All Materials';
  String _currentSort = 'Name (A-Z)';
  bool _isLoading = false;
  bool _showSaveButton = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Save current materials data locally using the provider's notifier
      await ref.read(materialsProvider.notifier).saveMaterialsLocally();

      if (mounted) {
        setState(() {
          _showSaveButton = false;
        });

        NotificationUtils.showSuccess(
          context,
          'Materials saved locally successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationUtils.showError(context, 'Save failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final materialsAsync = ref.watch(materialsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.materialsTitle),
        actions: [
          // Import Excel button
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: AppStrings.importExcel,
            onPressed: _isLoading
                ? null
                : () async {
                    await _handleImportExcel();
                    // Show save button after import
                    if (mounted) {
                      setState(() {
                        _showSaveButton = true;
                      });
                    }
                  },
          ),
          // Export Excel button
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: AppStrings.exportExcel,
            onPressed: _isLoading ? null : _handleExportExcel,
          ),
          // Save button (appears after import)
          if (_showSaveButton)
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save Data Locally',
              onPressed: _isLoading ? null : _handleSaveData,
            ),
          // More options
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'refresh':
                  _handleRefresh();
                  break;
                case 'clear':
                  _handleClearSearch();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear Search'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search bar
                custom.SearchBar(
                  controller: _searchController,
                  hintText: AppStrings.searchMaterials,
                  onChanged: (value) {
                    setState(() {});
                  },
                  onClear: _handleClearSearch,
                ),
                const SizedBox(height: 12),

                // Filter and sort row
                Row(
                  children: [
                    Expanded(
                      child: FilterChip(
                        label: Text(_currentFilter),
                        selected: _currentFilter != 'All Materials',
                        avatar: const Icon(Icons.filter_alt, size: 16),
                        onSelected: (_) => _showFilterDialog(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilterChip(
                        label: Text(_currentSort),
                        selected: _currentSort != 'Name (A-Z)',
                        avatar: const Icon(Icons.sort, size: 16),
                        onSelected: (_) => _showSortDialog(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Materials list
          Expanded(
            child: materialsAsync.when(
              data: (materials) => _buildMaterialsList(materials),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading materials',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: AppStrings.refresh,
                      onPressed: _handleRefresh,
                      icon: Icons.refresh,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // Floating action button for manual material addition
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMaterialDialog(),
        tooltip: 'Add Material',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMaterialsList(List<model.Material> allMaterials) {
    // Apply search filter
    List<model.Material> filteredMaterials = _searchController.text.isEmpty
        ? allMaterials
        : ref.read(materialSearchProvider(_searchController.text));

    // Apply category filter
    if (_currentFilter != 'All Materials') {
      filteredMaterials = ref
          .read(materialsProvider.notifier)
          .filterMaterials(_currentFilter);
    }

    // Apply sorting
    final sortedMaterials = ref.read(
      sortedMaterialsProvider({
        'materials': filteredMaterials,
        'sortType': _currentSort,
      }),
    );

    if (sortedMaterials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No materials found'
                  : 'No materials match your search',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isEmpty
                  ? 'Import Excel file or add materials manually'
                  : 'Try adjusting your search or filter',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (_searchController.text.isEmpty) ...[
              const SizedBox(height: 16),
              CustomButton(
                text: AppStrings.importExcel,
                onPressed: _handleImportExcel,
                icon: Icons.file_upload,
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _handleRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedMaterials.length,
        itemBuilder: (context, index) {
          final material = sortedMaterials[index];
          return MaterialsCard(
            material: material,
            onEdit: () => _showEditMaterialDialog(material),
            onDelete: () => _showDeleteMaterialDialog(material),
            onQuantityUpdate: (newQuantity) =>
                _handleQuantityUpdate(material, newQuantity),
          );
        },
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => FilterDialog(
        currentFilter: _currentFilter,
        options: AppConfig.filterOptions,
        onFilterChanged: (filter) {
          setState(() {
            _currentFilter = filter;
          });
        },
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => FilterDialog(
        title: 'Sort By',
        currentFilter: _currentSort,
        options: AppConfig.sortingOptions,
        onFilterChanged: (sort) {
          setState(() {
            _currentSort = sort;
          });
        },
      ),
    );
  }

  void _showAddMaterialDialog() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final descriptionController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Material'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Material Name',
                  prefixIcon: Icon(Icons.inventory),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter material name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Initial Quantity',
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter quantity';
                  }
                  if (int.tryParse(value) == null || int.parse(value) < 0) {
                    return 'Please enter valid quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(AppStrings.cancel),
          ),
          CustomButton(
            text: AppStrings.add,
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final material = model.Material(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  initialQuantity: int.parse(quantityController.text),
                  remainingQuantity: int.parse(quantityController.text),
                  createdAt: DateTime.now(),
                  lastUsedAt: DateTime.now(),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                );

                ref.read(materialsProvider.notifier).addMaterial(material);
                Navigator.of(context).pop();

                // Hide save button after user modification
                setState(() {
                  _showSaveButton = false;
                });

                NotificationUtils.showSuccess(
                  context,
                  'Material added successfully',
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showEditMaterialDialog(model.Material material) {
    final nameController = TextEditingController(text: material.name);
    final quantityController = TextEditingController(
      text: material.remainingQuantity.toString(),
    );
    final descriptionController = TextEditingController(
      text: material.description ?? '',
    );
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Material'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Material Name',
                  prefixIcon: Icon(Icons.inventory),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter material name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Remaining Quantity',
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter quantity';
                  }
                  if (int.tryParse(value) == null || int.parse(value) < 0) {
                    return 'Please enter valid quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          CustomButton(
            text: AppStrings.update,
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final updatedMaterial = material.copyWith(
                  name: nameController.text.trim(),
                  remainingQuantity: int.parse(quantityController.text),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                );

                ref
                    .read(materialsProvider.notifier)
                    .updateMaterial(updatedMaterial);
                Navigator.of(context).pop();

                // Hide save button after user modification
                setState(() {
                  _showSaveButton = false;
                });

                NotificationUtils.showSuccess(
                  context,
                  'Material updated successfully',
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteMaterialDialog(model.Material material) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: Text('Are you sure you want to delete "${material.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          CustomButton(
            text: AppStrings.delete,
            backgroundColor: Colors.red,
            onPressed: () {
              ref.read(materialsProvider.notifier).deleteMaterial(material.id);
              Navigator.of(context).pop();

              // Hide save button after user modification
              setState(() {
                _showSaveButton = false;
              });

              NotificationUtils.showSuccess(
                context,
                'Material deleted successfully',
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleQuantityUpdate(model.Material material, int newQuantity) {
    ref
        .read(materialsProvider.notifier)
        .updateRemainingQuantity(material.id, newQuantity);

    // Hide save button after user modification
    setState(() {
      _showSaveButton = false;
    });

    NotificationUtils.showSuccess(context, 'Quantity updated successfully');
  }

  Future<void> _handleImportExcel() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(materialsProvider.notifier).importMaterials();

      if (mounted) {
        // Clear search and reset filter after successful import
        _searchController.clear();
        setState(() {
          _currentFilter = 'All Materials';
          _currentSort = 'Name (A-Z)';
        });

        NotificationUtils.showSuccess(
          context,
          'Materials imported successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationUtils.showError(context, 'Import failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleExportExcel() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool success = await ref
          .read(materialsProvider.notifier)
          .exportMaterials();

      if (mounted) {
        if (success) {
          NotificationUtils.showSuccess(
            context,
            'Materials exported successfully',
          );
        } else {
          NotificationUtils.showError(context, 'Export failed');
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationUtils.showError(context, 'Export failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleRefresh() {
    // In a real app, you would reload data from storage
    setState(() {});
  }

  void _handleClearSearch() {
    _searchController.clear();
    setState(() {});
  }
}
