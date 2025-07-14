// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/supplier_location.dart';
import '../services/supplier_location_service.dart';
import '../services/map_service.dart';

class SupplierLocationPage extends StatefulWidget {
  const SupplierLocationPage({super.key});

  @override
  State<SupplierLocationPage> createState() => _SupplierLocationPageState();
}

class _SupplierLocationPageState extends State<SupplierLocationPage> {
  final MapController _mapController = MapController();
  final SupplierLocationService _supplierLocationService = SupplierLocationService();
  final MapService _mapService = MapService();
  
  SupplierLocation? _supplierLocation;
  LatLng? _selectedLocation;
  bool _isLoading = true;
  bool _isAddingPin = false; // Track if user is in pin addition mode
  bool _isEditingPin = false; // Track if user is in pin editing mode

  @override
  void initState() {
    super.initState();
    _loadSupplierLocation();
  }

  Future<void> _loadSupplierLocation() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final location = await _supplierLocationService.getSupplierLocationBySupplierId(user.uid);
        setState(() {
          _supplierLocation = location;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading supplier location: $e')),
      );
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    // Check if the tapped location is within Bogo City boundary
    const LatLng bogoCityCenter = LatLng(11.0474, 124.0051);
    
    double distance = _mapService.calculateDistance(bogoCityCenter, point);
    
    if (distance > 5.0) { // 5km radius
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Supplier locations can only be added within Bogo City boundaries'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // If in pin addition mode, add the pin immediately
    if (_isAddingPin) {
      setState(() {
        _selectedLocation = point;
        _isAddingPin = false; // Exit pin addition mode
      });
      _showAddLocationDialog(point);
    } else if (_isEditingPin) {
      // If in editing mode, update the existing pin location
      setState(() {
        _selectedLocation = point;
        _isEditingPin = false; // Exit editing mode
      });
      _showEditLocationDialog(point);
    } else {
      // Show a hint to enable pin addition mode
      if (_supplierLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tap the "Add Location" button to add your supplier location'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tap the "Edit Location" button to move your supplier location'),
          duration: Duration(seconds: 2),
        ),
      );
      }
    }
  }

  void _enablePinAdditionMode() {
    // Check if supplier already has a location
    if (_supplierLocation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You already have a supplier location. Use "Edit Location" to modify it.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    setState(() {
      _isAddingPin = true;
      _isEditingPin = false;
      _selectedLocation = null; // Clear any existing selection
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tap anywhere on the map to add your supplier location'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _enablePinEditingMode() {
    if (_supplierLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to add a supplier location first.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    setState(() {
      _isEditingPin = true;
      _isAddingPin = false;
      _selectedLocation = null; // Clear any existing selection
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tap anywhere on the map to move your supplier location'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _cancelPinAdditionMode() {
    setState(() {
      _isAddingPin = false;
      _isEditingPin = false;
      _selectedLocation = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pin mode cancelled'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAddLocationDialog(LatLng location) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.add_location, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('Add Supplier Location'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Location Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              FutureBuilder<String>(
                future: _mapService.getAddressFromCoordinates(location),
                builder: (context, snapshot) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (snapshot.hasData && snapshot.data!.isNotEmpty)
                        Text(
                          'Address: ${snapshot.data}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  await _addSupplierLocation(
                    nameController.text,
                    descriptionController.text,
                    location,
                  );
                }
              },
              child: const Text('Add Location'),
            ),
          ],
        );
      },
    );
  }

  void _showEditLocationDialog(LatLng newLocation) {
    if (_supplierLocation == null) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.edit_location, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('Move Supplier Location'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Location: ${_supplierLocation!.locationName}'),
              const SizedBox(height: 16),
              FutureBuilder<String>(
                future: _mapService.getAddressFromCoordinates(newLocation),
                builder: (context, snapshot) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Location: ${newLocation.latitude.toStringAsFixed(6)}, ${newLocation.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (snapshot.hasData && snapshot.data!.isNotEmpty)
                        Text(
                          'New Address: ${snapshot.data}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _updateSupplierLocation(newLocation);
              },
              child: const Text('Move Location'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addSupplierLocation(String name, String description, LatLng location) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get user data for supplier name
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      final supplierName = userDoc.data()?['name'] ?? 'Unknown Supplier';
      
      // Get address from coordinates
      final address = await _mapService.getAddressFromCoordinates(location);

      final supplierLocation = SupplierLocation(
        id: user.uid, // FIX: Use UID as document ID
        supplierId: user.uid,
        supplierName: supplierName,
        locationName: name,
        description: description,
        latitude: location.latitude,
        longitude: location.longitude,
        address: address,
        createdAt: DateTime.now(),
      );

      await _supplierLocationService.addSupplierLocation(supplierLocation);
      
      // Reload supplier location
      await _loadSupplierLocation();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplier location added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding supplier location: $e')),
      );
    }
  }

  Future<void> _updateSupplierLocation(LatLng newLocation) async {
    try {
      if (_supplierLocation == null) return;
      
      // Get new address from coordinates
      final newAddress = await _mapService.getAddressFromCoordinates(newLocation);

      // Create updated supplier location
      final updatedLocation = _supplierLocation!.copyWith(
        latitude: newLocation.latitude,
        longitude: newLocation.longitude,
        address: newAddress,
      );

      await _supplierLocationService.updateSupplierLocation(updatedLocation);
      
      // Reload supplier location
      await _loadSupplierLocation();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplier location moved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error moving supplier location: $e')),
      );
    }
  }

  void _showLocationDetails() {
    if (_supplierLocation == null) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_supplierLocation!.locationName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Description: ${_supplierLocation!.description}'),
              const SizedBox(height: 8),
              Text('Address: ${_supplierLocation!.address}'),
              const SizedBox(height: 8),
              Text('Coordinates: ${_supplierLocation!.latitude.toStringAsFixed(6)}, ${_supplierLocation!.longitude.toStringAsFixed(6)}'),
              const SizedBox(height: 8),
              Text('Added: ${_supplierLocation!.createdAt.toString().split('.')[0]}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showEditLocationDialog(_supplierLocation! as LatLng);
              },
              child: const Text('Edit', style: TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteSupplierLocation();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }



  Future<void> _deleteSupplierLocation() async {
    try {
      if (_supplierLocation == null) return;
      
      await _supplierLocationService.deleteSupplierLocation(_supplierLocation!.id);
      await _loadSupplierLocation();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplier location deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting supplier location: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Bogo City, Cebu, Philippines coordinates
    const LatLng bogoCityCenter = LatLng(11.0474, 124.0051);
// Approximately 5km radius
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Location - Bogo City'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: bogoCityCenter,
                initialZoom: 12,
                onTap: _onMapTap,
                maxZoom: 16,
                minZoom: 10,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.vegieconnect',
                ),
                // Bogo City boundary circle (barrier interface)
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
                // Show existing supplier location
                if (_supplierLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(_supplierLocation!.latitude, _supplierLocation!.longitude),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => _showLocationDetails(),
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
                      ),
                    ],
                  ),
                // Show selected location
                if (_selectedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedLocation!,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.add_location,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
                // Bogo City boundary indicator
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
                    child: const Text(
                      '📍 Bogo City Boundary',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                // Location status indicator
                Positioned(
                  top: 60,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _supplierLocation != null ? Colors.blue.withOpacity(0.9) : Colors.orange.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      _supplierLocation != null 
                          ? '📍 Supplier Location Set'
                          : '📍 No Supplier Location',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                // Pin addition mode indicator
                if (_isAddingPin)
                  Positioned(
                    top: 16,
                    right: 16,
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
                      child: const Text(
                        '📍 Adding Location Mode',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                // Pin editing mode indicator
                if (_isEditingPin)
                  Positioned(
                    top: 16,
                    right: 16,
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
                      child: const Text(
                        '📍 Moving Location Mode',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                // Center map button
                Positioned(
                  bottom: 100,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: () {
                      _mapController.move(bogoCityCenter, 12);
                    },
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    mini: true,
                    child: const Icon(Icons.center_focus_strong),
                  ),
                ),
              ],
            ),
      floatingActionButton: _supplierLocation == null
          ? FloatingActionButton.extended(
        onPressed: _isAddingPin ? _cancelPinAdditionMode : _enablePinAdditionMode,
        backgroundColor: _isAddingPin ? Colors.red : Colors.blue,
        foregroundColor: Colors.white,
        icon: Icon(_isAddingPin ? Icons.close : Icons.add_location),
              label: Text(_isAddingPin ? 'Cancel' : 'Add Location'),
            )
          : FloatingActionButton.extended(
              onPressed: _isEditingPin ? _cancelPinAdditionMode : _enablePinEditingMode,
              backgroundColor: _isEditingPin ? Colors.red : Colors.blue,
              foregroundColor: Colors.white,
              icon: Icon(_isEditingPin ? Icons.close : Icons.edit_location),
              label: Text(_isEditingPin ? 'Cancel' : 'Move Location'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
} 