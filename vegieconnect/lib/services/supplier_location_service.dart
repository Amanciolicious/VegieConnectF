import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/supplier_location.dart';
import 'dart:math';

class SupplierLocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'supplier_locations';

  // Add a new supplier location
  Future<void> addSupplierLocation(SupplierLocation supplierLocation) async {
    try {
      await _firestore.collection(_collection).doc(supplierLocation.id).set({
        ...supplierLocation.toMap(),
        'createdAt': Timestamp.fromDate(supplierLocation.createdAt),
      });
    } catch (e) {
      throw Exception('Failed to add supplier location: $e');
    }
  }

  // Get all supplier locations
  Future<List<SupplierLocation>> getAllSupplierLocations() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return SupplierLocation.fromMap(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get supplier locations: $e');
    }
  }

  // Get supplier location by supplier ID
  Future<SupplierLocation?> getSupplierLocationBySupplierId(String supplierId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('supplierId', isEqualTo: supplierId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      Map<String, dynamic> data = snapshot.docs.first.data() as Map<String, dynamic>;
      data['id'] = snapshot.docs.first.id;
      return SupplierLocation.fromMap(data);
    } catch (e) {
      throw Exception('Failed to get supplier location: $e');
    }
  }

  // Update supplier location
  Future<void> updateSupplierLocation(SupplierLocation supplierLocation) async {
    try {
      await _firestore.collection(_collection).doc(supplierLocation.id).update({
        ...supplierLocation.toMap(),
        'createdAt': Timestamp.fromDate(supplierLocation.createdAt),
      });
    } catch (e) {
      throw Exception('Failed to update supplier location: $e');
    }
  }

  // Delete supplier location
  Future<void> deleteSupplierLocation(String locationId) async {
    try {
      await _firestore.collection(_collection).doc(locationId).delete();
    } catch (e) {
      throw Exception('Failed to delete supplier location: $e');
    }
  }

  // Soft delete supplier location (set isActive to false)
  Future<void> deactivateSupplierLocation(String locationId) async {
    try {
      await _firestore.collection(_collection).doc(locationId).update({
        'isActive': false,
      });
    } catch (e) {
      throw Exception('Failed to deactivate supplier location: $e');
    }
  }

  // Get supplier locations within a certain radius
  Future<List<SupplierLocation>> getSupplierLocationsInRadius({
    required double centerLat,
    required double centerLng,
    required double radiusKm,
  }) async {
    try {
      // Note: This is a simplified approach. For production, consider using
      // Firestore's GeoPoint and geohashing for more efficient geospatial queries
      List<SupplierLocation> allLocations = await getAllSupplierLocations();
      
      return allLocations.where((location) {
        double distance = _calculateDistance(
          centerLat, centerLng,
          location.latitude, location.longitude,
        );
        return distance <= radiusKm;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get supplier locations in radius: $e');
    }
  }

  // Helper method to calculate distance between two points
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    double lat1Rad = lat1 * (pi / 180);
    double lat2Rad = lat2 * (pi / 180);
    double deltaLat = (lat2 - lat1) * (pi / 180);
    double deltaLon = (lon2 - lon1) * (pi / 180);

    double a = pow(sin(deltaLat / 2), 2) +
        cos(lat1Rad) * cos(lat2Rad) * pow(sin(deltaLon / 2), 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }
} 