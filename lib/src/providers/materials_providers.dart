import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/materials.dart';
import '../services/excel_service.dart';
import '../utils/search_trie.dart';
import '../constants/app_config.dart';

// Materials state notifier
class MaterialsNotifier extends StateNotifier<AsyncValue<List<Material>>> {
  MaterialsNotifier() : super(const AsyncValue.loading()) {
    _loadMaterials();
  }

  final SearchTrie _searchTrie = SearchTrie();
  List<Material> _allMaterials = [];

  // Load materials (from local storage or initialize empty)
  Future<void> _loadMaterials() async {
    try {
      // In a real app, you would load from local storage here
      // For now, we'll start with an empty list
      _allMaterials = [];
      _rebuildSearchTrie();
      state = AsyncValue.data(_allMaterials);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
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
  void addMaterial(Material material) {
    _allMaterials.add(material);
    _searchTrie.insert(material.name, material.id);
    state = AsyncValue.data(List.from(_allMaterials));
  }

  // Update material
  void updateMaterial(Material updatedMaterial) {
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
    }
  }

  // Update remaining quantity only
  void updateRemainingQuantity(String materialId, int newQuantity) {
    int index = _allMaterials.indexWhere((m) => m.id == materialId);
    if (index != -1) {
      _allMaterials[index] = _allMaterials[index].copyWith(
        remainingQuantity: newQuantity,
        usedQuantity: _allMaterials[index].initialQuantity - newQuantity,
        lastUsedAt: DateTime.now(),
      );
      state = AsyncValue.data(List.from(_allMaterials));
    }
  }

  // Use materials (decrease remaining quantity)
  void useMaterials(Map<String, int> materialsToUse) {
    for (String materialId in materialsToUse.keys) {
      int quantityToUse = materialsToUse[materialId] ?? 0;
      int index = _allMaterials.indexWhere((m) => m.id == materialId);

      if (index != -1) {
        Material material = _allMaterials[index];
        int newRemainingQuantity = (material.remainingQuantity - quantityToUse)
            .clamp(0, material.initialQuantity);

        _allMaterials[index] = material.copyWith(
          remainingQuantity: newRemainingQuantity,
          usedQuantity: material.initialQuantity - newRemainingQuantity,
          lastUsedAt: DateTime.now(),
        );
      }
    }
    state = AsyncValue.data(List.from(_allMaterials));
  }

  // Delete material
  void deleteMaterial(String materialId) {
    Material? materialToDelete = _allMaterials
        .where((m) => m.id == materialId)
        .firstOrNull;
    if (materialToDelete != null) {
      _allMaterials.removeWhere((m) => m.id == materialId);
      _searchTrie.remove(materialToDelete.name, materialId);
      state = AsyncValue.data(List.from(_allMaterials));
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
  void resetData() {
    _allMaterials.clear();
    _searchTrie.clear();
    state = const AsyncValue.data([]);
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
