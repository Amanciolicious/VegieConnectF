// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/supplier_location.dart';
import '../services/supplier_location_service.dart';

class AdminSupplierLocationPage extends StatefulWidget {
  const AdminSupplierLocationPage({super.key});

  @override
  State<AdminSupplierLocationPage> createState() => _AdminSupplierLocationPageState();
}

class _AdminSupplierLocationPageState extends State<AdminSupplierLocationPage> {
  final MapController _mapController = MapController();
  final SupplierLocationService _supplierLocationService = SupplierLocationService();
  
  List<SupplierLocation> _supplierLocations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSupplierLocations();
  }

  Future<void> _loadSupplierLocations() async {
    try {
      final locations = await _supplierLocationService.getAllSupplierLocations();
      setState(() {
        _supplierLocations = locations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading supplier locations: $e')),
      );
    }
  }

  void _showSupplierLocationDetails(SupplierLocation location) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(location.locationName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Supplier: ${location.supplierName}'),
              const SizedBox(height: 8),
              Text('Description: ${location.description}'),
              const SizedBox(height: 8),
              Text('Address: ${location.address}'),
              const SizedBox(height: 8),
              Text('Coordinates: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}'),
              const SizedBox(height: 8),
              Text('Added: ${location.createdAt.toString().split('.')[0]}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Bogo City, Cebu, Philippines coordinates
    const LatLng bogoCityCenter = LatLng(11.0474, 124.0051);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Locations - Bogo City'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadSupplierLocations();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_pin, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Supplier Locations Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total Supplier Locations: ${_supplierLocations.length}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (_supplierLocations.isNotEmpty)
                        Text(
                          'Active Suppliers: ${_supplierLocations.map((loc) => loc.supplierName).toSet().length}',
                          style: const TextStyle(fontSize: 16),
                        ),
                    ],
                  ),
                ),
                // Map
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: bogoCityCenter,
                          initialZoom: 12,
                          maxZoom: 16,
                          minZoom: 10,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.vegieconnect',
                          ),
                          // Bogo City boundary circle
                          CircleLayer(
                            circles: [
                              CircleMarker(
                                point: bogoCityCenter,
                                radius: 5000, // 5km radius in meters
                                color: Colors.blue.withOpacity(0.1),
                                borderColor: Colors.blue.withOpacity(0.5),
                                borderStrokeWidth: 3,
                              ),
                            ],
                          ),
                          // Show supplier locations
                          MarkerLayer(
                            markers: _supplierLocations.map((location) {
                              return Marker(
                                point: LatLng(location.latitude, location.longitude),
                                width: 40,
                                height: 40,
                                child: GestureDetector(
                                  onTap: () => _showSupplierLocationDetails(location),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.person_pin,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      // Boundary indicator
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Bogo City Boundary',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
} 