import '../models/bom.dart';
import '../models/materials.dart';

class BOMService {
  // Validate BOM against available materials
  static Map<String, dynamic> validateBOM(
    List<BOMItem> bomItems,
    List<Material> materials,
  ) {
    List<String> missingMaterials = [];
    List<String> availableMaterials = [];
    Map<String, int> insufficientStock = {};

    for (BOMItem item in bomItems) {
      // Find material by name (case insensitive)
      Material? material = materials
          .where((m) => m.name.toLowerCase() == item.value.toLowerCase())
          .firstOrNull;

      if (material == null) {
        missingMaterials.add(item.value);
      } else {
        availableMaterials.add(item.value);

        // Check if sufficient stock for single PCB production
        if (material.remainingQuantity < item.quantity) {
          insufficientStock[item.value] =
              item.quantity - material.remainingQuantity;
        }
      }
    }

    return {
      'isValid': missingMaterials.isEmpty && insufficientStock.isEmpty,
      'missingMaterials': missingMaterials,
      'availableMaterials': availableMaterials,
      'insufficientStock': insufficientStock,
      'totalComponents': bomItems.length,
      'validComponents': availableMaterials.length,
    };
  }

  // Calculate material requirements for batch production
  static Map<String, int> calculateBatchRequirements(BOM bom, int quantity) {
    Map<String, int> requirements = {};

    for (BOMItem item in bom.items) {
      String materialName = item.value;
      int totalRequired = item.quantity * quantity;

      requirements[materialName] =
          (requirements[materialName] ?? 0) + totalRequired;
    }

    return requirements;
  }

  // Get BOM summary statistics
  static Map<String, dynamic> getBOMSummary(BOM bom) {
    Map<String, int> layerCount = {'top': 0, 'bottom': 0};
    Map<String, int> componentTypes = {};
    int totalQuantity = 0;

    for (BOMItem item in bom.items) {
      // Count by layer
      layerCount[item.layer] = (layerCount[item.layer] ?? 0) + 1;

      // Count by component type (first letter of reference)
      String componentType = item.reference.isNotEmpty
          ? item.reference[0].toUpperCase()
          : 'Unknown';
      componentTypes[componentType] = (componentTypes[componentType] ?? 0) + 1;

      // Total quantity
      totalQuantity += item.quantity;
    }

    return {
      'totalComponents': bom.items.length,
      'totalQuantity': totalQuantity,
      'layerCount': layerCount,
      'componentTypes': componentTypes,
      'uniqueValues': bom.items.map((item) => item.value).toSet().length,
    };
  }

  // Generate BOM comparison report
  static Map<String, dynamic> compareBOMs(BOM bom1, BOM bom2) {
    Set<String> allReferences = {};
    Map<String, BOMItem> bom1Items = {};
    Map<String, BOMItem> bom2Items = {};

    // Build reference maps
    for (BOMItem item in bom1.items) {
      allReferences.add(item.reference);
      bom1Items[item.reference] = item;
    }

    for (BOMItem item in bom2.items) {
      allReferences.add(item.reference);
      bom2Items[item.reference] = item;
    }

    List<String> addedComponents = [];
    List<String> removedComponents = [];
    List<String> modifiedComponents = [];
    List<String> unchangedComponents = [];

    for (String reference in allReferences) {
      BOMItem? item1 = bom1Items[reference];
      BOMItem? item2 = bom2Items[reference];

      if (item1 == null) {
        addedComponents.add(reference);
      } else if (item2 == null) {
        removedComponents.add(reference);
      } else {
        // Compare items
        bool isModified =
            item1.value != item2.value ||
            item1.footprint != item2.footprint ||
            item1.quantity != item2.quantity ||
            item1.layer != item2.layer;

        if (isModified) {
          modifiedComponents.add(reference);
        } else {
          unchangedComponents.add(reference);
        }
      }
    }

    return {
      'added': addedComponents,
      'removed': removedComponents,
      'modified': modifiedComponents,
      'unchanged': unchangedComponents,
      'totalChanges':
          addedComponents.length +
          removedComponents.length +
          modifiedComponents.length,
    };
  }

  // Extract unique materials from BOM
  static Set<String> extractUniqueMaterials(BOM bom) {
    return bom.items.map((item) => item.value).toSet();
  }

  // Find duplicate references in BOM
  static List<String> findDuplicateReferences(List<BOMItem> bomItems) {
    Map<String, int> referenceCount = {};
    List<String> duplicates = [];

    for (BOMItem item in bomItems) {
      referenceCount[item.reference] =
          (referenceCount[item.reference] ?? 0) + 1;
    }

    referenceCount.forEach((reference, count) {
      if (count > 1) {
        duplicates.add(reference);
      }
    });

    return duplicates;
  }

  // Validate BOM format
  static Map<String, dynamic> validateBOMFormat(List<BOMItem> bomItems) {
    List<String> errors = [];
    List<String> warnings = [];

    for (int i = 0; i < bomItems.length; i++) {
      BOMItem item = bomItems[i];

      // Check required fields
      if (item.reference.isEmpty) {
        errors.add('Row ${i + 1}: Reference is required');
      }

      if (item.value.isEmpty) {
        errors.add('Row ${i + 1}: Value is required');
      }

      if (item.quantity <= 0) {
        errors.add('Row ${i + 1}: Quantity must be greater than 0');
      }

      // Check layer format
      if (!['top', 'bottom'].contains(item.layer.toLowerCase())) {
        warnings.add('Row ${i + 1}: Layer should be "top" or "bottom"');
      }

      // Check reference format
      if (item.reference.isNotEmpty &&
          !RegExp(r'^[A-Z]+\d+$').hasMatch(item.reference)) {
        warnings.add(
          'Row ${i + 1}: Reference format should be like C1, R1, U1',
        );
      }
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
      'duplicateReferences': findDuplicateReferences(bomItems),
    };
  }
}
