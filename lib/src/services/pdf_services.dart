import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/devices.dart';
import '../models/bom.dart';
import '../models/pcb.dart';

class PDFService {
  static const int MAX_BOM_ITEMS_PER_PAGE = 35; // BOM items per page
  static const int MAX_BOM_ITEMS_PER_SECTION =
      25; // Items per section in multi-page layout

  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Enhanced single device PDF with proper BOM pagination
  static Future generateSingleDevicePDF(Device device) async {
    try {
      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(base: pw.Font.courier()),
      );

      // Calculate total BOM items to determine if we need pagination
      int totalBomItems = 0;
      for (final pcb in device.pcbs) {
        if (pcb.hasBOM && pcb.bom != null) {
          totalBomItems += pcb.bom!.items.length;
        }
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          maxPages: 1000, // Allow many pages for large BOMs
          build: (pw.Context context) {
            List<pw.Widget> widgets = [
              _buildDetailedPDFHeader(device),
              pw.SizedBox(height: 15),
              _buildDetailedDeviceInfo(device),
              pw.SizedBox(height: 15),
              _buildDetailedComponents(device),
              pw.SizedBox(height: 15),
              _buildPCBSummaryTable(device),
            ];

            // Add paginated BOM for each PCB that has BOM
            for (final pcb in device.pcbs) {
              if (pcb.hasBOM && pcb.bom != null) {
                widgets.add(pw.SizedBox(height: 20));
                widgets.addAll(_buildPaginatedBOMSections(pcb));
              }
            }

            return widgets;
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name:
            'Device_${device.name.replaceAll(' ', '_')}_Complete_BOM_Details.pdf',
      );

      return true;
    } catch (e) {
      print('Single device PDF generation error: $e');
      return false;
    }
  }

  // NEW: Build paginated BOM sections for large BOMs
  static List<pw.Widget> _buildPaginatedBOMSections(PCB pcb) {
    if (pcb.bom == null || pcb.bom!.items.isEmpty) {
      return [
        pw.Text(
          'No BOM items for ${pcb.name}',
          style: const pw.TextStyle(fontSize: 10),
        ),
      ];
    }

    List<pw.Widget> sections = [];
    List<BOMItem> bomItems = pcb.bom!.items;
    int totalItems = bomItems.length;

    // Add BOM header with statistics
    sections.add(_buildBOMHeader(pcb, totalItems));
    sections.add(pw.SizedBox(height: 10));

    // Split BOM into manageable chunks
    for (int i = 0; i < totalItems; i += MAX_BOM_ITEMS_PER_SECTION) {
      int endIndex = (i + MAX_BOM_ITEMS_PER_SECTION < totalItems)
          ? i + MAX_BOM_ITEMS_PER_SECTION
          : totalItems;

      List<BOMItem> sectionItems = bomItems.sublist(i, endIndex);
      int sectionNumber = (i ~/ MAX_BOM_ITEMS_PER_SECTION) + 1;
      int totalSections = (totalItems / MAX_BOM_ITEMS_PER_SECTION).ceil();

      sections.add(
        _buildBOMSection(
          pcb.name,
          sectionItems,
          sectionNumber,
          totalSections,
          i + 1, // Starting item number
        ),
      );

      // Add spacing between sections
      if (endIndex < totalItems) {
        sections.add(pw.SizedBox(height: 15));
        sections.add(_buildSectionBreak());
        sections.add(pw.SizedBox(height: 15));
      }
    }

    return sections;
  }

  // NEW: Build BOM header with statistics
  static pw.Widget _buildBOMHeader(PCB pcb, int totalItems) {
    // Calculate layer distribution
    int topLayerItems = pcb.bom!.items
        .where((item) => item.layer.toLowerCase() == 'top')
        .length;
    int bottomLayerItems = pcb.bom!.items
        .where((item) => item.layer.toLowerCase() == 'bottom')
        .length;
    int totalQuantity = pcb.bom!.items.fold(
      0,
      (sum, item) => sum + item.quantity,
    );

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Complete BOM for ${pcb.name}',
            style: const pw.TextStyle(fontSize: 14, color: PdfColors.blue900),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Total Components: $totalItems',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Total Quantity: $totalQuantity pieces',
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
                      'Top Layer: $topLayerItems items',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Bottom Layer: $bottomLayerItems items',
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

  // NEW: Build individual BOM section with page numbering
  static pw.Widget _buildBOMSection(
    String pcbName,
    List<BOMItem> sectionItems,
    int sectionNumber,
    int totalSections,
    int startingItemNumber,
  ) {
    List<pw.TableRow> bomRows = [
      // Header row
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text('S.No', style: const pw.TextStyle(fontSize: 8)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text('Reference', style: const pw.TextStyle(fontSize: 8)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text('Value', style: const pw.TextStyle(fontSize: 8)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text('Footprint', style: const pw.TextStyle(fontSize: 8)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text('Qty', style: const pw.TextStyle(fontSize: 8)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text('Layer', style: const pw.TextStyle(fontSize: 8)),
          ),
        ],
      ),
    ];

    // Add items with continuous numbering
    for (int i = 0; i < sectionItems.length; i++) {
      final item = sectionItems[i];
      bomRows.add(
        pw.TableRow(
          decoration: i % 2 == 0
              ? const pw.BoxDecoration(color: PdfColors.grey50)
              : null,
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                (startingItemNumber + i).toString(),
                style: const pw.TextStyle(fontSize: 7),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                item.reference,
                style: const pw.TextStyle(fontSize: 7),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                item.value,
                style: const pw.TextStyle(fontSize: 7),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                item.footprint,
                style: const pw.TextStyle(fontSize: 7),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                item.quantity.toString(),
                style: const pw.TextStyle(fontSize: 7),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                item.layer,
                style: pw.TextStyle(
                  fontSize: 7,
                  color: item.layer.toLowerCase() == 'top'
                      ? PdfColors.blue
                      : PdfColors.orange,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Section header
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '$pcbName - Section $sectionNumber of $totalSections',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.Text(
              'Items $startingItemNumber-${startingItemNumber + sectionItems.length - 1}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
        pw.SizedBox(height: 5),
        // BOM table
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
            4: const pw.FlexColumnWidth(1),
            5: const pw.FlexColumnWidth(1),
          },
          children: bomRows,
        ),
      ],
    );
  }

  // NEW: Visual section break
  static pw.Widget _buildSectionBreak() {
    return pw.Container(
      width: double.infinity,
      height: 1,
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
            color: PdfColors.grey400,
            width: 1,
            style: pw.BorderStyle.dashed,
          ),
        ),
      ),
    );
  }

  // Enhanced device info with BOM statistics
  static pw.Widget _buildDetailedDeviceInfo(Device device) {
    int totalBomItems = 0;
    int totalBomQuantity = 0;

    for (final pcb in device.pcbs) {
      if (pcb.hasBOM && pcb.bom != null) {
        totalBomItems += pcb.bom!.items.length;
        totalBomQuantity += pcb.bom!.totalComponents;
      }
    }

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
            'Device Information & BOM Summary',
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
                      'Total Sub-Components: ${device.subComponents.length}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Total PCB Boards: ${device.pcbs.length}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Complete BOM Items: $totalBomItems',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.blue,
                      ),
                    ),
                    pw.Text(
                      'Total BOM Quantity: $totalBomQuantity pieces',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.blue,
                      ),
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

  // Keep existing methods unchanged
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
                'Complete Device & BOM Report',
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

  // Keep all other existing methods unchanged...
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
              'Total Qty',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    ];

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
                pcb.hasBOM ? 'Complete BOM' : 'No BOM',
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
                pcb.hasBOM && pcb.bom != null
                    ? '${pcb.bom!.totalComponents} pcs'
                    : '-',
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
            3: const pw.FlexColumnWidth(2),
          },
          children: pcbRows,
        ),
      ],
    );
  }

  // Multiple devices PDF - Summary report for all finished goods
  static Future generateMultipleDevicesPDF(List<Device> devices) async {
    try {
      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(base: pw.Font.courier()),
      );

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
      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(base: pw.Font.courier()),
      );

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
