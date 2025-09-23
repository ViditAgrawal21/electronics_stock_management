import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/devices.dart';
import '../models/bom.dart';
import '../models/pcb.dart';

class PDFService {
  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Helper method to load fonts with fallback
  static Future<pw.Font> _loadFont() async {
    try {
      return await PdfGoogleFonts.notoSansRegular();
    } catch (e) {
      try {
        return await PdfGoogleFonts.robotoRegular();
      } catch (e2) {
        return pw.Font.helvetica();
      }
    }
  }

  static Future<pw.Font?> _loadBoldFont() async {
    try {
      return await PdfGoogleFonts.notoSansBold();
    } catch (e) {
      try {
        return await PdfGoogleFonts.robotoBold();
      } catch (e2) {
        return pw.Font.helveticaBold();
      }
    }
  }

  // MAIN METHOD - Generate single device PDF
  static Future<bool> generateSingleDevicePDF(Device device) async {
    try {
      final baseFont = await _loadFont();
      final boldFont = await _loadBoldFont();

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: boldFont ?? baseFont,
        ),
      );

      print('Generating single PDF for ${device.name}');

      // Add pages one by one to avoid limits
      _addOverviewPage(pdf, device);
      _addComponentPages(pdf, device);
      _addBOMPages(pdf, device);

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'Device_${device.name.replaceAll(' ', '_')}_Complete.pdf',
      );

      print('Single PDF generated successfully');
      return true;
    } catch (e) {
      print('PDF generation error: $e');
      return false;
    }
  }

  // Add overview page
  static void _addOverviewPage(pw.Document pdf, Device device) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildPDFHeader(device),
            pw.SizedBox(height: 15),
            _buildDeviceInfo(device),
            pw.SizedBox(height: 15),
            _buildPCBSummary(device),
            pw.Spacer(),
            pw.Text(
              'Components and BOM details on following pages',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ],
        ),
      ),
    );
  }

  // Add component pages (split into smaller chunks)
  static void _addComponentPages(pw.Document pdf, Device device) {
    if (device.subComponents.isEmpty) return;

    List<dynamic> components = device.subComponents;
    int itemsPerPage = 15; // Small number to avoid page limits

    for (int i = 0; i < components.length; i += itemsPerPage) {
      int endIndex = (i + itemsPerPage < components.length)
          ? i + itemsPerPage
          : components.length;
      List<dynamic> pageComponents = components.sublist(i, endIndex);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildPageHeader(
                device.name,
                'Components',
                i + 1,
                endIndex,
                components.length,
              ),
              pw.SizedBox(height: 15),
              _buildComponentsTable(pageComponents, i + 1),
              pw.Spacer(),
              _buildPageFooter('Components'),
            ],
          ),
        ),
      );
    }
  }

  // Add BOM pages
  static void _addBOMPages(pw.Document pdf, Device device) {
    for (final pcb in device.pcbs) {
      if (pcb.hasBOM && pcb.bom != null && pcb.bom!.items.isNotEmpty) {
        List<BOMItem> bomItems = pcb.bom!.items;
        int itemsPerPage = 20;

        for (int i = 0; i < bomItems.length; i += itemsPerPage) {
          int endIndex = (i + itemsPerPage < bomItems.length)
              ? i + itemsPerPage
              : bomItems.length;
          List<BOMItem> pageBomItems = bomItems.sublist(i, endIndex);

          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: const pw.EdgeInsets.all(20),
              build: (context) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildPageHeader(
                    device.name,
                    '${pcb.name} BOM',
                    i + 1,
                    endIndex,
                    bomItems.length,
                  ),
                  pw.SizedBox(height: 15),
                  _buildBOMTable(pageBomItems, i + 1),
                  pw.Spacer(),
                  _buildPageFooter('${pcb.name} BOM'),
                ],
              ),
            ),
          );
        }
      }
    }
  }

  // Build PDF header
  static pw.Widget _buildPDFHeader(Device device) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: const pw.BoxDecoration(color: PdfColors.blue50),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Complete Device Report',
            style: const pw.TextStyle(fontSize: 18, color: PdfColors.blue900),
          ),
          pw.SizedBox(height: 5),
          pw.Text(device.name, style: const pw.TextStyle(fontSize: 16)),
          pw.Text(
            'Generated: ${_formatDateTime(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  // Build page header
  static pw.Widget _buildPageHeader(
    String deviceName,
    String section,
    int startNum,
    int endNum,
    int total,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '$deviceName - $section',
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.Text(
            'Items $startNum-$endNum of $total',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  // Build device info
  static pw.Widget _buildDeviceInfo(Device device) {
    int totalBomItems = 0;
    for (final pcb in device.pcbs) {
      if (pcb.hasBOM && pcb.bom != null) {
        totalBomItems += pcb.bom!.items.length;
      }
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
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
                      'Status: ${device.isReadyForProduction ? "Ready" : "Pending"}',
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
                      'Components: ${device.subComponents.length}',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.green,
                      ),
                    ),
                    pw.Text(
                      'PCB Boards: ${device.pcbs.length}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'BOM Items: $totalBomItems',
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

  // Build PCB summary
  static pw.Widget _buildPCBSummary(Device device) {
    if (device.pcbs.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('PCB Summary', style: const pw.TextStyle(fontSize: 14)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'PCB Name',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'BOM Status',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'Components',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              ],
            ),
            ...device.pcbs
                .take(5)
                .map(
                  (pcb) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          pcb.name,
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          pcb.hasBOM ? 'Complete' : 'No BOM',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          pcb.hasBOM && pcb.bom != null
                              ? '${pcb.bom!.items.length}'
                              : '-',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ],
    );
  }

  // Build components table
  static pw.Widget _buildComponentsTable(
    List<dynamic> components,
    int startNum,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(3),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('#', style: const pw.TextStyle(fontSize: 9)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                'Component Name',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Qty', style: const pw.TextStyle(fontSize: 9)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                'Description',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
          ],
        ),
        // Data rows
        ...components.asMap().entries.map((entry) {
          int idx = entry.key;
          var component = entry.value;
          return pw.TableRow(
            decoration: idx % 2 == 0
                ? const pw.BoxDecoration(color: PdfColors.grey50)
                : null,
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  (startNum + idx).toString(),
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  component.name ?? 'N/A',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  (component.quantity ?? 0).toString(),
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  _truncateText(component.description ?? '-', 40),
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  // Build BOM table
  static pw.Widget _buildBOMTable(List<BOMItem> bomItems, int startNum) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(1),
        5: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('#', style: const pw.TextStyle(fontSize: 8)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                'Reference',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Value', style: const pw.TextStyle(fontSize: 8)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                'Footprint',
                style: const pw.TextStyle(fontSize: 8),
              ),
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
        // Data rows
        ...bomItems.asMap().entries.map((entry) {
          int idx = entry.key;
          BOMItem item = entry.value;
          return pw.TableRow(
            decoration: idx % 2 == 0
                ? const pw.BoxDecoration(color: PdfColors.grey50)
                : null,
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  (startNum + idx).toString(),
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  _truncateText(item.reference, 12),
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  _truncateText(item.value, 12),
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  _truncateText(item.footprint, 15),
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
                  item.layer.substring(0, 1).toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 7,
                    color: item.layer.toLowerCase() == 'top'
                        ? PdfColors.blue
                        : PdfColors.orange,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  // Build page footer
  static pw.Widget _buildPageFooter(String section) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      padding: const pw.EdgeInsets.only(top: 5),
      child: pw.Text(
        '$section - Generated ${_formatDateTime(DateTime.now())}',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ),
    );
  }

  // Helper to truncate text
  static String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  // MULTIPLE DEVICES PDF
  static Future<bool> generateMultipleDevicesPDF(List<Device> devices) async {
    try {
      final baseFont = await _loadFont();
      final boldFont = await _loadBoldFont();

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: boldFont ?? baseFont,
        ),
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: const pw.BoxDecoration(color: PdfColors.green50),
                child: pw.Text(
                  'All Finished Good Products',
                  style: const pw.TextStyle(
                    fontSize: 20,
                    color: PdfColors.green900,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Total Products: ${devices.length}',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 20),
              // Simple devices list
              ...devices
                  .take(10)
                  .map(
                    (device) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2),
                      child: pw.Text(
                        '• ${device.name}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'All_Devices_Summary.pdf',
      );

      return true;
    } catch (e) {
      print('Multiple devices PDF error: $e');
      return false;
    }
  }

  // PRODUCTION REPORT PDF
  static Future<bool> generateProductionReportPDF(
    List<Device> devices,
    Map<String, dynamic> stats,
  ) async {
    try {
      final baseFont = await _loadFont();
      final boldFont = await _loadBoldFont();

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: boldFont ?? baseFont,
        ),
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: const pw.BoxDecoration(color: PdfColors.orange50),
                child: pw.Text(
                  'Production Report',
                  style: const pw.TextStyle(
                    fontSize: 20,
                    color: PdfColors.orange900,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Generated: ${_formatDateTime(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Total Devices: ${stats['totalDevices'] ?? devices.length}',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Text(
                'Ready for Production: ${stats['readyDevices'] ?? 0}',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Text(
                'Total Components: ${stats['totalComponents'] ?? 0}',
                style: const pw.TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'Production_Report.pdf',
      );

      return true;
    } catch (e) {
      print('Production report error: $e');
      return false;
    }
  }
}
