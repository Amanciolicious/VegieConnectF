// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vegieconnect/models/farm_location.dart';
import '../models/supplier_location.dart';
import '../services/supplier_location_service.dart';
import '../services/map_service.dart';
import 'location_selection_page.dart';

class FarmLocationsPage extends StatefulWidget {
  const FarmLocationsPage({super.key});

  @override
  State<FarmLocationsPage> createState() => _FarmLocationsPageState();
}

class _FarmLocationsPageState extends State<FarmLocationsPage> {
  final MapController _mapController = MapController();
  final SupplierLocationService _supplierLocationService = SupplierLocationService();
  final MapService _mapService = MapService();
  
  List<SupplierLocation> _allSupplierLocations = [];
  List<SupplierLocation> _nearbySuppliers = [];
  List<SupplierLocation> _veryNearbySuppliers = []; // Suppliers within 1km
  LatLng? _userLocation;
  String _userAddress = '';
  bool _isLoading = true;
  bool _showOnlyNearby = false;
  double _searchRadius = 10.0; // Default 10km radius
  final double _vicinityRadius = 1.0; // 1km radius for automatic guides
  bool _hasShownVicinityGuide = false; // Track if guide has been shown

  @override
  void initState() {
    super.initState();
  }

  bool _didShowLocationDialog = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didShowLocationDialog) {
      _didShowLocationDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLocationSelectionDialog();
      });
    }
  }

  void _showLocationSelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.location_on, color: Colors.green),
              SizedBox(width: 8),
              Text('Set Your Location'),
            ],
          ),
          content: Text(
            'Choose how you want to set your location to find nearby farms. '
            'You can use your current GPS location or enter an address manually.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showLocationSelectionPage();
              },
              child: Text('Choose Location'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _initializeLocation(); // Use default location
              },
              child: Text('Skip'),
            ),
          ],
        );
      },
    );
  }

  void _showLocationSelectionPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LocationSelectionPage(
          onLocationSelected: (location, address) {
            if (mounted) {
              setState(() {
                _userLocation = location;
                _userAddress = address;
                _filterNearbySuppliers();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Location set to: $address'),
                  backgroundColor: Colors.green,
                ),
              );
            }
            // Ensure we only pop once, after state is set
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
  }

  Future<void> _refreshGPSLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        final location = LatLng(position.latitude, position.longitude);
        final address = await _mapService.getAddressFromCoordinates(location);
        
        setState(() {
          _userLocation = location;
          _userAddress = address;
        });
        _filterNearbySuppliers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location refreshed: $address'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission required to refresh'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _initializeLocation() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Use default location if permission denied
          _userLocation = const LatLng(11.0474, 124.0051); // Bogo City, Cebu, Philippines
          _userAddress = await _mapService.getAddressFromCoordinates(_userLocation!);
        }
      }

      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        _userLocation = LatLng(position.latitude, position.longitude);
        _userAddress = await _mapService.getAddressFromCoordinates(_userLocation!);
      } else {
        _userLocation = const LatLng(11.0474, 124.0051); // Bogo City, Cebu, Philippines
        _userAddress = await _mapService.getAddressFromCoordinates(_userLocation!);
      }

      await _loadSupplierLocations();
    } catch (e) {
      _userLocation = const LatLng(11.0474, 124.0051); // Bogo City, Cebu, Philippines
      _userAddress = await _mapService.getAddressFromCoordinates(_userLocation!);
      await _loadSupplierLocations();
    }
  }

  Future<void> _loadSupplierLocations() async {
    try {
      final locations = await _supplierLocationService.getAllSupplierLocations();
      setState(() {
        _allSupplierLocations = locations;
        _filterNearbySuppliers();
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

  void _filterNearbySuppliers() {
    if (_userLocation == null) {
      _nearbySuppliers = _allSupplierLocations;
      _veryNearbySuppliers = [];
      return;
    }

    _nearbySuppliers = _allSupplierLocations.where((supplier) {
      double distance = _mapService.calculateDistance(
        _userLocation!,
        LatLng(supplier.latitude, supplier.longitude),
      );
      return distance <= _searchRadius;
    }).toList();

    // Filter very nearby suppliers (within vicinity radius)
    _veryNearbySuppliers = _allSupplierLocations.where((supplier) {
      double distance = _mapService.calculateDistance(
        _userLocation!,
        LatLng(supplier.latitude, supplier.longitude),
      );
      return distance <= _vicinityRadius;
    }).toList();

    // Check if we should show vicinity guide
    _checkAndShowVicinityGuide();
  }

  void _checkAndShowVicinityGuide() {
    if (_veryNearbySuppliers.isNotEmpty && !_hasShownVicinityGuide) {
      _hasShownVicinityGuide = true;
      _showVicinityGuide();
    }
  }

  void _showVicinityGuide() {
    if (_veryNearbySuppliers.isEmpty) return;

    // Sort suppliers by distance
    _veryNearbySuppliers.sort((a, b) {
      double distanceA = _mapService.calculateDistance(
        _userLocation!,
        LatLng(a.latitude, a.longitude),
      );
      double distanceB = _mapService.calculateDistance(
        _userLocation!,
        LatLng(b.latitude, b.longitude),
      );
      return distanceA.compareTo(distanceB);
    });

    final nearestSupplier = _veryNearbySuppliers.first;
    final distance = _mapService.calculateDistance(
      _userLocation!,
      LatLng(nearestSupplier.latitude, nearestSupplier.longitude),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.person_pin, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('Supplier Nearby!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are near ${nearestSupplier.locationName}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Supplier: ${nearestSupplier.supplierName}'),
              const SizedBox(height: 4),
              Text('Distance: ${distance.toStringAsFixed(2)} km'),
              const SizedBox(height: 4),
              Text('Address: ${nearestSupplier.address}'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📍 Guide & Tips:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('• Look for supplier location signs'),
                    const Text('• Contact the supplier before visiting'),
                    const Text('• Check supplier operating hours'),
                    const Text('• Bring cash for purchases'),
                    const Text('• Ask about available products'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
                          ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showDetailedDirections(nearestSupplier);
                },
                icon: const Icon(Icons.directions),
                label: const Text('Get Directions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        );
      },
    );
  }

  void _showSupplierDetails(SupplierLocation supplier) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(supplier.locationName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Supplier: ${supplier.supplierName}'),
              const SizedBox(height: 8),
              Text('Description: ${supplier.description}'),
              const SizedBox(height: 8),
              Text('Address: ${supplier.address}'),
              if (_userLocation != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Distance: ${_mapService.calculateDistance(_userLocation!, LatLng(supplier.latitude, supplier.longitude)).toStringAsFixed(1)} km',
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (_userLocation != null)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showDetailedDirections(supplier);
                },
                icon: const Icon(Icons.directions),
                label: const Text('Get Directions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        );
      },
    );
  }

  void _showDetailedDirections(SupplierLocation supplier) {
    final distance = _mapService.calculateDistance(
      _userLocation!,
      LatLng(supplier.latitude, supplier.longitude),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.directions, color: Colors.blue),
              const SizedBox(width: 8),
              Text('Directions to ${supplier.supplierName}'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Farm Information
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        supplier.supplierName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Supplier: ${supplier.supplierName}'),
                      Text('Address: ${supplier.address}'),
                      Text('Distance: ${distance.toStringAsFixed(2)} km'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Navigation Options
                const Text(
                  'Navigation Options:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Walking Directions
                if (distance <= 2.0) ...[
                  _buildNavigationOption(
                    icon: Icons.directions_walk,
                    title: 'Walking Directions',
                    subtitle: 'Best for short distances',
                    onTap: () => _getWalkingDirections(supplier as FarmLocation),
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Driving Directions
                _buildNavigationOption(
                  icon: Icons.directions_car,
                  title: 'Driving Directions',
                  subtitle: 'Best for longer distances',
                  onTap: () => _getDrivingDirections(supplier as FarmLocation),
                ),
                const SizedBox(height: 8),
                
                // Open in Maps
                _buildNavigationOption(
                  icon: Icons.map,
                  title: 'Open in Maps App',
                  subtitle: 'Use your preferred navigation app',
                  onTap: () => _openInMaps(supplier as FarmLocation),
                ),
                const SizedBox(height: 16),
                
                // Farm Visit Tips
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🌾 Farm Visit Tips:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('• Call ahead to confirm availability'),
                      const Text('• Check if the farm is open today'),
                      const Text('• Ask about parking availability'),
                      const Text('• Bring containers for fresh produce'),
                      const Text('• Consider weather conditions'),
                    ],
                  ),
                ),
              ],
            ),
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

  Widget _buildNavigationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  void _getWalkingDirections(FarmLocation farm) {
    Navigator.of(context).pop(); // Close the detailed directions dialog
    _showRouteDirections(farm, 'foot-walking');
  }

  void _getDrivingDirections(FarmLocation farm) {
    Navigator.of(context).pop(); // Close the detailed directions dialog
    _showRouteDirections(farm, 'driving-car');
  }

  void _showRouteDirections(FarmLocation farm, String profile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                profile == 'foot-walking' ? Icons.directions_walk : Icons.directions_car,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              Text('${profile == 'foot-walking' ? 'Walking' : 'Driving'} Directions'),
            ],
          ),
          content: FutureBuilder(
            future: _mapService.getRoute(
              start: _userLocation!,
              end: LatLng(farm.latitude, farm.longitude),
              profile: profile,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Text('Error getting directions: ${snapshot.error}');
              }

              final route = snapshot.data;
              if (route == null) {
                return const Text('No route found');
              }

              final features = route['features'] as List<dynamic>;
              final summary = features[0]['properties']['summary'];
              final distance = summary['distance'] / 1000; // Convert to km
              final duration = summary['duration'] / 60; // Convert to minutes

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Route Summary:',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('Distance: ${distance.toStringAsFixed(1)} km'),
                        Text('Duration: ${duration.toStringAsFixed(0)} minutes'),
                        Text('Mode: ${profile == 'foot-walking' ? 'Walking' : 'Driving'}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Step-by-step Directions:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: SingleChildScrollView(
                      child: _buildRouteInstructions(route),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openInMaps(farm);
              },
              child: const Text('Open in Maps'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRouteInstructions(Map<String, dynamic> route) {
    // This is a simplified version. In a real app, you'd parse the route
    // and show step-by-step instructions
    return const Text(
      'Follow the route on the map. For detailed turn-by-turn directions, '
      'use the "Open in Maps" button to open your preferred navigation app.',
    );
  }

  void _openInMaps(FarmLocation farm) {
    // Open the location in the device's default maps app
    // You can use url_launcher package to open this URL
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${farm.name} in maps...'),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () {
            // Implement url_launcher here
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displaySuppliers = _showOnlyNearby ? _nearbySuppliers : _allSupplierLocations;
    
    // Bogo City, Cebu, Philippines coordinates
    const LatLng bogoCityCenter = LatLng(11.0474, 124.0051);


    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Farm Locations - Bogo City'),
            if (_userLocation != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'GPS',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshGPSLocation,
            tooltip: 'Refresh GPS location',
          ),
          IconButton(
            icon: const Icon(Icons.edit_location),
            onPressed: _showLocationSelectionPage,
            tooltip: 'Change location',
          ),
          IconButton(
            icon: Icon(_showOnlyNearby ? Icons.location_on : Icons.location_off),
            onPressed: () {
              setState(() {
                _showOnlyNearby = !_showOnlyNearby;
              });
            },
            tooltip: _showOnlyNearby ? 'Show all farms' : 'Show nearby farms only',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter controls
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text('Search Radius: '),
                      Expanded(
                        child: Slider(
                          value: _searchRadius,
                          min: 1.0,
                          max: 50.0,
                          divisions: 49,
                          label: '${_searchRadius.toStringAsFixed(1)} km',
                          onChanged: (value) {
                            setState(() {
                              _searchRadius = value;
                              _filterNearbySuppliers();
                            });
                          },
                        ),
                      ),
                      Text('${_searchRadius.toStringAsFixed(1)} km'),
                    ],
                  ),
                ),
                // Farm count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _showOnlyNearby 
                                ? 'Nearby Farms (${_nearbySuppliers.length})'
                                : 'All Farms (${_allSupplierLocations.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_userLocation != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.my_location, color: Colors.green, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'Location Set',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (_userLocation != null) ...[
                        SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.grey, size: 14),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _userAddress.isNotEmpty 
                                      ? _userAddress
                                      : 'Your location: ${_userLocation!.latitude.toStringAsFixed(4)}, ${_userLocation!.longitude.toStringAsFixed(4)}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Map
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _userLocation ?? bogoCityCenter,
                          initialZoom: 12,
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
                          // User location marker
                          if (_userLocation != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _userLocation!,
                                  width: 40,
                                  height: 40,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.my_location,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          // Supplier location markers
                          MarkerLayer(
                            markers: displaySuppliers.map((supplier) {
                              double distance = _userLocation != null
                                  ? _mapService.calculateDistance(
                                      _userLocation!,
                                      LatLng(supplier.latitude, supplier.longitude),
                                    )
                                  : 0.0;

                              // Check if supplier is very nearby (within vicinity radius)
                              bool isVeryNearby = distance <= _vicinityRadius;
                              bool isNearby = distance <= _searchRadius;

                              return Marker(
                                point: LatLng(supplier.latitude, supplier.longitude),
                                width: isVeryNearby ? 50 : 40,
                                height: isVeryNearby ? 50 : 40,
                                child: GestureDetector(
                                  onTap: () => _showSupplierDetails(supplier),
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: isVeryNearby 
                                              ? Colors.orange 
                                              : (isNearby ? Colors.blue : Colors.grey),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white, 
                                            width: isVeryNearby ? 3 : 2,
                                          ),
                                          boxShadow: isVeryNearby ? [
                                            BoxShadow(
                                              color: Colors.orange.withOpacity(0.5),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ] : null,
                                        ),
                                        child: Icon(
                                          isVeryNearby ? Icons.person_pin : Icons.person_pin_circle,
                                          color: Colors.white,
                                          size: isVeryNearby ? 30 : 24,
                                        ),
                                      ),
                                      if (isVeryNearby)
                                        Positioned(
                                          top: -5,
                                          right: -5,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Text(
                                              '!',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
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
                      // Vicinity indicator
                      if (_veryNearbySuppliers.isNotEmpty)
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.person_pin,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_veryNearbySuppliers.length} Supplier${_veryNearbySuppliers.length > 1 ? 's' : ''} Nearby',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
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
      floatingActionButton: Tooltip(
        message: 'Center map on your location',
        child: FloatingActionButton(
          onPressed: () async {
            if (_userLocation != null) {
              _mapController.move(_userLocation!, 15);
            } else {
              _mapController.move(bogoCityCenter, 12);
            }
          },
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          child: const Icon(Icons.my_location),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
} 