import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/devices.dart';
// import '../models/bom.dart';
// import '../models/pcb.dart';

class PDFService {
  static const int MAX_BOM_ITEMS_PER_PAGE = 25; // Limit BOM items per page

  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Single device PDF - Complete detailed report with PCB summary (no full BOM)
  static Future generateSingleDevicePDF(Device device) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return [
              _buildDetailedPDFHeader(device),
              pw.SizedBox(height: 15),
              _buildDetailedDeviceInfo(device),
              pw.SizedBox(height: 15),
              _buildDetailedComponents(device),
              pw.SizedBox(height: 15),
              _buildPCBSummaryTable(device), // Changed from full BOM to summary
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Device_${device.name.replaceAll(' ', '_')}_Complete_Details.pdf',
      );

      return true;
    } catch (e) {
      print('Single device PDF generation error: $e');
      return false;
    }
  }

  // Multiple devices PDF - Summary report for all finished goods
  static Future generateMultipleDevicesPDF(List<Device> devices) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildAllDevicesHeader(devices),
                pw.SizedBox(height: 20),
                _buildAllDevicesSummary(devices),
                pw.SizedBox(height: 20),
                _buildOverallStatistics(devices),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'All_Finished_Good_Products_Summary.pdf',
      );

      return true;
    } catch (e) {
      print('All devices PDF generation error: $e');
      return false;
    }
  }

  // Header for single device detailed report
  static pw.Widget _buildDetailedPDFHeader(Device device) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Detailed Device Report',
                style: const pw.TextStyle(
                  fontSize: 20,
                  color: PdfColors.blue900,
                ),
              ),
              pw.Text(
                'Generated: ${_formatDateTime(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(device.name, style: const pw.TextStyle(fontSize: 16)),
          if (device.description != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              device.description!,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  // Header for all devices summary report
  static pw.Widget _buildAllDevicesHeader(List<Device> devices) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Text(
              'All Finished Good Products',
              style: const pw.TextStyle(
                fontSize: 24,
                color: PdfColors.green900,
              ),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total Products: ${devices.length}',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.Text(
                'Generated: ${_formatDateTime(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Detailed device info for single device report
  static pw.Widget _buildDetailedDeviceInfo(Device device) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Device Information',
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Created: ${_formatDateTime(device.createdAt)}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Updated: ${_formatDateTime(device.updatedAt)}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Status: ${device.isReadyForProduction ? "Ready for Production" : "Pending BOM Upload"}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Total Components: ${device.subComponents.length}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Total PCB Boards: ${device.pcbs.length}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Total BOM Items: ${device.totalBomItems}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Complete detailed components list with names and quantities
  static pw.Widget _buildDetailedComponents(Device device) {
    if (device.subComponents.isEmpty) {
      return pw.Text(
        'No components defined',
        style: const pw.TextStyle(fontSize: 10),
      );
    }

    List<pw.TableRow> componentRows = [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(
              'Component Name',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text('Quantity', style: const pw.TextStyle(fontSize: 10)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(
              'Description',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    ];

    // Show ALL components without restriction
    for (final component in device.subComponents) {
      componentRows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                component.name,
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                component.quantity.toString(),
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                component.description ?? '-',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
          ],
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Components Details (${device.subComponents.length} total)',
          style: const pw.TextStyle(fontSize: 14),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(3),
          },
          children: componentRows,
        ),
      ],
    );
  }

  // NEW: PCB Summary Table - Shows PCB names and component counts only
  static pw.Widget _buildPCBSummaryTable(Device device) {
    if (device.pcbs.isEmpty) {
      return pw.Text(
        'No PCB boards defined',
        style: const pw.TextStyle(fontSize: 10),
      );
    }

    List<pw.TableRow> pcbRows = [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text('PCB Name', style: const pw.TextStyle(fontSize: 10)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(
              'BOM Status',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(
              'Components',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(
              'Description',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    ];

    // Show ALL PCBs with their component counts
    for (final pcb in device.pcbs) {
      pcbRows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(pcb.name, style: const pw.TextStyle(fontSize: 9)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                pcb.hasBOM ? 'Available' : 'No BOM',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: pcb.hasBOM ? PdfColors.green : PdfColors.orange,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                pcb.hasBOM ? '${pcb.uniqueComponents} items' : '-',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                pcb.description ?? '-',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
          ],
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'PCB Boards Summary (${device.pcbs.length} total)',
          style: const pw.TextStyle(fontSize: 14),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(3),
          },
          children: pcbRows,
        ),
      ],
    );
  }

  // REMOVED: The old _buildDetailedPCBsWithCompleteBOM and _buildCompleteBOMTable methods
  // These are no longer needed since we're just showing PCB summaries

  // Summary for all devices - just counts
  static pw.Widget _buildAllDevicesSummary(List<Device> devices) {
    List<pw.TableRow> deviceRows = [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Device Name',
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Components Count',
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'PCB Count',
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text('Status', style: const pw.TextStyle(fontSize: 11)),
          ),
        ],
      ),
    ];

    for (final device in devices) {
      deviceRows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                device.name,
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                device.subComponents.length.toString(),
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                device.pcbs.length.toString(),
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                device.isReadyForProduction ? 'Ready' : 'Pending',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Devices Summary', style: const pw.TextStyle(fontSize: 16)),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
          },
          children: deviceRows,
        ),
      ],
    );
  }

  // Overall statistics for all devices
  static pw.Widget _buildOverallStatistics(List<Device> devices) {
    final totalComponents = devices.fold<int>(
      0,
      (sum, device) => sum + device.subComponents.length,
    );
    final totalPCBs = devices.fold<int>(
      0,
      (sum, device) => sum + device.pcbs.length,
    );
    final readyDevices = devices.where((d) => d.isReadyForProduction).length;
    final totalBOMItems = devices.fold<int>(
      0,
      (sum, device) => sum + device.totalBomItems,
    );

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Overall Statistics',
            style: const pw.TextStyle(fontSize: 16),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Total Finished Products: ${devices.length}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    pw.Text(
                      'Ready for Production: $readyDevices',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Total Components Used: $totalComponents',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    pw.Text(
                      'Total PCB Boards: $totalPCBs',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Total BOM Items Across All Devices: $totalBOMItems',
            style: const pw.TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  // Production report generation
  static Future<bool> generateProductionReportPDF(
    List<Device> devices,
    Map<String, dynamic> stats,
  ) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildProductionReportHeader(),
                pw.SizedBox(height: 20),
                _buildProductionStats(stats),
                pw.SizedBox(height: 20),
                _buildAllDevicesSummary(devices),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Production_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      return true;
    } catch (e) {
      print('Production report PDF generation error: $e');
      return false;
    }
  }

  static pw.Widget _buildProductionReportHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Production Report',
            style: const pw.TextStyle(fontSize: 20, color: PdfColors.orange900),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Generated: ${_formatDateTime(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildProductionStats(Map<String, dynamic> stats) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Production Statistics',
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Total Devices: ${stats['totalDevices'] ?? 0}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Ready for Production: ${stats['readyDevices'] ?? 0}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Total Components: ${stats['totalComponents'] ?? 0}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Total PCBs: ${stats['totalPcbs'] ?? 0}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
