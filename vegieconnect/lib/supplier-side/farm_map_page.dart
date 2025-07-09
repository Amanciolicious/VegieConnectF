import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/farm_location.dart';
import '../services/farm_location_service.dart';
import '../services/map_service.dart';

class FarmMapPage extends StatefulWidget {
  const FarmMapPage({super.key});

  @override
  State<FarmMapPage> createState() => _FarmMapPageState();
}

class _FarmMapPageState extends State<FarmMapPage> {
  final MapController _mapController = MapController();
  final FarmLocationService _farmLocationService = FarmLocationService();
  final MapService _mapService = MapService();
  
  List<FarmLocation> _farmLocations = [];
  LatLng? _selectedLocation;
  bool _isLoading = true;
  bool _isAddingPin = false; // Track if user is in pin addition mode

  @override
  void initState() {
    super.initState();
    _loadFarmLocations();
  }

  Future<void> _loadFarmLocations() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final locations = await _farmLocationService.getFarmLocationsBySupplier(user.uid);
        setState(() {
          _farmLocations = locations;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading farm locations: $e')),
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
          content: Text('Farm locations can only be added within Bogo City boundaries'),
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
      _showAddFarmDialog(point);
    } else {
      // Show a hint to enable pin addition mode
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tap the "Add Pin" button to add a new farm location'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _enablePinAdditionMode() {
    setState(() {
      _isAddingPin = true;
      _selectedLocation = null; // Clear any existing selection
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tap anywhere on the map to add a farm pin'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _cancelPinAdditionMode() {
    setState(() {
      _isAddingPin = false;
      _selectedLocation = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pin addition mode cancelled'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAddFarmDialog(LatLng location) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.add_location, color: Colors.green),
              const SizedBox(width: 8),
              const Text('Add Farm Location'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Farm Name',
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
                  await _addFarmLocation(
                    nameController.text,
                    descriptionController.text,
                    location,
                  );
                }
              },
              child: const Text('Add Farm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addFarmLocation(String name, String description, LatLng location) async {
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

      final farmLocation = FarmLocation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        description: description,
        latitude: location.latitude,
        longitude: location.longitude,
        supplierId: user.uid,
        supplierName: supplierName,
        address: address,
        createdAt: DateTime.now(),
      );

      await _farmLocationService.addFarmLocation(farmLocation);
      
      // Reload farm locations
      await _loadFarmLocations();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Farm location added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding farm location: $e')),
      );
    }
  }

  void _showFarmDetails(FarmLocation farm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(farm.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Description: ${farm.description}'),
              const SizedBox(height: 8),
              Text('Address: ${farm.address}'),
              const SizedBox(height: 8),
              Text('Coordinates: ${farm.latitude.toStringAsFixed(6)}, ${farm.longitude.toStringAsFixed(6)}'),
              const SizedBox(height: 8),
              Text('Added: ${farm.createdAt.toString().split('.')[0]}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteFarmLocation(farm.id);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteFarmLocation(String farmId) async {
    try {
      await _farmLocationService.deleteFarmLocation(farmId);
      await _loadFarmLocations();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Farm location deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting farm location: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Bogo City, Cebu, Philippines coordinates
    const LatLng bogoCityCenter = LatLng(11.0474, 124.0051);
    const double bogoCityRadius = 0.05; // Approximately 5km radius
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Locations - Bogo City'),
        backgroundColor: Colors.green,
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
                // Show existing farm locations
                MarkerLayer(
                  markers: _farmLocations.map((farm) {
                    return Marker(
                      point: LatLng(farm.latitude, farm.longitude),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _showFarmDetails(farm),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
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
                // Farm count indicator
                Positioned(
                  top: 60,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.9),
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
                      '🌾 ${_farmLocations.length} Farms',
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
                        color: Colors.orange.withOpacity(0.9),
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
                        '📍 Adding Pin Mode',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isAddingPin ? _cancelPinAdditionMode : _enablePinAdditionMode,
        backgroundColor: _isAddingPin ? Colors.red : Colors.green,
        foregroundColor: Colors.white,
        icon: Icon(_isAddingPin ? Icons.close : Icons.add_location),
        label: Text(_isAddingPin ? 'Cancel' : 'Add Pin'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
} 