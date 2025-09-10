import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/devices.dart';
import '../models/pcb.dart';
import '../models/bom.dart';
import '../models/materials.dart';

// Hive box keys
const String _devicesBoxKey = 'devices_box';
const String _productionHistoryBoxKey = 'production_history_box';

// Device state notifier with Hive persistence
class DeviceNotifier extends StateNotifier<AsyncValue<List<Device>>> {
  DeviceNotifier() : super(const AsyncValue.loading()) {
    _loadDevices();
  }

  List<Device> _allDevices = [];
  List<ProductionRecord> _productionHistory = [];
  
  // Hive boxes
  Box<Device>? _devicesBox;
  Box<ProductionRecord>? _productionHistoryBox;

  // Load devices from Hive storage
  Future<void> _loadDevices() async {
    try {
      // Open Hive boxes
      _devicesBox = await Hive.openBox<Device>(_devicesBoxKey);
      _productionHistoryBox = await Hive.openBox<ProductionRecord>(_productionHistoryBoxKey);

      // Load devices from Hive
      _allDevices = _devicesBox?.values.toList() ?? [];
      _productionHistory = _productionHistoryBox?.values.toList() ?? [];

      // Sort production history by date (most recent first)
      _productionHistory.sort((a, b) => b.productionDate.compareTo(a.productionDate));

      print('Loaded ${_allDevices.length} devices from Hive storage');
      print('Loaded ${_productionHistory.length} production records from Hive storage');

      state = AsyncValue.data(_allDevices);
    } catch (error, stackTrace) {
      print('Error loading devices from Hive: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Add new device
  Future<void> addDevice(Device device) async {
    try {
      // Add to local list
      _allDevices.add(device);
      
      // Save to Hive
      await _devicesBox?.put(device.id, device);
      
      // Update state
      state = AsyncValue.data(List.from(_allDevices));
      
      print('Device ${device.name} added and saved to Hive');
    } catch (error) {
      print('Error adding device to Hive: $error');
      // Remove from local list if Hive save failed
      _allDevices.removeWhere((d) => d.id == device.id);
      rethrow;
    }
  }

  // Update device
  Future<void> updateDevice(Device updatedDevice) async {
    try {
      int index = _allDevices.indexWhere((d) => d.id == updatedDevice.id);
      if (index != -1) {
        // Update local list
        _allDevices[index] = updatedDevice;
        
        // Save to Hive
        await _devicesBox?.put(updatedDevice.id, updatedDevice);
        
        // Update state
        state = AsyncValue.data(List.from(_allDevices));
        
        print('Device ${updatedDevice.name} updated in Hive');
      }
    } catch (error) {
      print('Error updating device in Hive: $error');
      rethrow;
    }
  }

  // Delete device
  Future<void> deleteDevice(String deviceId) async {
    try {
      // Remove from local list
      Device? deviceToRemove = _allDevices.where((d) => d.id == deviceId).firstOrNull;
      _allDevices.removeWhere((d) => d.id == deviceId);
      
      // Remove from Hive
      await _devicesBox?.delete(deviceId);
      
      // Also remove related production records
      List<String> recordsToRemove = _productionHistory
          .where((record) => record.deviceId == deviceId)
          .map((record) => record.id)
          .toList();
      
      for (String recordId in recordsToRemove) {
        await _productionHistoryBox?.delete(recordId);
      }
      
      // Remove from local production history
      _productionHistory.removeWhere((record) => record.deviceId == deviceId);
      
      // Update state
      state = AsyncValue.data(List.from(_allDevices));
      
      print('Device ${deviceToRemove?.name ?? deviceId} and related records deleted from Hive');
    } catch (error) {
      print('Error deleting device from Hive: $error');
      rethrow;
    }
  }

  // Update PCB BOM
  Future<void> updatePcbBOM(String deviceId, String pcbId, BOM bom) async {
    try {
      int deviceIndex = _allDevices.indexWhere((d) => d.id == deviceId);
      if (deviceIndex != -1) {
        Device device = _allDevices[deviceIndex];
        List<PCB> updatedPcbs = device.pcbs.map((pcb) {
          if (pcb.id == pcbId) {
            return pcb.copyWith(bom: bom, updatedAt: DateTime.now());
          }
          return pcb;
        }).toList();

        Device updatedDevice = device.copyWith(
          pcbs: updatedPcbs,
          updatedAt: DateTime.now(),
        );

        // Update local list
        _allDevices[deviceIndex] = updatedDevice;
        
        // Save to Hive
        await _devicesBox?.put(deviceId, updatedDevice);
        
        // Update state
        state = AsyncValue.data(List.from(_allDevices));

        print('BOM updated for PCB $pcbId in device $deviceId and saved to Hive');
        print('Device ${updatedDevice.name} ready for production: ${updatedDevice.isReadyForProduction}');
      }
    } catch (error) {
      print('Error updating PCB BOM in Hive: $error');
      rethrow;
    }
  }

  // Calculate material requirements for batch production
  Map<String, int> calculateBatchMaterialRequirements(
    String deviceId,
    int quantity,
  ) {
    Device? device = _allDevices.where((d) => d.id == deviceId).firstOrNull;
    if (device == null) return {};

    Map<String, int> totalRequirements = {};

    // Calculate requirements from all PCB BOMs
    for (PCB pcb in device.pcbs) {
      if (pcb.bom != null) {
        for (BOMItem item in pcb.bom!.items) {
          String materialName = item.value; // Raw material name
          int requiredPerPcb = item.quantity;
          int totalRequired = requiredPerPcb * quantity;

          totalRequirements[materialName] =
              (totalRequirements[materialName] ?? 0) + totalRequired;
        }
      }
    }

    return totalRequirements;
  }

  // Check if device can be produced with available materials
  Map<String, dynamic> checkProductionFeasibility(
    String deviceId,
    int quantity,
    List<Material> availableMaterials,
  ) {
    Map<String, int> requirements = calculateBatchMaterialRequirements(
      deviceId,
      quantity,
    );
    Map<String, int> shortages = {};
    Map<String, int> available = {};
    bool canProduce = true;

    for (String materialName in requirements.keys) {
      int requiredQty = requirements[materialName] ?? 0;

      // Find material by name (case insensitive)
      Material? material = availableMaterials
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
      'requirements': requirements,
      'shortages': shortages,
      'available': available,
    };
  }

  // Record production
  Future<void> recordProduction({
    required String deviceId,
    required int quantityProduced,
    required Map<String, int> materialsUsed,
    double? totalCost,
    String? notes,
  }) async {
    try {
      Device? device = _allDevices.where((d) => d.id == deviceId).firstOrNull;
      if (device == null) return;

      final productionRecord = ProductionRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        deviceId: deviceId,
        deviceName: device.name,
        quantityProduced: quantityProduced,
        productionDate: DateTime.now(),
        materialsUsed: materialsUsed,
        totalCost: totalCost ?? 0.0,
        notes: notes,
      );

      // Add to local list (at beginning for most recent first)
      _productionHistory.insert(0, productionRecord);

      // Save to Hive
      await _productionHistoryBox?.put(productionRecord.id, productionRecord);

      // Keep only last 100 production records in memory and Hive
      if (_productionHistory.length > 100) {
        List<ProductionRecord> recordsToRemove = _productionHistory.skip(100).toList();
        _productionHistory = _productionHistory.take(100).toList();
        
        // Remove old records from Hive
        for (ProductionRecord record in recordsToRemove) {
          await _productionHistoryBox?.delete(record.id);
        }
      }
      
      print('Production record for ${device.name} saved to Hive');
    } catch (error) {
      print('Error recording production in Hive: $error');
      rethrow;
    }
  }

  // Get device by ID
  Device? getDeviceById(String id) {
    return _allDevices.where((d) => d.id == id).firstOrNull;
  }

  // Get devices ready for production
  List<Device> getReadyForProductionDevices() {
    return _allDevices.where((d) => d.isReadyForProduction).toList();
  }

  // Get devices needing BOM upload
  List<Device> getDevicesNeedingBOM() {
    return _allDevices.where((d) => !d.isReadyForProduction).toList();
  }

  // Get production history
  List<ProductionRecord> getProductionHistory() {
    return List.from(_productionHistory);
  }

  // Get production history for specific device
  List<ProductionRecord> getDeviceProductionHistory(String deviceId) {
    return _productionHistory.where((r) => r.deviceId == deviceId).toList();
  }

  // Get production statistics
  Map<String, dynamic> getProductionStatistics() {
    int totalProduced = _productionHistory.fold(
      0,
      (sum, record) => sum + record.quantityProduced,
    );
    double totalCost = _productionHistory.fold(
      0.0,
      (sum, record) => sum + record.totalCost,
    );

    Map<String, int> deviceProduction = {};
    for (ProductionRecord record in _productionHistory) {
      deviceProduction[record.deviceName] =
          (deviceProduction[record.deviceName] ?? 0) + record.quantityProduced;
    }

    return {
      'totalProduced': totalProduced,
      'totalCost': totalCost,
      'deviceProduction': deviceProduction,
      'totalRecords': _productionHistory.length,
    };
  }

  // Clear all data (for testing/reset)
  Future<void> resetData() async {
    try {
      // Clear local lists
      _allDevices.clear();
      _productionHistory.clear();
      
      // Clear Hive boxes
      await _devicesBox?.clear();
      await _productionHistoryBox?.clear();
      
      // Update state
      state = const AsyncValue.data([]);
      
      print('All device data cleared from Hive');
    } catch (error) {
      print('Error clearing device data from Hive: $error');
      rethrow;
    }
  }

  // Close Hive boxes when notifier is disposed
  @override
  void dispose() {
    _devicesBox?.close();
    _productionHistoryBox?.close();
    super.dispose();
  }

  // Refresh data from Hive (useful for debugging or data sync)
  Future<void> refreshFromStorage() async {
    await _loadDevices();
  }
}

// Provider instances
final deviceProvider =
    StateNotifierProvider<DeviceNotifier, AsyncValue<List<Device>>>(
      (ref) => DeviceNotifier(),
    );

// Ready for production devices provider
final readyForProductionDevicesProvider = Provider<List<Device>>((ref) {
  final devicesState = ref.watch(deviceProvider);
  return devicesState.when(
    data: (devices) {
      final notifier = ref.read(deviceProvider.notifier);
      return notifier.getReadyForProductionDevices();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Devices needing BOM provider
final devicesNeedingBOMProvider = Provider<List<Device>>((ref) {
  final devicesState = ref.watch(deviceProvider);
  return devicesState.when(
    data: (devices) {
      final notifier = ref.read(deviceProvider.notifier);
      return notifier.getDevicesNeedingBOM();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Production history provider
final productionHistoryProvider = Provider<List<ProductionRecord>>((ref) {
  final notifier = ref.read(deviceProvider.notifier);
  return notifier.getProductionHistory();
});

// Production statistics provider
final productionStatisticsProvider = Provider<Map<String, dynamic>>((ref) {
  final notifier = ref.read(deviceProvider.notifier);
  return notifier.getProductionStatistics();
});

// Device production history provider
final deviceProductionHistoryProvider =
    Provider.family<List<ProductionRecord>, String>((ref, deviceId) {
      final notifier = ref.read(deviceProvider.notifier);
      return notifier.getDeviceProductionHistory(deviceId);
    });