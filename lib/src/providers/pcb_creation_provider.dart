import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/devices.dart';
import '../models/pcb.dart';
import '../models/bom.dart';

/// Provider for managing temporary device creation state
/// This ensures that form data persists across navigation
class PcbCreationNotifier extends StateNotifier<PcbCreationState> {
  PcbCreationNotifier() : super(PcbCreationState());

  /// Initialize state for editing an existing device
  void initializeForEdit(Device device) {
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
  }

  /// Initialize state for creating a new device
  void initializeForCreate() {
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
  }

  /// Update device name
  void updateDeviceName(String name) {
    state = state.copyWith(deviceName: name);
  }

  /// Update description
  void updateDescription(String description) {
    state = state.copyWith(description: description);
  }

  /// Update quantity
  void updateQuantity(String quantity) {
    state = state.copyWith(quantity: quantity);
  }

  /// Add a sub component
  void addSubComponent(SubComponent component) {
    state = state.copyWith(subComponents: [...state.subComponents, component]);
  }

  /// Update a sub component
  void updateSubComponent(int index, SubComponent component) {
    final updatedComponents = List<SubComponent>.from(state.subComponents);
    updatedComponents[index] = component;
    state = state.copyWith(subComponents: updatedComponents);
  }

  /// Remove a sub component
  void removeSubComponent(int index) {
    final updatedComponents = List<SubComponent>.from(state.subComponents);
    updatedComponents.removeAt(index);
    state = state.copyWith(subComponents: updatedComponents);
  }

  /// Add a PCB
  void addPcb(PCB pcb) {
    state = state.copyWith(pcbs: [...state.pcbs, pcb]);
  }

  /// Update a PCB
  void updatePcb(int index, PCB pcb) {
    final updatedPcbs = List<PCB>.from(state.pcbs);
    updatedPcbs[index] = pcb;
    state = state.copyWith(pcbs: updatedPcbs);
  }

  /// Remove a PCB
  void removePcb(int index) {
    final updatedPcbs = List<PCB>.from(state.pcbs);
    updatedPcbs.removeAt(index);
    state = state.copyWith(pcbs: updatedPcbs);
  }

  /// Replace all sub components (useful for Excel upload)
  void setSubComponents(List<SubComponent> components) {
    state = state.copyWith(subComponents: components);
  }

  /// Replace all PCBs
  void setPcbs(List<PCB> pcbs) {
    state = state.copyWith(pcbs: pcbs);
  }

  /// Clear all data (reset form)
  void clear() {
    state = PcbCreationState();
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
}

// Provider instance
final pcbCreationProvider =
    StateNotifierProvider<PcbCreationNotifier, PcbCreationState>((ref) {
      return PcbCreationNotifier();
    });
