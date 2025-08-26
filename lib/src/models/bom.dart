class BOMItem {
  final int serialNumber;
  final String reference;
  final String value;
  final String footprint;
  final int quantity;
  final String placement; // 'top', 'bottom', or 'both'
  
  BOMItem({
    required this.serialNumber,
    required this.reference,
    required this.value,
    required this.footprint,
    required this.quantity,
    required this.placement,
  });

  // Convert from Excel row data
  factory BOMItem.fromExcelRow(List<dynamic> row) {
    return BOMItem(
      serialNumber: _parseToInt(row[0]),
      reference: row[1]?.toString() ?? '',
      value: row[2]?.toString() ?? '',
      footprint: row[3]?.toString() ?? '',
      quantity: _parseToInt(row[4]),
      placement: row[5]?.toString().toLowerCase() ?? 'top',
    );
  }

  // Convert to Excel row for export
  List<dynamic> toExcelRow() {
    return [
      serialNumber,
      reference,
      value,
      footprint,
      quantity,
      placement,
    ];
  }

  // Convert to/from JSON for storage
  factory BOMItem.fromJson(Map<String, dynamic> json) {
    return BOMItem(
      serialNumber: json['serialNumber'] ?? 0,
      reference: json['reference'] ?? '',
      value: json['value'] ?? '',
      footprint: json['footprint'] ?? '',
      quantity: json['quantity'] ?? 0,
      placement: json['placement'] ?? 'top',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serialNumber': serialNumber,
      'reference': reference,
      'value': value,
      'footprint': footprint,
      'quantity': quantity,
      'placement': placement,
    };
  }

  // Helper method to parse dynamic values to int
  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  // Copy with method for easy updates
  BOMItem copyWith({
    int? serialNumber,
    String? reference,
    String? value,
    String? footprint,
    int? quantity,
    String? placement,
  }) {
    return BOMItem(
      serialNumber: serialNumber ?? this.serialNumber,
      reference: reference ?? this.reference,
      value: value ?? this.value,
      footprint: footprint ?? this.footprint,
      quantity: quantity ?? this.quantity,
      placement: placement ?? this.placement,
    );
  }

  @override
  String toString() {
    return 'BOMItem(sr: $serialNumber, ref: $reference, val: $value, qty: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BOMItem &&
        other.serialNumber == serialNumber &&
        other.reference == reference &&
        other.value == value &&
        other.footprint == footprint &&
        other.quantity == quantity &&
        other.placement == placement;
  }

  @override
  int get hashCode {
    return Object.hash(
      serialNumber,
      reference,
      value,
      footprint,
      quantity,
      placement,
    );
  }
}

class BOM {
  final String id;
  final String pcbName;
  final String deviceName;
  final List<BOMItem> items;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BOM({
    required this.id,
    required this.pcbName,
    required this.deviceName,
    required this.items,
    required this.createdAt,
    this.updatedAt,
  });

  // Create BOM from Excel data
  factory BOM.fromExcelData({
    required String pcbName,
    required String deviceName,
    required List<List<dynamic>> excelData,
  }) {
    // Skip header row (index 0) and process data rows
    final items = <BOMItem>[];
    
    for (int i = 1; i < excelData.length; i++) {
      final row = excelData[i];
      if (row.length >= 6 && row[1] != null && row[1].toString().isNotEmpty) {
        items.add(BOMItem.fromExcelRow(row));
      }
    }

    return BOM(
      id: _generateId(),
      pcbName: pcbName,
      deviceName: deviceName,
      items: items,
      createdAt: DateTime.now(),
    );
  }

  // Convert to/from JSON for storage
  factory BOM.fromJson(Map<String, dynamic> json) {
    return BOM(
      id: json['id'],
      pcbName: json['pcbName'],
      deviceName: json['deviceName'],
      items: (json['items'] as List)
          .map((item) => BOMItem.fromJson(item))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pcbName': pcbName,
      'deviceName': deviceName,
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Get total component count
  int get totalComponents => items.length;

  // Get total quantity needed
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  // Get unique components (by reference)
  int get uniqueComponents => items.map((e) => e.reference).toSet().length;

  // Get components by placement
  List<BOMItem> getComponentsByPlacement(String placement) {
    return items.where((item) => 
        item.placement.toLowerCase() == placement.toLowerCase() ||
        item.placement.toLowerCase() == 'both'
    ).toList();
  }

  // Get components for top side
  List<BOMItem> get topComponents => getComponentsByPlacement('top');

  // Get components for bottom side
  List<BOMItem> get bottomComponents => getComponentsByPlacement('bottom');

  // Search components by reference or value
  List<BOMItem> searchComponents(String query) {
    if (query.isEmpty) return items;
    
    final lowercaseQuery = query.toLowerCase();
    return items.where((item) =>
        item.reference.toLowerCase().contains(lowercaseQuery) ||
        item.value.toLowerCase().contains(lowercaseQuery) ||
        item.footprint.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  // Calculate material requirements for multiple PCBs
  Map<String, int> calculateMaterialRequirements(int pcbCount) {
    final requirements = <String, int>{};
    
    for (final item in items) {
      final totalNeeded = item.quantity * pcbCount;
      requirements[item.value] = (requirements[item.value] ?? 0) + totalNeeded;
    }
    
    return requirements;
  }

  // Export to Excel format
  List<List<dynamic>> toExcelData() {
    final excelData = <List<dynamic>>[];
    
    // Header row
    excelData.add([
      'Sr.No',
      'Reference',
      'Value',
      'Footprint',
      'Qty',
      'Top/Bottom'
    ]);
    
    // Data rows
    for (final item in items) {
      excelData.add(item.toExcelRow());
    }
    
    return excelData;
  }

  // Generate unique ID
  static String _generateId() {
    return 'bom_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Copy with method
  BOM copyWith({
    String? id,
    String? pcbName,
    String? deviceName,
    List<BOMItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BOM(
      id: id ?? this.id,
      pcbName: pcbName ?? this.pcbName,
      deviceName: deviceName ?? this.deviceName,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'BOM(id: $id, pcb: $pcbName, device: $deviceName, items: ${items.length})';
  }
}