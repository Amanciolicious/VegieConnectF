import 'package:cloud_firestore/cloud_firestore.dart';

class SupplierLocation {
  final String id;
  final String supplierId;
  final String supplierName;
  final String locationName;
  final String description;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime createdAt;
  final bool isActive;

  SupplierLocation({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.locationName,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'locationName': locationName,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }

  factory SupplierLocation.fromMap(Map<String, dynamic> map) {
    return SupplierLocation(
      id: map['id'] ?? '',
      supplierId: map['supplierId'] ?? '',
      supplierName: map['supplierName'] ?? '',
      locationName: map['locationName'] ?? '',
      description: map['description'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      address: map['address'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  SupplierLocation copyWith({
    String? id,
    String? supplierId,
    String? supplierName,
    String? locationName,
    String? description,
    double? latitude,
    double? longitude,
    String? address,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return SupplierLocation(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      locationName: locationName ?? this.locationName,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
} 