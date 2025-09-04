import '../models/materials.dart';
import '../models/devices.dart';

class StockService {
  // Calculate optimal reorder quantities
  static Map<String, int> calculateReorderQuantities(
    List<Material> materials, {
    int safetyStockDays = 30,
    double averageUsagePerDay = 1.0,
  }) {
    Map<String, int> reorderQuantities = {};

    for (Material material in materials) {
      if (material.isLowStock ||
          material.isCriticalStock ||
          material.isOutOfStock) {
        // Calculate days since last used
        int daysSinceLastUsed = DateTime.now()
            .difference(material.lastUsedAt)
            .inDays;

        // Estimate usage rate
        double usageRate = daysSinceLastUsed > 0
            ? material.usedQuantity / daysSinceLastUsed
            : averageUsagePerDay;

        // Calculate reorder quantity (safety stock + projected usage)
        int reorderQty = (safetyStockDays * usageRate).ceil();

        // Minimum reorder quantity
        int minReorder =
            material.initialQuantity * 0.2.ceil(); // 20% of initial

        reorderQuantities[material.name] = reorderQty > minReorder
            ? reorderQty
            : minReorder;
      }
    }

    return reorderQuantities;
  }

  // Analyze stock patterns
  static Map<String, dynamic> analyzeStockPatterns(List<Material> materials) {
    List<Material> fastMoving = [];
    List<Material> slowMoving = [];
    List<Material> deadStock = [];

    DateTime thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    for (Material material in materials) {
      double usageRate = material.initialQuantity > 0
          ? material.usedQuantity / material.initialQuantity
          : 0.0;

      if (material.usedQuantity == 0) {
        deadStock.add(material);
      } else if (usageRate > 0.5 ||
          material.lastUsedAt.isAfter(thirtyDaysAgo)) {
        fastMoving.add(material);
      } else {
        slowMoving.add(material);
      }
    }

    return {
      'fastMoving': fastMoving,
      'slowMoving': slowMoving,
      'deadStock': deadStock,
      'totalValue': _calculateTotalValue(materials),
      'turnoverRate': _calculateTurnoverRate(materials),
    };
  }

  // Calculate ABC analysis
  static Map<String, List<Material>> performABCAnalysis(
    List<Material> materials,
  ) {
    // Sort by value (usage * unit cost)
    List<Material> sortedMaterials = List.from(materials);
    sortedMaterials.sort((a, b) {
      double valueA = (a.unitCost ?? 0) * a.usedQuantity;
      double valueB = (b.unitCost ?? 0) * b.usedQuantity;
      return valueB.compareTo(valueA);
    });

    int totalItems = sortedMaterials.length;
    int aCount = (totalItems * 0.2).ceil(); // Top 20%
    int bCount = (totalItems * 0.3).ceil(); // Next 30%

    return {
      'A': sortedMaterials.take(aCount).toList(),
      'B': sortedMaterials.skip(aCount).take(bCount).toList(),
      'C': sortedMaterials.skip(aCount + bCount).toList(),
    };
  }

  // Generate stock forecast
  static Map<String, dynamic> generateStockForecast(
    List<Material> materials,
    List<ProductionRecord> productionHistory,
    int forecastDays,
  ) {
    Map<String, double> dailyUsageRates = {};
    Map<String, DateTime> stockoutDates = {};

    for (Material material in materials) {
      // Calculate average daily usage
      double totalUsed = material.usedQuantity.toDouble();
      int daysActive = DateTime.now()
          .difference(material.createdAt)
          .inDays
          .clamp(1, 365);
      double dailyUsage = totalUsed / daysActive;

      dailyUsageRates[material.name] = dailyUsage;

      // Predict stockout date
      if (dailyUsage > 0 && material.remainingQuantity > 0) {
        int daysUntilStockout = (material.remainingQuantity / dailyUsage)
            .floor();
        stockoutDates[material.name] = DateTime.now().add(
          Duration(days: daysUntilStockout),
        );
      }
    }

    return {
      'dailyUsageRates': dailyUsageRates,
      'stockoutDates': stockoutDates,
      'criticalMaterials': _getCriticalMaterials(
        materials,
        stockoutDates,
        forecastDays,
      ),
    };
  }

  // Calculate inventory value
  static double _calculateTotalValue(List<Material> materials) {
    return materials.fold(0.0, (total, material) {
      return total + ((material.unitCost ?? 0) * material.remainingQuantity);
    });
  }

  // Calculate inventory turnover rate
  static double _calculateTurnoverRate(List<Material> materials) {
    double totalCostOfGoodsSold = materials.fold(0.0, (total, material) {
      return total + ((material.unitCost ?? 0) * material.usedQuantity);
    });

    double averageInventoryValue =
        _calculateTotalValue(materials) * 1.5; // Approximate

    return averageInventoryValue > 0
        ? totalCostOfGoodsSold / averageInventoryValue
        : 0.0;
  }

  // Get materials that will be critical within forecast period
  static List<String> _getCriticalMaterials(
    List<Material> materials,
    Map<String, DateTime> stockoutDates,
    int forecastDays,
  ) {
    DateTime cutoffDate = DateTime.now().add(Duration(days: forecastDays));
    List<String> criticalMaterials = [];

    stockoutDates.forEach((materialName, stockoutDate) {
      if (stockoutDate.isBefore(cutoffDate)) {
        criticalMaterials.add(materialName);
      }
    });

    return criticalMaterials;
  }

  // Generate purchase recommendations
  static List<Map<String, dynamic>> generatePurchaseRecommendations(
    List<Material> materials,
    Map<String, int> reorderQuantities,
  ) {
    List<Map<String, dynamic>> recommendations = [];

    for (Material material in materials) {
      if (reorderQuantities.containsKey(material.name)) {
        int recommendedQty = reorderQuantities[material.name]!;
        double estimatedCost = (material.unitCost ?? 0) * recommendedQty;

        recommendations.add({
          'material': material,
          'recommendedQuantity': recommendedQty,
          'estimatedCost': estimatedCost,
          'priority': _getPurchasePriority(material),
          'supplier': material.supplier,
          'lastOrderDate': material.createdAt, // Approximation
        });
      }
    }

    // Sort by priority
    recommendations.sort((a, b) => b['priority'].compareTo(a['priority']));

    return recommendations;
  }

  // Get purchase priority score
  static int _getPurchasePriority(Material material) {
    if (material.isOutOfStock) return 3;
    if (material.isCriticalStock) return 2;
    if (material.isLowStock) return 1;
    return 0;
  }

  // Validate stock levels
  static Map<String, dynamic> validateStockLevels(List<Material> materials) {
    int totalMaterials = materials.length;
    int healthyStock = 0;
    int lowStock = 0;
    int criticalStock = 0;
    int outOfStock = 0;

    for (Material material in materials) {
      if (material.isOutOfStock) {
        outOfStock++;
      } else if (material.isCriticalStock) {
        criticalStock++;
      } else if (material.isLowStock) {
        lowStock++;
      } else {
        healthyStock++;
      }
    }

    double healthPercentage = totalMaterials > 0
        ? (healthyStock / totalMaterials) * 100
        : 0;

    return {
      'totalMaterials': totalMaterials,
      'healthyStock': healthyStock,
      'lowStock': lowStock,
      'criticalStock': criticalStock,
      'outOfStock': outOfStock,
      'healthPercentage': healthPercentage,
      'status': _getOverallStockStatus(healthPercentage),
    };
  }

  // Get overall stock status
  static String _getOverallStockStatus(double healthPercentage) {
    if (healthPercentage >= 80) return 'Excellent';
    if (healthPercentage >= 60) return 'Good';
    if (healthPercentage >= 40) return 'Fair';
    if (healthPercentage >= 20) return 'Poor';
    return 'Critical';
  }
}
