// Simple Equipment model to map backend equipment documents to frontend
class Equipment {
  String? id;
  String? formattedId;
  String? buildingId;
  String? equipmentName;
  String? assetTag;
  String? manufacturer;
  String? equipmentType;
  String? category;
  String? modelNumber;
  String? serialNumber;
  String? location;
  String? department;
  String? status;
  bool? isCritical;
  bool? isActive;
  String? createdBy;
  DateTime? createdAt;
  DateTime? updatedAt;

  Equipment({
    this.id,
    this.formattedId,
    this.buildingId,
    this.equipmentName,
    this.assetTag,
    this.manufacturer,
    this.equipmentType,
    this.category,
    this.modelNumber,
    this.serialNumber,
    this.location,
    this.department,
    this.status,
    this.isCritical,
    this.isActive,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'] ?? json['_doc_id'] ?? json['equipmentId'],
      formattedId: json['formatted_id'] ?? json['formattedId'] ?? json['equipmentId'],
      buildingId: json['building_id'] ?? json['buildingId'] ?? json['building'],
      equipmentName: json['equipment_name'] ?? json['name'] ?? json['equipmentName'],
      assetTag: json['asset_tag'] ?? json['assetTag'],
      manufacturer: json['manufacturer'],
      equipmentType: json['equipment_type'] ?? json['equipmentType'],
      category: json['category'],
      modelNumber: json['model_number'] ?? json['modelNumber'],
      serialNumber: json['serial_number'] ?? json['serialNumber'],
      location: json['location'] ?? json['area'],
      department: json['department'],
      status: json['status'],
      isCritical: json['is_critical'] ?? json['isCritical'] ?? false,
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      createdBy: json['created_by'] ?? json['createdBy'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (formattedId != null) 'formatted_id': formattedId,
      if (buildingId != null) 'building_id': buildingId,
      if (equipmentName != null) 'equipment_name': equipmentName,
      if (assetTag != null) 'asset_tag': assetTag,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (equipmentType != null) 'equipment_type': equipmentType,
      if (category != null) 'category': category,
      if (modelNumber != null) 'model_number': modelNumber,
      if (serialNumber != null) 'serial_number': serialNumber,
      if (location != null) 'location': location,
      if (department != null) 'department': department,
      if (status != null) 'status': status,
      if (isCritical != null) 'is_critical': isCritical,
      if (isActive != null) 'is_active': isActive,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
