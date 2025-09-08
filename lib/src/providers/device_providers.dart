import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/devices.dart';
import '../models/pcb.dart';
import '../models/bom.dart';
import '../models/materials.dart';

// Device state notifier
class DeviceNotifier extends StateNotifier<AsyncValue<List<Device>>> {
  DeviceNotifier() : super(const AsyncValue.loading()) {
    _loadDevices();
  }

  List<Device> _allDevices = [];
  List<ProductionRecord> _productionHistory = [];

  // Load devices (from local storage or initialize empty)
  Future<void> _loadDevices() async {
    try {
      // In a real app, you would load from local storage here
      _allDevices = [];
      state = AsyncValue.data(_allDevices);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Add new device
  void addDevice(Device device) {
    _allDevices.add(device);
    _saveToStorage(); // Add this method
    state = AsyncValue.data(List.from(_allDevices));
  }

  // Save to local storage (simplified for demo)
  void _saveToStorage() {
    // In a real app, save to SharedPreferences or SQLite
    print('Saving ${_allDevices.length} devices to storage');
    for (var device in _allDevices) {
      print('Device: ${device.name} with ${device.pcbs.length} PCBs');
    }
  }

  // Mock data for testing
  List<Device> _getMockDevices() {
    return [
      Device(
        id: 'device_1',
        name: 'Air Leak Tester',
        subComponents: [
          SubComponent(id: 'sc_1', name: 'Enclosure', quantity: 1),
          SubComponent(id: 'sc_2', name: 'Display', quantity: 1),
          SubComponent(id: 'sc_3', name: 'SMPS', quantity: 1),
        ],
        pcbs: [
          PCB(
            id: 'pcb_1',
            name: 'Cape Board',
            deviceId: 'device_1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          PCB(
            id: 'pcb_2',
            name: 'DIDO Board',
            deviceId: 'device_1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  // Update device
  void updateDevice(Device updatedDevice) {
    int index = _allDevices.indexWhere((d) => d.id == updatedDevice.id);
    if (index != -1) {
      _allDevices[index] = updatedDevice;
      state = AsyncValue.data(List.from(_allDevices));
    }
  }

  // Delete device
  void deleteDevice(String deviceId) {
    _allDevices.removeWhere((d) => d.id == deviceId);
    state = AsyncValue.data(List.from(_allDevices));
  }

  // Update PCB BOM
  void updatePcbBOM(String deviceId, String pcbId, BOM bom) {
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

      _allDevices[deviceIndex] = updatedDevice;
      _saveToStorage(); // Save updated device
      state = AsyncValue.data(List.from(_allDevices));

      // Debug print
      print('BOM updated for PCB $pcbId in device $deviceId');
      print(
        'Device ${updatedDevice.name} ready for production: ${updatedDevice.isReadyForProduction}',
      );
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
  void recordProduction({
    required String deviceId,
    required int quantityProduced,
    required Map<String, int> materialsUsed,
    double? totalCost,
    String? notes,
  }) {
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

    _productionHistory.insert(0, productionRecord); // Add to beginning

    // Keep only last 100 production records
    if (_productionHistory.length > 100) {
      _productionHistory = _productionHistory.take(100).toList();
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

  // Reset all data
  void resetData() {
    _allDevices.clear();
    _productionHistory.clear();
    state = const AsyncValue.data([]);
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
