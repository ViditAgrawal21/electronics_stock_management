import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/devices.dart';
import '../models/pcb.dart';

/// Provider for managing temporary device creation state
/// This ensures that form data persists across navigation
class PcbCreationNotifier extends StateNotifier<PcbCreationState> {
  PcbCreationNotifier() : super(PcbCreationState());

  /// Initialize state for editing an existing device
  void initializeForEdit(Device device) {
    print('🔄 PCB Provider - Initializing for edit: ${device.name}');
    state = state.copyWith(
      deviceToEdit: device,
      deviceName: device.name,
      description: device.description ?? '',
      quantity: '1',
      subComponents: List.from(device.subComponents),
      pcbs: List.from(device.pcbs),
      currentDeviceId: device.id,
      isEditMode: true,
    );
    print(
      '🔄 PCB Provider - Edit state set with ${state.subComponents.length} components, ${state.pcbs.length} PCBs',
    );
  }

  /// Initialize state for creating a new device
  void initializeForCreate() {
    print('🔄 PCB Provider - Initializing for create');
    state = state.copyWith(
      deviceToEdit: null,
      deviceName: '',
      description: '',
      quantity: '1',
      subComponents: [],
      pcbs: [],
      currentDeviceId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      isEditMode: false,
    );
    print('🔄 PCB Provider - Create state initialized');
  }

  /// Restore state from backup data
  void restoreState({
    required String deviceName,
    required String description,
    required String quantity,
    required List<SubComponent> subComponents,
    required List<PCB> pcbs,
  }) {
    print(
      '🔄 PCB Provider - Restoring state: $deviceName with ${subComponents.length} components, ${pcbs.length} PCBs',
    );
    state = state.copyWith(
      deviceName: deviceName,
      description: description,
      quantity: quantity,
      subComponents: List.from(subComponents),
      pcbs: List.from(pcbs),
    );
    print('🔄 PCB Provider - State restored successfully');
  }

  /// Update device name
  void updateDeviceName(String name) {
    print('🔄 PCB Provider - Updating device name: $name');
    state = state.copyWith(deviceName: name);
  }

  /// Update description
  void updateDescription(String description) {
    print('🔄 PCB Provider - Updating description');
    state = state.copyWith(description: description);
  }

  /// Update quantity
  void updateQuantity(String quantity) {
    print('🔄 PCB Provider - Updating quantity: $quantity');
    state = state.copyWith(quantity: quantity);
  }

  /// Add a sub component
  void addSubComponent(SubComponent component) {
    print('🔄 PCB Provider - Adding component: ${component.name}');
    state = state.copyWith(subComponents: [...state.subComponents, component]);
    print(
      '🔄 PCB Provider - Total components now: ${state.subComponents.length}',
    );
  }

  /// Update a sub component
  void updateSubComponent(int index, SubComponent component) {
    print(
      '🔄 PCB Provider - Updating component at index $index: ${component.name}',
    );
    final updatedComponents = List<SubComponent>.from(state.subComponents);
    updatedComponents[index] = component;
    state = state.copyWith(subComponents: updatedComponents);
  }

  /// Remove a sub component
  void removeSubComponent(int index) {
    if (index >= 0 && index < state.subComponents.length) {
      print(
        '🔄 PCB Provider - Removing component at index $index: ${state.subComponents[index].name}',
      );
      final updatedComponents = List<SubComponent>.from(state.subComponents);
      updatedComponents.removeAt(index);
      state = state.copyWith(subComponents: updatedComponents);
      print(
        '🔄 PCB Provider - Total components now: ${state.subComponents.length}',
      );
    }
  }

  /// Add a PCB
  void addPcb(PCB pcb) {
    print('🔄 PCB Provider - Adding PCB: ${pcb.name}');
    state = state.copyWith(pcbs: [...state.pcbs, pcb]);
    print('🔄 PCB Provider - Total PCBs now: ${state.pcbs.length}');
  }

  /// Update a PCB
  void updatePcb(int index, PCB pcb) {
    if (index >= 0 && index < state.pcbs.length) {
      print('🔄 PCB Provider - Updating PCB at index $index: ${pcb.name}');
      final updatedPcbs = List<PCB>.from(state.pcbs);
      updatedPcbs[index] = pcb;
      state = state.copyWith(pcbs: updatedPcbs);
      print('🔄 PCB Provider - PCB updated with BOM: ${pcb.hasBOM}');
    }
  }

  /// Remove a PCB
  void removePcb(int index) {
    if (index >= 0 && index < state.pcbs.length) {
      print(
        '🔄 PCB Provider - Removing PCB at index $index: ${state.pcbs[index].name}',
      );
      final updatedPcbs = List<PCB>.from(state.pcbs);
      updatedPcbs.removeAt(index);
      state = state.copyWith(pcbs: updatedPcbs);
      print('🔄 PCB Provider - Total PCBs now: ${state.pcbs.length}');
    }
  }

  /// Replace all sub components (useful for Excel upload)
  void setSubComponents(List<SubComponent> components) {
    print(
      '🔄 PCB Provider - Setting ${components.length} components from Excel',
    );
    state = state.copyWith(subComponents: List.from(components));
    print('🔄 PCB Provider - Components set successfully');
  }

  /// Replace all PCBs
  void setPcbs(List<PCB> pcbs) {
    print('🔄 PCB Provider - Setting ${pcbs.length} PCBs');
    state = state.copyWith(pcbs: List.from(pcbs));
  }

  /// Clear all data (reset form)
  void clear() {
    print('🔄 PCB Provider - Clearing all state');
    state = PcbCreationState();
  }

  /// Reset to empty state but preserve current device ID
  void reset() {
    print('🔄 PCB Provider - Resetting to empty state');
    state = PcbCreationState(
      currentDeviceId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      isEditMode: false,
    );
  }

  /// Get current device data as a Device object
  Device? getCurrentDevice() {
    if (state.deviceName.trim().isEmpty) return null;

    return Device(
      id: state.currentDeviceId,
      name: state.deviceName.trim(),
      subComponents: state.subComponents,
      pcbs: state.pcbs,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      description: state.description.trim().isEmpty
          ? null
          : state.description.trim(),
    );
  }

  /// Check if form is valid
  bool isFormValid() {
    return state.deviceName.trim().isNotEmpty &&
        state.pcbs.isNotEmpty &&
        int.tryParse(state.quantity) != null &&
        int.tryParse(state.quantity)! > 0;
  }

  /// Get debug info about current state
  Map<String, dynamic> getDebugInfo() {
    return {
      'deviceName': state.deviceName,
      'componentCount': state.subComponents.length,
      'pcbCount': state.pcbs.length,
      'quantity': state.quantity,
      'isEditMode': state.isEditMode,
      'currentDeviceId': state.currentDeviceId,
    };
  }

  @override
  void dispose() {
    print('🔄 PCB Provider - DISPOSING provider');
    super.dispose();
  }
}

/// State class for PCB creation
class PcbCreationState {
  final Device? deviceToEdit;
  final String deviceName;
  final String description;
  final String quantity;
  final List<SubComponent> subComponents;
  final List<PCB> pcbs;
  final String currentDeviceId;
  final bool isEditMode;

  const PcbCreationState({
    this.deviceToEdit,
    this.deviceName = '',
    this.description = '',
    this.quantity = '1',
    this.subComponents = const [],
    this.pcbs = const [],
    this.currentDeviceId = '',
    this.isEditMode = false,
  });

  PcbCreationState copyWith({
    Device? deviceToEdit,
    String? deviceName,
    String? description,
    String? quantity,
    List<SubComponent>? subComponents,
    List<PCB>? pcbs,
    String? currentDeviceId,
    bool? isEditMode,
  }) {
    return PcbCreationState(
      deviceToEdit: deviceToEdit ?? this.deviceToEdit,
      deviceName: deviceName ?? this.deviceName,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      subComponents: subComponents ?? this.subComponents,
      pcbs: pcbs ?? this.pcbs,
      currentDeviceId: currentDeviceId ?? this.currentDeviceId,
      isEditMode: isEditMode ?? this.isEditMode,
    );
  }

  @override
  String toString() {
    return 'PcbCreationState(deviceName: $deviceName, components: ${subComponents.length}, pcbs: ${pcbs.length})';
  }
}

// Provider instance with keepAlive to prevent disposal
final pcbCreationProvider =
    StateNotifierProvider<PcbCreationNotifier, PcbCreationState>((ref) {
      print('🔄 PCB Provider - Creating new provider instance');
      final notifier = PcbCreationNotifier();

      // Keep the provider alive to prevent disposal during navigation
      ref.keepAlive();

      return notifier;
    });
