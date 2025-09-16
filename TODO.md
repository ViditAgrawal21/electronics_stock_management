# Material Usage Tracking and Reversion Implementation

## Overview
Implement material usage tracking and reversion logic for device creation, BOM upload, and production flows. Ensure materials are marked as used when allocated to devices and reverted when devices are deleted. Update UI to reflect used/available status.

## Current Implementation Status
- ✅ Material model tracks `usedQuantity`, `remainingQuantity`, `initialQuantity`
- ✅ Materials provider has `useMaterialsByNames` and `addMaterialsByNames` for deduction/addition
- ✅ Device provider deducts materials during production (`produceDevice`)
- ✅ Device provider reverts materials during device deletion (`deleteDevice`)
- ✅ UI shows stock status based on remaining quantities
- ✅ BOM upload screen analyzes material requirements
- ✅ PCB creation screen shows production feasibility

## Pending Tasks

### 1. Verify Material Deduction Timing
- [ ] Confirm if materials should be deducted at device creation or only at production
- [ ] Check if subComponents should be treated as materials (currently not deducted)
- [ ] Verify BOM upload does not deduct materials (only analyzes)

### 2. Improve Material Allocation Logic
- [x] Modify `calculateDeviceMaterialRequirements` to include subComponents if they are materials
- [x] Decide on deduction timing: device creation vs production (decided to keep at production, but include subComponents)
- [ ] Update `addDevice` to deduct materials if needed
- [ ] Update `updatePcbBOM` to deduct materials when BOM uploaded if needed

### 3. Enhance UI Status Display
- [ ] Ensure materials list clearly shows used/available status
- [ ] Add visual indicators for allocated vs used materials
- [ ] Update BOM upload screen to show allocation status

### 4. Add Material Status Field (Optional)
- [ ] Consider adding `isAllocated` or `status` field to Material model
- [ ] Update providers to set allocation status
- [ ] Update UI to show allocation status

### 5. Testing and Integration
- [ ] Test device creation with components and BOM
- [ ] Test BOM upload and material analysis
- [ ] Test production and material deduction
- [ ] Test device deletion and material reversion
- [ ] Verify UI updates correctly

### 6. Documentation
- [ ] Add comments to clarify material usage logic
- [ ] Update README with material tracking features

## Implementation Plan
1. Analyze current flows and decide on deduction timing
2. Update providers for consistent material handling
3. Enhance UI for better status visibility
4. Test all flows thoroughly
5. Document the implementation

## Files to Modify
- `lib/src/models/materials.dart` (if adding status field)
- `lib/src/providers/device_providers.dart` (allocation logic)
- `lib/src/providers/materials_providers.dart` (status updates)
- `lib/src/screens/bom_upload_screen.dart` (UI updates)
- `lib/src/screens/pcb_creation_screen.dart` (UI updates)
- `lib/src/screens/materials_list_screen.dart` (status display)
