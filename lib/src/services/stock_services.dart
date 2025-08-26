import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/materials.dart';

class StockService {
  static const String _stockKey = 'materials_stock';
  static const String _usageHistoryKey = 'usage_history';
  static const String _lowStockThresholdKey = 'low_stock_threshold';
  
  // Default low stock threshold
  static const int _defaultLowStockThreshold = 10;

  /// Get all materials from storage
  Future<List<Material>> getAllMaterials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? materialsJson = prefs.getString(_stockKey);
      
      if (materialsJson == null || materialsJson.isEmpty) {
        return [];
      }
      
      final List<dynamic> materialsList = jsonDecode(materialsJson);
      return materialsList.map((json) => Material.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load materials: $e');
    }
  }

  /// Save materials to storage
  Future<bool> saveMaterials(List<Material> materials) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String materialsJson = jsonEncode(
        materials.map((material) => material.toJson()).toList(),
      );
      
      return await prefs.setString(_stockKey, materialsJson);
    } catch (e) {
      throw Exception('Failed to save materials: $e');
    }
  }

  /// Update stock quantity for a specific material
  Future<bool> updateMaterialStock({
    required String materialId,
    required int newQuantity,
    String? reason,
  }) async {
    try {
      final materials = await getAllMaterials();
      final materialIndex = materials.indexWhere((m) => m.id == materialId);
      
      if (materialIndex == -1) {
        throw Exception('Material not found');
      }
      
      final oldQuantity = materials[materialIndex].remainingQuantity;
      materials[materialIndex] = materials[materialIndex].copyWith(
        remainingQuantity: newQuantity,
        lastUpdated: DateTime.now(),
      );
      
      // Save updated materials
      await saveMaterials(materials);
      
      // Log usage history
      await _logUsageHistory(
        materialId: materialId,
        materialName: materials[materialIndex].name,
        oldQuantity: oldQuantity,
        newQuantity: newQuantity,
        reason: reason ?? 'Manual update',
      );
      
      return true;
    } catch (e) {
      throw Exception('Failed to update stock: $e');
    }
  }

  /// Consume materials (reduce stock) - used when creating PCBs
  Future<bool> consumeMaterials(Map<String, int> materialsToConsume) async {
    try {
      final materials = await getAllMaterials();
      
      // First check if we have enough stock for all materials
      for (final entry in materialsToConsume.entries) {
        final material = materials.firstWhere(
          (m) => m.id == entry.key,
          orElse: () => throw Exception('Material ${entry.key} not found'),
        );
        
        if (material.remainingQuantity < entry.value) {
          throw Exception(
            'Insufficient stock for ${material.name}. '
            'Required: ${entry.value}, Available: ${material.remainingQuantity}',
          );
        }
      }
      
      // If all checks pass, consume the materials
      for (final entry in materialsToConsume.entries) {
        final materialIndex = materials.indexWhere((m) => m.id == entry.key);
        final oldQuantity = materials[materialIndex].remainingQuantity;
        final newQuantity = oldQuantity - entry.value;
        
        materials[materialIndex] = materials[materialIndex].copyWith(
          remainingQuantity: newQuantity,
          usedQuantity: materials[materialIndex].usedQuantity + entry.value,
          lastUpdated: DateTime.now(),
        );
        
        // Log usage
        await _logUsageHistory(
          materialId: entry.key,
          materialName: materials[materialIndex].name,
          oldQuantity: oldQuantity,
          newQuantity: newQuantity,
          reason: 'PCB Production',
          quantityUsed: entry.value,
        );
      }
      
      await saveMaterials(materials);
      return true;
    } catch (e) {
      throw Exception('Failed to consume materials: $e');
    }
  }

  /// Check if materials are available for production
  Future<Map<String, dynamic>> checkMaterialAvailability(
    Map<String, int> requiredMaterials,
  ) async {
    try {
      final materials = await getAllMaterials();
      final Map<String, dynamic> result = {
        'canProduce': true,
        'unavailableMaterials': <String>[],
        'shortageDetails': <Map<String, dynamic>>[],
      };
      
      for (final entry in requiredMaterials.entries) {
        final material = materials.firstWhere(
          (m) => m.id == entry.key,
          orElse: () => Material.empty(),
        );
        
        if (material.id.isEmpty) {
          result['canProduce'] = false;
          result['unavailableMaterials'].add('Material ID: ${entry.key}');
          continue;
        }
        
        if (material.remainingQuantity < entry.value) {
          result['canProduce'] = false;
          result['shortageDetails'].add({
            'materialName': material.name,
            'required': entry.value,
            'available': material.remainingQuantity,
            'shortage': entry.value - material.remainingQuantity,
          });
        }
      }
      
      return result;
    } catch (e) {
      throw Exception('Failed to check material availability: $e');
    }
  }

  /// Get materials with low stock
  Future<List<Material>> getLowStockMaterials() async {
    try {
      final materials = await getAllMaterials();
      final threshold = await getLowStockThreshold();
      
      return materials.where((material) => 
        material.remainingQuantity <= threshold
      ).toList();
    } catch (e) {
      throw Exception('Failed to get low stock materials: $e');
    }
  }

  /// Get low stock threshold
  Future<int> getLowStockThreshold() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_lowStockThresholdKey) ?? _defaultLowStockThreshold;
    } catch (e) {
      return _defaultLowStockThreshold;
    }
  }

  /// Set low stock threshold
  Future<bool> setLowStockThreshold(int threshold) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setInt(_lowStockThresholdKey, threshold);
    } catch (e) {
      throw Exception('Failed to set low stock threshold: $e');
    }
  }

  /// Get usage history
  Future<List<Map<String, dynamic>>> getUsageHistory({
    String? materialId,
    int? limit,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString(_usageHistoryKey);
      
      if (historyJson == null || historyJson.isEmpty) {
        return [];
      }
      
      List<Map<String, dynamic>> history = 
        List<Map<String, dynamic>>.from(jsonDecode(historyJson));
      
      // Filter by material ID if specified
      if (materialId != null) {
        history = history.where((h) => h['materialId'] == materialId).toList();
      }
      
      // Sort by timestamp (newest first)
      history.sort((a, b) => 
        DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp']))
      );
      
      // Limit results if specified
      if (limit != null && limit > 0) {
        history = history.take(limit).toList();
      }
      
      return history;
    } catch (e) {
      throw Exception('Failed to get usage history: $e');
    }
  }

  /// Clear all stock data (for reset/testing purposes)
  Future<bool> clearAllStockData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_stockKey);
      await prefs.remove(_usageHistoryKey);
      return true;
    } catch (e) {
      throw Exception('Failed to clear stock data: $e');
    }
  }

  /// Get stock summary statistics
  Future<Map<String, dynamic>> getStockSummary() async {
    try {
      final materials = await getAllMaterials();
      final lowStockMaterials = await getLowStockMaterials();
      
      final totalMaterials = materials.length;
      final totalStock = materials.fold<int>(
        0, (sum, material) => sum + material.remainingQuantity
      );
      final totalUsed = materials.fold<int>(
        0, (sum, material) => sum + material.usedQuantity
      );
      final lowStockCount = lowStockMaterials.length;
      
      return {
        'totalMaterials': totalMaterials,
        'totalRemainingStock': totalStock,
        'totalUsedStock': totalUsed,
        'lowStockMaterials': lowStockCount,
        'lowStockPercentage': totalMaterials > 0 
          ? (lowStockCount / totalMaterials * 100).toStringAsFixed(1)
          : '0.0',
      };
    } catch (e) {
      throw Exception('Failed to get stock summary: $e');
    }
  }

  /// Private method to log usage history
  Future<void> _logUsageHistory({
    required String materialId,
    required String materialName,
    required int oldQuantity,
    required int newQuantity,
    required String reason,
    int? quantityUsed,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? existingHistoryJson = prefs.getString(_usageHistoryKey);
      
      List<Map<String, dynamic>> history = [];
      if (existingHistoryJson != null && existingHistoryJson.isNotEmpty) {
        history = List<Map<String, dynamic>>.from(jsonDecode(existingHistoryJson));
      }
      
      final historyEntry = {
        'materialId': materialId,
        'materialName': materialName,
        'oldQuantity': oldQuantity,
        'newQuantity': newQuantity,
        'quantityChanged': newQuantity - oldQuantity,
        'quantityUsed': quantityUsed,
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      history.insert(0, historyEntry); // Add to beginning for newest first
      
      // Keep only last 1000 entries to prevent unlimited growth
      if (history.length > 1000) {
        history = history.take(1000).toList();
      }
      
      await prefs.setString(_usageHistoryKey, jsonEncode(history));
    } catch (e) {
      // Log error but don't throw to avoid breaking main functionality
      print('Failed to log usage history: $e');
    }
  }
}