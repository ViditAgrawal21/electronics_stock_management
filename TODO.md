# TODO: Fix Excel Import and Export Issues

## Export Issue (Fixed)
- Error: UnimplementedError: getExternalStoragePath() has not been implemented.
- Occurs when exporting materials to Excel on Android.
- Root cause: Using `getExternalStorageDirectory()` which is not implemented on all platforms.

## Import Issue (Fixed)
- When importing Excel, it was picking random numbers instead of exact values.
- User wants exact Excel format preserved (A: Raw Materials name, B: Initial Quantity).
- Root cause: Conversion logic was evaluating cell values instead of preserving display text.

## Plan
- [x] Update `exportMaterials` method in `lib/src/services/excel_service.dart` to use `getApplicationDocumentsDirectory()` instead of `getExternalStorageDirectory()`.
- [x] Update `exportBOM` method similarly.
- [x] Update `createBOMTemplate` method similarly.
- [x] Update `importMaterials` to use exact string values from Excel cells without conversion.
- [ ] Test import and export functionality.

## Dependent Files
- `lib/src/services/excel_service.dart`: Code changes for both import and export.

## Followup Steps
- [ ] Run the app on Android and test material import from Excel (2-column format: Name, Initial Quantity).
- [ ] Test material export to Excel.
- [ ] Verify exported files are saved in the Downloads directory.
- [ ] Confirm imported materials have exact names and quantities as in Excel.
- [x] Added reset function to clear all app data (materials, devices, production history).
