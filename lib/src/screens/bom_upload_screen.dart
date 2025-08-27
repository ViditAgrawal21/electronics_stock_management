import 'package:flutter/material.dart';

class BomUploadScreen extends StatefulWidget {
  const BomUploadScreen({Key? key}) : super(key: key);

  @override
  State<BomUploadScreen> createState() => _BomUploadScreenState();
}

class _BomUploadScreenState extends State<BomUploadScreen> {
  bool _isLoading = false;
  String? _selectedFileName;
  List<Map<String, dynamic>> _bomData = [];
  final _pcbNameController = TextEditingController();

  // Mock BOM data after upload
  final List<Map<String, dynamic>> _mockBomData = [
    {
      'srNo': 1,
      'reference': 'R1,R2,R3',
      'value': '10K Resistor',
      'footprint': '0603',
      'qty': 3,
      'topBottom': 'Top',
    },
    {
      'srNo': 2,
      'reference': 'C1,C2',
      'value': '100uF Capacitor',
      'footprint': '0805',
      'qty': 2,
      'topBottom': 'Top',
    },
    {
      'srNo': 3,
      'reference': 'LED1',
      'value': 'Red LED 5mm',
      'footprint': 'LED_D5.0mm',
      'qty': 1,
      'topBottom': 'Top',
    },
    {
      'srNo': 4,
      'reference': 'U1',
      'value': 'Arduino Nano',
      'footprint': 'Module_Arduino',
      'qty': 1,
      'topBottom': 'Top',
    },
  ];

  @override
  void dispose() {
    _pcbNameController.dispose();
    super.dispose();
  }

  Future<void> _pickExcelFile() async {
    setState(() => _isLoading = true);

    // Simulate file picker
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _selectedFileName = 'bom_cape_board.xlsx';
      _isLoading = false;
    });

    _showSnackBar('Excel file selected: $_selectedFileName', Colors.blue);
  }

  Future<void> _uploadBom() async {
    if (_selectedFileName == null) {
      _showSnackBar('Please select an Excel file first', Colors.red);
      return;
    }

    if (_pcbNameController.text.trim().isEmpty) {
      _showSnackBar('Please enter PCB name', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    // Simulate BOM processing
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _bomData = List.from(_mockBomData);
      _isLoading = false;
    });

    _showSnackBar('BOM uploaded and processed successfully!', Colors.green);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveBom() async {
    if (_bomData.isEmpty) {
      _showSnackBar('No BOM data to save', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);

    _showSnackBar('BOM saved successfully!', Colors.green);
    Navigator.pop(context);
  }

  void _clearBom() {
    setState(() {
      _bomData.clear();
      _selectedFileName = null;
      _pcbNameController.clear();
    });
    _showSnackBar('BOM data cleared', Colors.orange);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BOM Upload'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        actions: [
          if (_bomData.isNotEmpty)
            IconButton(
              onPressed: _clearBom,
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear BOM',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // PCB Name Input
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PCB Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _pcbNameController,
                      decoration: InputDecoration(
                        labelText: 'PCB Name',
                        hintText: 'e.g., Cape Board, DIDO Board, LED Board',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.memory),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // File Upload Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload BOM Excel File',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Required format: Sr.No | Reference | Value | Footprint | Qty | Top/Bottom',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 16),

                    // File Selection
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedFileName != null
                              ? Colors.green
                              : Colors.grey[300]!,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: _selectedFileName != null
                            ? Colors.green[50]
                            : Colors.grey[50],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _selectedFileName != null
                                ? Icons.check_circle
                                : Icons.upload_file,
                            size: 48,
                            color: _selectedFileName != null
                                ? Colors.green
                                : Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedFileName ?? 'No file selected',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: _selectedFileName != null
                                  ? Colors.green[700]
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _pickExcelFile,
                            icon: const Icon(Icons.file_open),
                            label: const Text('Select Excel File'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Upload Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: (_isLoading || _selectedFileName == null)
                            ? null
                            : _uploadBom,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.upload),
                        label: Text(
                          _isLoading ? 'Processing...' : 'Upload & Process BOM',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // BOM Data Display
            if (_bomData.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'BOM Components (${_bomData.length} items)',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Chip(
                            label: Text(
                              'Total Qty: ${_bomData.fold(0, (sum, item) => sum + (item['qty'] as int))}',
                            ),
                            backgroundColor: Colors.blue[100],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // BOM Table
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Sr.No')),
                            DataColumn(label: Text('Reference')),
                            DataColumn(label: Text('Value')),
                            DataColumn(label: Text('Footprint')),
                            DataColumn(label: Text('Qty')),
                            DataColumn(label: Text('Side')),
                          ],
                          rows: _bomData
                              .map(
                                (item) => DataRow(
                                  cells: [
                                    DataCell(Text(item['srNo'].toString())),
                                    DataCell(
                                      Container(
                                        constraints: const BoxConstraints(
                                          maxWidth: 80,
                                        ),
                                        child: Text(
                                          item['reference'],
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        constraints: const BoxConstraints(
                                          maxWidth: 120,
                                        ),
                                        child: Text(
                                          item['value'],
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(item['footprint'])),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[100],
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          item['qty'].toString(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: item['topBottom'] == 'Top'
                                              ? Colors.green[100]
                                              : Colors.orange[100],
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          item['topBottom'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: item['topBottom'] == 'Top'
                                                ? Colors.green[700]
                                                : Colors.orange[700],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveBom,
                  icon: const Icon(Icons.save),
                  label: const Text('Save BOM'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
