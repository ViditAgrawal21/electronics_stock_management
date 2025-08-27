import 'package:flutter/foundation.dart';
import '../models/devices.dart';
import '../models/pcb.dart';
import '../models/materials.dart';
import '../services/stock_services.dart';

class DeviceProvider with ChangeNotifier {
  final StockService _stockService = StockService();

  // State variables
  List<Device> _devices = [];
  List<Device> _deviceHistory = [];
  Device? _currentDevice;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Device> get devices => _devices;
  List<Device> get deviceHistory => _deviceHistory;
  Device? get currentDevice => _currentDevice;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Create new device
  Future<bool> createDevice({
    required String deviceName,
    required List<String> subComponents,
    required List<PCB> pcbs,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Create new device
      final device = Device(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: deviceName,
        subComponents: subComponents,
        pcbs: pcbs,
        createdDate: DateTime.now(),
        totalMaterialsUsed: _calculateTotalMaterials(pcbs),
      );

      // Add to devices list
      _devices.add(device);
      _currentDevice = device;

      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to create device: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Calculate material requirements for batch production
  Future<Map<String, dynamic>> calculateBatchRequirements({
    required String deviceId,
    required int quantity,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final device = _devices.firstWhere((d) => d.id == deviceId);
      Map<String, int> totalRequirements = {};
      Map<String, bool> availabilityStatus = {};
      List<String> shortageItems = [];

      // Calculate total material requirements
      for (PCB pcb in device.pcbs) {
        for (var bomItem in pcb.bomItems) {
          String materialRef = bomItem.reference;
          int requiredQty = bomItem.quantity * quantity;

          if (totalRequirements.containsKey(materialRef)) {
            totalRequirements[materialRef] =
                totalRequirements[materialRef]! + requiredQty;
          } else {
            totalRequirements[materialRef] = requiredQty;
          }
        }
      }

      // Check availability against current stock
      final currentStock = await _stockService.getAllMaterials();

      for (String materialRef in totalRequirements.keys) {
        int required = totalRequirements[materialRef]!;

        // Find material in current stock
        final material = currentStock.firstWhere(
          (m) => m.reference == materialRef,
          orElse: () => Material(
            reference: materialRef,
            value: 'Unknown',
            footprint: '',
            initialQuantity: 0,
            remainingQuantity: 0,
            usedQuantity: 0,
          ),
        );

        bool isAvailable = material.remainingQuantity >= required;
        availabilityStatus[materialRef] = isAvailable;

        if (!isAvailable) {
          shortageItems.add(
            '$materialRef (Need: $required, Available: ${material.remainingQuantity})',
          );
        }
      }

      _setLoading(false);

      return {
        'canProduce': shortageItems.isEmpty,
        'requirements': totalRequirements,
        'availability': availabilityStatus,
        'shortages': shortageItems,
        'quantity': quantity,
      };
    } catch (e) {
      _setError('Failed to calculate batch requirements: ${e.toString()}');
      _setLoading(false);
      return {'canProduce': false, 'error': e.toString()};
    }
  }

  // Execute production and update stock
  Future<bool> executeProduction({
    required String deviceId,
    required int quantity,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final device = _devices.firstWhere((d) => d.id == deviceId);

      // Calculate requirements first
      final requirements = await calculateBatchRequirements(
        deviceId: deviceId,
        quantity: quantity,
      );

      if (!requirements['canProduce']) {
        _setError('Cannot produce: Material shortage');
        _setLoading(false);
        return false;
      }

      // Update stock for each material used
      Map<String, int> materialUsage = requirements['requirements'];

      for (String materialRef in materialUsage.keys) {
        int usedQty = materialUsage[materialRef]!;
        await _stockService.updateMaterialUsage(materialRef, usedQty);
      }

      // Create production record
      final productionRecord = Device(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '${device.name} (${quantity}x)',
        subComponents: device.subComponents,
        pcbs: device.pcbs,
        createdDate: DateTime.now(),
        quantityProduced: quantity,
        totalMaterialsUsed: materialUsage,
      );

      // Add to history
      _deviceHistory.insert(0, productionRecord);

      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to execute production: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Get device by ID
  Device? getDeviceById(String deviceId) {
    try {
      return _devices.firstWhere((device) => device.id == deviceId);
    } catch (e) {
      return null;
    }
  }

  // Delete device
  Future<bool> deleteDevice(String deviceId) async {
    try {
      _devices.removeWhere((device) => device.id == deviceId);

      if (_currentDevice?.id == deviceId) {
        _currentDevice = null;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete device: ${e.toString()}');
      return false;
    }
  }

  // Set current device
  void setCurrentDevice(Device device) {
    _currentDevice = device;
    notifyListeners();
  }

  // Clear current device
  void clearCurrentDevice() {
    _currentDevice = null;
    notifyListeners();
  }

  // Get production history with date filtering
  List<Device> getProductionHistory({DateTime? fromDate, DateTime? toDate}) {
    List<Device> filteredHistory = List.from(_deviceHistory);

    if (fromDate != null) {
      filteredHistory = filteredHistory
          .where(
            (device) => device.createdDate.isAfter(
              fromDate.subtract(const Duration(days: 1)),
            ),
          )
          .toList();
    }

    if (toDate != null) {
      filteredHistory = filteredHistory
          .where(
            (device) => device.createdDate.isBefore(
              toDate.add(const Duration(days: 1)),
            ),
          )
          .toList();
    }

    return filteredHistory;
  }

  // Get total devices produced
  int getTotalDevicesProduced() {
    return _deviceHistory.fold(
      0,
      (total, device) => total + (device.quantityProduced ?? 1),
    );
  }

  // Get most produced device
  String? getMostProducedDevice() {
    if (_deviceHistory.isEmpty) return null;

    Map<String, int> deviceCount = {};

    for (Device device in _deviceHistory) {
      String baseName = device.name.split(' (')[0]; // Remove quantity part
      int quantity = device.quantityProduced ?? 1;

      if (deviceCount.containsKey(baseName)) {
        deviceCount[baseName] = deviceCount[baseName]! + quantity;
      } else {
        deviceCount[baseName] = quantity;
      }
    }

    String mostProduced = '';
    int maxCount = 0;

    deviceCount.forEach((name, count) {
      if (count > maxCount) {
        maxCount = count;
        mostProduced = name;
      }
    });

    return mostProduced.isEmpty ? null : mostProduced;
  }

  // Helper methods
  Map<String, int> _calculateTotalMaterials(List<PCB> pcbs) {
    Map<String, int> totalMaterials = {};

    for (PCB pcb in pcbs) {
      for (var bomItem in pcb.bomItems) {
        String materialRef = bomItem.reference;
        int quantity = bomItem.quantity;

        if (totalMaterials.containsKey(materialRef)) {
          totalMaterials[materialRef] = totalMaterials[materialRef]! + quantity;
        } else {
          totalMaterials[materialRef] = quantity;
        }
      }
    }

    return totalMaterials;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (!loading) notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // Clear all data
  void clearAll() {
    _devices.clear();
    _deviceHistory.clear();
    _currentDevice = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // Search devices
  List<Device> searchDevices(String query) {
    if (query.isEmpty) return _devices;

    return _devices
        .where(
          (device) =>
              device.name.toLowerCase().contains(query.toLowerCase()) ||
              device.subComponents.any(
                (component) =>
                    component.toLowerCase().contains(query.toLowerCase()),
              ),
        )
        .toList();
  }
}
