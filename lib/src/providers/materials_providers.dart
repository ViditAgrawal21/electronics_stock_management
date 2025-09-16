import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:electronics_stock_management/src/models/materials.dart';
import '../services/excel_service.dart';
import '../utils/search_trie.dart';
import '../constants/app_config.dart';
import 'dart:math' as math;

// Hive box name constant
const String _materialsBoxName = 'materials_box';

// Materials state notifier
class MaterialsNotifier extends StateNotifier<AsyncValue<List<Material>>> {
  MaterialsNotifier() : super(const AsyncValue.loading()) {
    _loadMaterials();
  }

  final SearchTrie _searchTrie = SearchTrie();
  List<Material> _allMaterials = [];

  // Get Hive box for materials
  Future<Box<Material>> _getMaterialsBox() async {
    return await Hive.openBox<Material>(_materialsBoxName);
  }

  // Load materials (from Hive or initialize empty)
  Future<void> _loadMaterials() async {
    try {
      await loadMaterialsFromLocal();
    } catch (error, stackTrace) {
      print('Error loading materials: $error');
      _allMaterials = [];
      _rebuildSearchTrie();
      state = AsyncValue.data(_allMaterials);
    }
  }

  // Import materials from Excel
  Future<void> importMaterials() async {
    try {
      state = const AsyncValue.loading();
      List<Material> importedMaterials = await ExcelService.importMaterials();

      // Merge with existing materials (avoid duplicates by name)
      Map<String, Material> materialMap = {};

      // Add existing materials
      for (Material material in _allMaterials) {
        materialMap[material.name.toLowerCase()] = material;
      }

      // Add imported materials (overwrite if same name)
      for (Material material in importedMaterials) {
        materialMap[material.name.toLowerCase()] = material;
      }

      _allMaterials = materialMap.values.toList();
      _rebuildSearchTrie();
      state = AsyncValue.data(_allMaterials);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Export materials to Excel
  Future<bool> exportMaterials() async {
    try {
      return await ExcelService.exportMaterials(_allMaterials);
    } catch (error) {
      return false;
    }
  }

  // Add single material
  Future<void> addMaterial(Material material) async {
    try {
      _allMaterials.add(material);
      _searchTrie.insert(material.name, material.id);
      state = AsyncValue.data(List.from(_allMaterials));

      // Save to Hive immediately
      final box = await _getMaterialsBox();
      await box.put(material.id, material);
    } catch (e) {
      print('Error adding material: $e');
    }
  }

  // Update material
  Future<void> updateMaterial(Material updatedMaterial) async {
    try {
      int index = _allMaterials.indexWhere((m) => m.id == updatedMaterial.id);
      if (index != -1) {
        Material oldMaterial = _allMaterials[index];
        _allMaterials[index] = updatedMaterial;

        // Update search trie if name changed
        if (oldMaterial.name != updatedMaterial.name) {
          _searchTrie.update(
            oldMaterial.name,
            updatedMaterial.name,
            updatedMaterial.id,
          );
        }

        state = AsyncValue.data(List.from(_allMaterials));

        // Update in Hive immediately
        final box = await _getMaterialsBox();
        await box.put(updatedMaterial.id, updatedMaterial);
      }
    } catch (e) {
      print('Error updating material: $e');
    }
  }

  // Update remaining quantity only
  Future<void> updateRemainingQuantity(
    String materialId,
    int newQuantity,
  ) async {
    try {
      int index = _allMaterials.indexWhere((m) => m.id == materialId);
      if (index != -1) {
        _allMaterials[index] = _allMaterials[index].copyWith(
          remainingQuantity: newQuantity,
          usedQuantity: _allMaterials[index].initialQuantity - newQuantity,
          lastUsedAt: DateTime.now(),
        );
        state = AsyncValue.data(List.from(_allMaterials));

        // Update in Hive immediately
        final box = await _getMaterialsBox();
        await box.put(materialId, _allMaterials[index]);
      }
    } catch (e) {
      print('Error updating quantity: $e');
    }
  }

  // Use materials (decrease remaining quantity)
  Future<void> useMaterials(Map<String, int> materialsToUse) async {
    try {
      final box = await _getMaterialsBox();

      for (String materialId in materialsToUse.keys) {
        int quantityToUse = materialsToUse[materialId] ?? 0;
        int index = _allMaterials.indexWhere((m) => m.id == materialId);

        if (index != -1) {
          Material material = _allMaterials[index];
          int newRemainingQuantity =
              (material.remainingQuantity - quantityToUse).clamp(
                0,
                material.initialQuantity,
              );

          _allMaterials[index] = material.copyWith(
            remainingQuantity: newRemainingQuantity,
            usedQuantity: material.initialQuantity - newRemainingQuantity,
            lastUsedAt: DateTime.now(),
          );

          // Update in Hive
          await box.put(materialId, _allMaterials[index]);
        }
      }

      state = AsyncValue.data(List.from(_allMaterials));
    } catch (e) {
      print('Error using materials: $e');
    }
  }

  // Use materials by names (decrease remaining quantity)
  Future<void> useMaterialsByNames(Map<String, int> materialNamesToUse) async {
    try {
      print('=== Starting useMaterialsByNames ===');
      final box = await _getMaterialsBox();
      Map<String, int> processedMaterials = {};
      bool hasChanges = false;

      for (String materialName in materialNamesToUse.keys) {
        int quantityToUse = materialNamesToUse[materialName] ?? 0;

        // Find material by name (case insensitive)
        int index = _allMaterials.indexWhere(
          (m) =>
              m.name.toLowerCase().trim() == materialName.toLowerCase().trim(),
        );

        if (index != -1) {
          Material oldMaterial = _allMaterials[index];
          print(
            'BEFORE: ${oldMaterial.name} - Remaining: ${oldMaterial.remainingQuantity}, Used: ${oldMaterial.usedQuantity}',
          );

          int newRemainingQuantity =
              (oldMaterial.remainingQuantity - quantityToUse).clamp(
                0,
                oldMaterial.initialQuantity,
              );
          int newUsedQuantity =
              oldMaterial.initialQuantity - newRemainingQuantity;

          Material updatedMaterial = oldMaterial.copyWith(
            remainingQuantity: newRemainingQuantity,
            usedQuantity: newUsedQuantity, // Explicitly set used quantity
            lastUsedAt: DateTime.now(),
          );

          _allMaterials[index] = updatedMaterial;
          print(
            'AFTER: ${updatedMaterial.name} - Remaining: ${updatedMaterial.remainingQuantity}, Used: ${updatedMaterial.usedQuantity}',
          );

          // Update in Hive
          await box.put(updatedMaterial.id, updatedMaterial);
          processedMaterials[materialName] = quantityToUse;
          hasChanges = true;

          print(
            'Used $quantityToUse units of "$materialName" (ID: ${updatedMaterial.id})',
          );
        } else {
          print('WARNING: Material "$materialName" not found in inventory');
        }
      }

      // CRITICAL: Force state update with delay to ensure all updates are complete
      if (hasChanges) {
        print('=== Forcing state update ===');
        state = AsyncValue.data(List.from(_allMaterials));

        // Add small delay to ensure state propagation
        await Future.delayed(const Duration(milliseconds: 100));

        // Force another state notification
        state = AsyncValue.data(List.from(_allMaterials));
        print(
          'UI state forcefully updated - Material count: ${_allMaterials.length}',
        );
      }

      print(
        'Successfully processed ${processedMaterials.length} materials by name',
      );
      print('=== Finished useMaterialsByNames ===');
    } catch (e) {
      print('Error using materials by names: $e');
      rethrow;
    }
  }

  Future<void> addMaterialsByNames(Map<String, int> materialNamesToAdd) async {
    try {
      final box = await _getMaterialsBox();

      for (String materialName in materialNamesToAdd.keys) {
        int quantityToAdd = materialNamesToAdd[materialName] ?? 0;

        int index = _allMaterials.indexWhere(
          (m) =>
              m.name.toLowerCase().trim() == materialName.toLowerCase().trim(),
        );

        if (index != -1) {
          Material material = _allMaterials[index];
          int newRemainingQuantity =
              (material.remainingQuantity + quantityToAdd).clamp(
                0,
                material.initialQuantity,
              );

          _allMaterials[index] = material.copyWith(
            remainingQuantity: newRemainingQuantity,
            usedQuantity: material.initialQuantity - newRemainingQuantity,
            lastUsedAt: DateTime.now(),
          );

          await box.put(material.id, _allMaterials[index]);
          print('Added back $quantityToAdd units to "${materialName}"');
        }
      }

      state = AsyncValue.data(List.from(_allMaterials));
    } catch (e) {
      print('Error adding materials by names: $e');
      rethrow;
    }
  }

  // NEW: Get detailed material analysis for BOM validation
  Map<String, dynamic> analyzeMaterialRequirements(
    Map<String, int> requiredMaterials,
  ) {
    List<String> availableMaterials = [];
    List<String> missingMaterials = [];
    Map<String, int> availableQuantities = {};
    Map<String, int> shortages = {};
    Map<String, Material> foundMaterials = {};
    bool canProduce = true;

    for (String materialName in requiredMaterials.keys) {
      int requiredQty = requiredMaterials[materialName] ?? 0;

      // Find material by name (case insensitive, trimmed)
      Material? material = _allMaterials
          .where(
            (m) =>
                m.name.toLowerCase().trim() ==
                materialName.toLowerCase().trim(),
          )
          .firstOrNull;

      if (material != null) {
        availableMaterials.add(materialName);
        availableQuantities[materialName] = material.remainingQuantity;
        foundMaterials[materialName] = material;

        if (material.remainingQuantity < requiredQty) {
          shortages[materialName] = requiredQty - material.remainingQuantity;
          canProduce = false;
        }
      } else {
        missingMaterials.add(materialName);
        availableQuantities[materialName] = 0;
        shortages[materialName] = requiredQty;
        canProduce = false;
      }
    }

    return {
      'canProduce': canProduce,
      'availableMaterials': availableMaterials,
      'missingMaterials': missingMaterials,
      'availableQuantities': availableQuantities,
      'shortages': shortages,
      'foundMaterials': foundMaterials,
      'totalRequired': requiredMaterials.values.fold(
        0,
        (sum, qty) => sum + qty,
      ),
      'totalAvailable': availableQuantities.values.fold(
        0,
        (sum, qty) => sum + qty,
      ),
      'matchPercentage': missingMaterials.isEmpty
          ? 100.0
          : (availableMaterials.length / requiredMaterials.length) * 100,
    };
  }
  // Add this method to your MaterialsNotifier class in materials_providers.dart

  // NEW: Calculate maximum producible quantity for a set of materials
  int calculateMaxProducibleQuantity(
    Map<String, int> materialRequirementsPerUnit,
  ) {
    if (materialRequirementsPerUnit.isEmpty) return 0;

    int maxQuantity = double.maxFinite.toInt();

    for (String materialName in materialRequirementsPerUnit.keys) {
      int requiredPerUnit = materialRequirementsPerUnit[materialName] ?? 0;
      if (requiredPerUnit <= 0) continue;

      // Find material by name (case insensitive)
      Material? material = _allMaterials
          .where(
            (m) =>
                m.name.toLowerCase().trim() ==
                materialName.toLowerCase().trim(),
          )
          .firstOrNull;

      if (material != null) {
        int possibleFromThisMaterial =
            material.remainingQuantity ~/ requiredPerUnit;
        maxQuantity = math.min(maxQuantity, possibleFromThisMaterial);
      } else {
        // Material not found, can't produce any
        return 0;
      }
    }

    return maxQuantity == double.maxFinite.toInt() ? 0 : maxQuantity;
  }

  // Delete material
  Future<void> deleteMaterial(String materialId) async {
    try {
      Material? materialToDelete = _allMaterials
          .where((m) => m.id == materialId)
          .firstOrNull;
      if (materialToDelete != null) {
        _allMaterials.removeWhere((m) => m.id == materialId);
        _searchTrie.remove(materialToDelete.name, materialId);
        state = AsyncValue.data(List.from(_allMaterials));

        // Delete from Hive
        final box = await _getMaterialsBox();
        await box.delete(materialId);
      }
    } catch (e) {
      print('Error deleting material: $e');
    }
  }

  // Search materials using Trie
  List<Material> searchMaterials(String query) {
    if (query.isEmpty) return _allMaterials;

    List<String> matchingIds = _searchTrie.search(query);
    return _allMaterials
        .where((material) => matchingIds.contains(material.id))
        .toList();
  }

  // Filter materials
  List<Material> filterMaterials(String filterType) {
    switch (filterType) {
      case 'Low Stock':
        return _allMaterials.where((m) => m.isLowStock).toList();
      case 'Critical Stock':
        return _allMaterials.where((m) => m.isCriticalStock).toList();
      case 'Out of Stock':
        return _allMaterials.where((m) => m.isOutOfStock).toList();
      case 'Never Used':
        return _allMaterials.where((m) => m.usedQuantity == 0).toList();
      case 'Recently Used':
        DateTime oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
        return _allMaterials
            .where((m) => m.lastUsedAt.isAfter(oneWeekAgo))
            .toList();
      default:
        return _allMaterials;
    }
  }

  // Sort materials
  List<Material> sortMaterials(List<Material> materials, String sortType) {
    List<Material> sortedList = List.from(materials);

    switch (sortType) {
      case 'Name (A-Z)':
        sortedList.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case 'Name (Z-A)':
        sortedList.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
        break;
      case 'Quantity (High-Low)':
        sortedList.sort(
          (a, b) => b.remainingQuantity.compareTo(a.remainingQuantity),
        );
        break;
      case 'Quantity (Low-High)':
        sortedList.sort(
          (a, b) => a.remainingQuantity.compareTo(b.remainingQuantity),
        );
        break;
      case 'Most Used':
        sortedList.sort((a, b) => b.usedQuantity.compareTo(a.usedQuantity));
        break;
      case 'Least Used':
        sortedList.sort((a, b) => a.usedQuantity.compareTo(b.usedQuantity));
        break;
      default:
        break;
    }

    return sortedList;
  }

  // Get materials summary
  Map<String, int> getMaterialsSummary() {
    return {
      'total': _allMaterials.length,
      'lowStock': _allMaterials.where((m) => m.isLowStock).length,
      'criticalStock': _allMaterials.where((m) => m.isCriticalStock).length,
      'outOfStock': _allMaterials.where((m) => m.isOutOfStock).length,
    };
  }

  // Get low stock materials for alerts
  List<Material> getLowStockMaterials() {
    return _allMaterials
        .where((m) => m.isLowStock || m.isCriticalStock || m.isOutOfStock)
        .toList();
  }

  // Check if sufficient materials available for production
  Map<String, dynamic> checkMaterialAvailability(
    Map<String, int> requiredMaterials,
  ) {
    Map<String, int> shortages = {};
    Map<String, int> available = {};
    bool canProduce = true;

    for (String materialName in requiredMaterials.keys) {
      int requiredQty = requiredMaterials[materialName] ?? 0;

      // Find material by name (case insensitive)
      Material? material = _allMaterials
          .where((m) => m.name.toLowerCase() == materialName.toLowerCase())
          .firstOrNull;

      if (material != null) {
        available[materialName] = material.remainingQuantity;
        if (material.remainingQuantity < requiredQty) {
          shortages[materialName] = requiredQty - material.remainingQuantity;
          canProduce = false;
        }
      } else {
        shortages[materialName] = requiredQty;
        available[materialName] = 0;
        canProduce = false;
      }
    }

    return {
      'canProduce': canProduce,
      'shortages': shortages,
      'available': available,
    };
  }

  // Rebuild search trie from all materials
  void _rebuildSearchTrie() {
    _searchTrie.clear();
    for (Material material in _allMaterials) {
      _searchTrie.insert(material.name, material.id);
    }
  }

  // Get material by ID
  Material? getMaterialById(String id) {
    return _allMaterials.where((m) => m.id == id).firstOrNull;
  }

  // Get material by name
  Material? getMaterialByName(String name) {
    return _allMaterials
        .where((m) => m.name.toLowerCase() == name.toLowerCase())
        .firstOrNull;
  }

  // Reset all data
  Future<void> resetData() async {
    try {
      _allMaterials.clear();
      _searchTrie.clear();
      state = const AsyncValue.data([]);

      // Clear Hive storage
      final box = await _getMaterialsBox();
      await box.clear();
    } catch (e) {
      print('Error resetting data: $e');
    }
  }

  // Save materials data locally using Hive - called by save button
  Future<void> saveMaterialsLocally() async {
    try {
      final box = await _getMaterialsBox();

      // Clear existing data and save all current materials
      await box.clear();

      // Create a map of materials with IDs as keys
      final Map<String, Material> materialMap = {
        for (Material material in _allMaterials) material.id: material,
      };

      await box.putAll(materialMap);
      print('Successfully saved ${_allMaterials.length} materials to Hive');
    } catch (e) {
      print('Failed to save materials locally: $e');
      throw Exception('Failed to save materials: $e');
    }
  }

  // Load materials data from Hive storage
  Future<void> loadMaterialsFromLocal() async {
    try {
      final box = await _getMaterialsBox();
      final List<Material> materials = box.values.toList();

      _allMaterials = materials;
      _rebuildSearchTrie();
      state = AsyncValue.data(_allMaterials);

      print('Loaded ${materials.length} materials from Hive storage');
    } catch (e) {
      print('Error loading materials from Hive: $e');
      // If loading fails, start with empty list
      _allMaterials = [];
      _rebuildSearchTrie();
      state = AsyncValue.data(_allMaterials);
    }
  }

  // Force refresh materials from storage
  Future<void> refreshMaterials() async {
    await _loadMaterials();
  }
}

// Provider instances
final materialsProvider =
    StateNotifierProvider<MaterialsNotifier, AsyncValue<List<Material>>>(
      (ref) => MaterialsNotifier(),
    );

// Search results provider
final materialSearchProvider = Provider.family<List<Material>, String>((
  ref,
  query,
) {
  final materialsState = ref.watch(materialsProvider);
  return materialsState.when(
    data: (materials) {
      if (query.isEmpty) return materials;
      final notifier = ref.read(materialsProvider.notifier);
      return notifier.searchMaterials(query);
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Filtered materials provider
final filteredMaterialsProvider = Provider.family<List<Material>, String>((
  ref,
  filterType,
) {
  final materialsState = ref.watch(materialsProvider);
  return materialsState.when(
    data: (materials) {
      final notifier = ref.read(materialsProvider.notifier);
      return notifier.filterMaterials(filterType);
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Sorted materials provider
final sortedMaterialsProvider =
    Provider.family<List<Material>, Map<String, dynamic>>((ref, params) {
      final List<Material> materials = params['materials'] ?? [];
      final String sortType = params['sortType'] ?? 'Name (A-Z)';
      final notifier = ref.read(materialsProvider.notifier);
      return notifier.sortMaterials(materials, sortType);
    });

// Materials summary provider
final materialsSummaryProvider = Provider<Map<String, int>>((ref) {
  final materialsState = ref.watch(materialsProvider);
  return materialsState.when(
    data: (materials) {
      final notifier = ref.read(materialsProvider.notifier);
      return notifier.getMaterialsSummary();
    },
    loading: () => {
      'total': 0,
      'lowStock': 0,
      'criticalStock': 0,
      'outOfStock': 0,
    },
    error: (_, __) => {
      'total': 0,
      'lowStock': 0,
      'criticalStock': 0,
      'outOfStock': 0,
    },
  );
});

// Low stock materials provider for alerts
final lowStockMaterialsProvider = Provider<List<Material>>((ref) {
  final materialsState = ref.watch(materialsProvider);
  return materialsState.when(
    data: (materials) {
      final notifier = ref.read(materialsProvider.notifier);
      return notifier.getLowStockMaterials();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
