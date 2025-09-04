import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pcb.dart';
import '../models/bom.dart';

// PCB state notifier
class PCBNotifier extends StateNotifier<AsyncValue<List<PCB>>> {
  PCBNotifier() : super(const AsyncValue.loading()) {
    _loadPCBs();
  }

  List<PCB> _allPCBs = [];

  // Load PCBs (from local storage or initialize empty)
  Future<void> _loadPCBs() async {
    try {
      // In a real app, you would load from local storage here
      _allPCBs = [];
      state = AsyncValue.data(_allPCBs);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Add new PCB
  void addPCB(PCB pcb) {
    _allPCBs.add(pcb);
    state = AsyncValue.data(List.from(_allPCBs));
  }

  // Update PCB
  void updatePCB(PCB updatedPCB) {
    int index = _allPCBs.indexWhere((p) => p.id == updatedPCB.id);
    if (index != -1) {
      _allPCBs[index] = updatedPCB;
      state = AsyncValue.data(List.from(_allPCBs));
    }
  }

  // Delete PCB
  void deletePCB(String pcbId) {
    _allPCBs.removeWhere((p) => p.id == pcbId);
    state = AsyncValue.data(List.from(_allPCBs));
  }

  // Update PCB BOM
  void updatePCBBOM(String pcbId, BOM bom) {
    int index = _allPCBs.indexWhere((p) => p.id == pcbId);
    if (index != -1) {
      _allPCBs[index] = _allPCBs[index].copyWith(
        bom: bom,
        updatedAt: DateTime.now(),
      );
      state = AsyncValue.data(List.from(_allPCBs));
    }
  }

  // Get PCB by ID
  PCB? getPCBById(String id) {
    return _allPCBs.where((p) => p.id == id).firstOrNull;
  }

  // Get PCBs for specific device
  List<PCB> getPCBsForDevice(String deviceId) {
    return _allPCBs.where((p) => p.deviceId == deviceId).toList();
  }

  // Get PCBs with BOM
  List<PCB> getPCBsWithBOM() {
    return _allPCBs.where((p) => p.hasBOM).toList();
  }

  // Get PCBs without BOM
  List<PCB> getPCBsWithoutBOM() {
    return _allPCBs.where((p) => !p.hasBOM).toList();
  }

  // Reset data
  void resetData() {
    _allPCBs.clear();
    state = const AsyncValue.data([]);
  }
}

// Provider instances
final pcbProvider = StateNotifierProvider<PCBNotifier, AsyncValue<List<PCB>>>(
  (ref) => PCBNotifier(),
);

// PCBs with BOM provider
final pcbsWithBOMProvider = Provider<List<PCB>>((ref) {
  final pcbsState = ref.watch(pcbProvider);
  return pcbsState.when(
    data: (pcbs) {
      final notifier = ref.read(pcbProvider.notifier);
      return notifier.getPCBsWithBOM();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// PCBs without BOM provider
final pcbsWithoutBOMProvider = Provider<List<PCB>>((ref) {
  final pcbsState = ref.watch(pcbProvider);
  return pcbsState.when(
    data: (pcbs) {
      final notifier = ref.read(pcbProvider.notifier);
      return notifier.getPCBsWithoutBOM();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// PCBs for device provider
final pcbsForDeviceProvider = Provider.family<List<PCB>, String>((
  ref,
  deviceId,
) {
  final pcbsState = ref.watch(pcbProvider);
  return pcbsState.when(
    data: (pcbs) {
      final notifier = ref.read(pcbProvider.notifier);
      return notifier.getPCBsForDevice(deviceId);
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
