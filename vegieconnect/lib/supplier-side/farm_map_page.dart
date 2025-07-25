// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vegieconnect/widgets/chat_widgets.dart';
import '../models/supplier_location.dart';
import '../services/supplier_location_service.dart';
import '../services/map_service.dart';
import 'package:vegieconnect/theme.dart'; // For AppColors
import '../models/farm_location.dart';
import '../services/farm_location_service.dart';

class SupplierLocationPage extends StatefulWidget {
  const SupplierLocationPage({super.key});

  @override
  State<SupplierLocationPage> createState() => _SupplierLocationPageState();
}

class _SupplierLocationPageState extends State<SupplierLocationPage> {
  final MapController _mapController = MapController();
  final SupplierLocationService _supplierLocationService = SupplierLocationService();
  final FarmLocationService _farmLocationService = FarmLocationService();
  final MapService _mapService = MapService();
  
  SupplierLocation? _supplierLocation;
  List<FarmLocation> _canvassedFarms = [];
  LatLng? _selectedLocation;
  bool _isLoading = true;
  bool _isAddingPin = false; // Track if user is in pin addition mode
  bool _isEditingPin = false; // Track if user is in pin editing mode
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; });
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final location = await _supplierLocationService.getSupplierLocationBySupplierId(user.uid);
      final farms = await _farmLocationService.getAllFarmLocations();
      setState(() {
        _supplierLocation = location;
        _canvassedFarms = farms;
        _isLoading = false;
      });
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
      
      // Use the new API
      await _supplierLocationService.createOrUpdateSupplierLocation(
        supplierId: user.uid,
        supplierName: supplierName,
        locationName: name,
        description: description,
        location: location,
      );
      
      // Reload supplier location
      await _loadData();

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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || _supplierLocation == null) return;
      
      await _supplierLocationService.updateSupplierLocation(
        supplierId: user.uid,
        newLocation: newLocation,
      );
      
      // Reload supplier location
      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplier location moved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error moving supplier location: $e')),
      );
    }
  }

  void _showRateSupplierDialog(BuildContext context, SupplierLocation supplier) {
    int rating = 5;
    TextEditingController commentController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rate ${supplier.supplierName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StarRating(
              rating: rating,
              onRatingChanged: (val) {
                rating = val;
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Comment (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (user == null) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You must be logged in to rate.')),
                );
                return;
              }
              // Fetch user role and block if not buyer or is supplier
              final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
              final userRole = userDoc.data()?['role'] ?? '';
              if (userRole != 'buyer' || user.uid == supplier.supplierId) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Only buyers can rate suppliers.')),
                );
                return;
              }
              // Save rating to Firestore
              final ratingsRef = FirebaseFirestore.instance.collection('supplier_ratings');
              await ratingsRef.add({
                'supplierId': supplier.supplierId,
                'buyerId': user.uid,
                'rating': rating,
                'comment': commentController.text.trim(),
                'timestamp': FieldValue.serverTimestamp(),
              });
              // Recalculate average and update supplier_locations
              final query = await ratingsRef.where('supplierId', isEqualTo: supplier.supplierId).get();
              double avg = 0;
              if (query.docs.isNotEmpty) {
                double sum = 0;
                for (var doc in query.docs) {
                  sum += (doc['rating'] ?? 0) is int ? (doc['rating'] ?? 0).toDouble() : (doc['rating'] ?? 0);
                }
                avg = sum / query.docs.length;
              }
              // Update supplier_locations
              final locQuery = await FirebaseFirestore.instance
                  .collection('supplier_locations')
                  .where('supplierId', isEqualTo: supplier.supplierId)
                  .limit(1)
                  .get();
              if (locQuery.docs.isNotEmpty) {
                await locQuery.docs.first.reference.update({'rating': avg});
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you for your review!')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showSupplierModal(SupplierLocation? supplier) async {
    if (supplier == null) return;
    final user = FirebaseAuth.instance.currentUser;
    String? userRole;
    bool isBuyer = false;
    bool isNotSupplier = false;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      userRole = userDoc.data()?['role'] ?? '';
      isBuyer = userRole == 'buyer';
      isNotSupplier = user.uid != supplier.supplierId;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                    child: const Icon(Icons.store, color: AppColors.primaryGreen, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(supplier.supplierName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.orange, size: 18),
                            const SizedBox(width: 4),
                            Text(supplier.rating != null ? supplier.rating!.toStringAsFixed(1) : 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (supplier.isNearest ?? false) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Nearest', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Icon(Icons.location_on, color: AppColors.primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(supplier.address, style: const TextStyle(fontSize: 15))),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.payments, color: AppColors.primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  const Text('Cash on Pick Up', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  Icon(Icons.qr_code, color: AppColors.primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  const Text('GCash', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    // Optionally show more details or navigate
                    Navigator.pop(context);
                  },
                  child: const Text('View Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              if (isBuyer && isNotSupplier)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      _showRateSupplierDialog(context, supplier);
                    },
                    child: const Text('Rate Supplier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Bogo City, Cebu, Philippines coordinates
    const LatLng bogoCityCenter = LatLng(11.0474, 124.0051);
// Approximately 5km radius
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Map'),
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
                // Supplier's own location
                if (_supplierLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          _selectedLocation?.latitude ?? _supplierLocation!.latitude,
                          _selectedLocation?.longitude ?? _supplierLocation!.longitude,
                        ),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => _showSupplierModal(_supplierLocation),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen,
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
                // Canvassed farms (admin-added)
                if (_canvassedFarms.isNotEmpty)
                  MarkerLayer(
                    markers: _canvassedFarms.map((farm) => Marker(
                      point: LatLng(farm.latitude, farm.longitude),
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.agriculture,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    )).toList(),
                  ),
                // Selected location (for editing supplier location)
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
                // Show a floating button to save the new location if dragging
                if (_isDragging && _selectedLocation != null)
                  Positioned(
                    bottom: 80,
                    right: 16,
                    child: FloatingActionButton.extended(
                      onPressed: () async {
                        await _updateSupplierLocation(_selectedLocation!);
                        setState(() {
                          _isDragging = false;
                          _selectedLocation = null;
                        });
                      },
                      backgroundColor: Colors.green,
                      icon: const Icon(Icons.save),
                      label: const Text('Save New Location'),
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