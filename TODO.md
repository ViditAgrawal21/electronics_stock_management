# Device Creation with Quantity and Stock Management Implementation

## Overview
Implement device creation functionality with quantity input, material requirements indication, stock availability checks, stock deduction on production, and dynamic alerts for low stock materials.

## Tasks

### 1. Update PCB Creation Screen (lib/src/screens/pcb_creation_screen.dart)
- [x] Add quantity input field for device production
- [x] Add material requirements display section
- [x] Add stock availability and shortage indication
- [x] Add max producible quantity calculation and display
- [x] Add "Fill up stock" message when stock is insufficient
- [x] Update create button logic to handle production confirmation
- [x] Implement stock deduction and production recording on confirmation

### 2. Update Device Provider (lib/src/providers/device_providers.dart)
- [ ] Ensure calculateBatchMaterialRequirements works correctly
- [ ] Ensure checkProductionFeasibility works correctly
- [ ] Ensure recordProduction works correctly
- [ ] Add any helper methods if needed for UI integration

### 3. Update Materials Provider (lib/src/providers/materials_providers.dart)
- [ ] Ensure useMaterials method works correctly for stock deduction
- [ ] Ensure getLowStockMaterials works correctly

### 4. Update Alerts Screen (lib/src/screens/alerts_screen.dart)
- [x] Replace mock alerts with real-time stock alerts
- [x] Integrate with materialsProvider.getLowStockMaterials
- [x] Add refresh functionality for alerts
- [x] Show critical, low, and out of stock alerts dynamically

### 5. Testing and Validation
- [ ] Test device creation with quantity input
- [ ] Test material requirements calculation
- [ ] Test stock availability checks
- [ ] Test stock deduction on production
- [ ] Test alerts for low stock materials
- [ ] Test edge cases (insufficient stock, partial production)

## Dependencies
- Device model and ProductionRecord model
- Materials model with stock tracking
- Existing provider methods for calculations and updates

## Notes
- Use existing calculateBatchMaterialRequirements and checkProductionFeasibility methods
- Use existing useMaterials method for stock deduction
- Use existing getLowStockMaterials for alerts
- Integrate with existing UI patterns and styling
