// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vegieconnect/models/farm_location.dart';
import 'package:vegieconnect/theme.dart';
import '../models/supplier_location.dart';
import '../services/supplier_location_service.dart';
import '../services/map_service.dart';
import 'location_selection_page.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

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
  final bool _showOnlyNearby = false;
  final double _searchRadius = 10.0; // Default 10km radius
  final double _vicinityRadius = 1.0; // 1km radius for automatic guides
  bool _hasShownVicinityGuide = false; // Track if guide has been shown
  
  List<LatLng>? _routeLine; // Store the current route line

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
      // Use the enhanced map service for automatic location detection
      final locationData = await _mapService.getCurrentLocationWithAddress();
      final location = locationData['location'] as LatLng;
      final address = locationData['address'] as String;
      
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
      // Use the enhanced map service for automatic location detection
      final locationData = await _mapService.getCurrentLocationWithAddress();
      _userLocation = locationData['location'] as LatLng;
      _userAddress = locationData['address'] as String;

      await _loadSupplierLocations();
    } catch (e) {
      // Fallback to default location if automatic detection fails
      _userLocation = const LatLng(11.0474, 124.0051); // Bogo City, Cebu, Philippines
      _userAddress = await _mapService.getAddressFromCoordinates(_userLocation!);
      await _loadSupplierLocations();
    }
  }

  Future<void> _loadSupplierLocations() async {
    try {
      final locations = await _supplierLocationService.getAllSupplierLocations();
      // Filter out admin-added farms (assuming they have a distinguishing property, e.g., isAdminFarm or a different collection)
      final supplierOnlyLocations = locations.where((loc) => loc is! FarmLocation).toList();
      setState(() {
        _allSupplierLocations = supplierOnlyLocations;
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const Text(
                'Navigation Options:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildNavigationOption(
                icon: Icons.directions_walk,
                title: 'Walking Directions',
                subtitle: 'Best for short distances',
                onTap: () => _showRouteDirectionsSupplier(supplier, 'foot-walking'),
              ),
              const SizedBox(height: 8),
              _buildNavigationOption(
                icon: Icons.directions_car,
                title: 'Driving Directions',
                subtitle: 'Best for longer distances',
                onTap: () => _showRouteDirectionsSupplier(supplier, 'driving-car'),
              ),
              const SizedBox(height: 8),
              _buildNavigationOption(
                icon: Icons.map,
                title: 'Open in Maps App',
                subtitle: 'Use your preferred navigation app',
                onTap: () => _openInMapsSupplier(supplier),
              ),
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

  void _showRouteDirectionsSupplier(SupplierLocation supplier, String profile) {
    Navigator.of(context).pop();
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
              end: LatLng(supplier.latitude, supplier.longitude),
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
              final geometry = features[0]['geometry'];
              final summary = features[0]['properties']['summary'];
              final distance = summary['distance'] / 1000; // km
              final duration = summary['duration'] / 60; // min
              // Parse geometry coordinates to LatLng list
              final coords = geometry['coordinates'] as List<dynamic>;
              final List<LatLng> polyline = coords.map((c) => LatLng(c[1], c[0])).toList();
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
                        const Text('Route Summary:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Distance: ${distance.toStringAsFixed(1)} km'),
                        Text('Duration: ${duration.toStringAsFixed(0)} minutes'),
                        Text('Mode: ${profile == 'foot-walking' ? 'Walking' : 'Driving'}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Step-by-step Directions:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: SingleChildScrollView(
                      child: _buildRouteInstructions(route),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text('Show Route on Map'),
                    onPressed: () {
                      setState(() {
                        _routeLine = polyline;
                      });
                      Navigator.of(context).pop();
                      // Fit map to route
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _fitMapToRoute();
                      });
                    },
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
                _openInMapsSupplier(supplier);
              },
              child: const Text('Open in Maps'),
            ),
          ],
        );
      },
    );
  }

  void _openInMapsSupplier(SupplierLocation supplier) {
    // Implement url_launcher logic for supplier
  }

  void _fitMapToRoute() {
    if (_routeLine == null || _routeLine!.isEmpty) return;
    // LatLngBounds requires two points to initialize
    final points = _routeLine!;
    LatLngBounds bounds = LatLngBounds(points.first, points.first);
    for (final point in points) {
    bounds.extend(point);
    }
    // Animate the map to fit the bounds
    _mapController.fitBounds(
      bounds,
      options: const FitBoundsOptions(padding: EdgeInsets.all(60)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: Text('Supplier Locations', style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: screenWidth * 0.055)),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header Section
          Neumorphic(
            style: AppNeumorphic.card,
            margin: EdgeInsets.all(screenWidth * 0.04),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.06),
              child: Column(
                children: [
                  Icon(
                    Icons.location_on,
                    size: screenWidth * 0.12,
                    color: AppColors.primaryGreen,
                  ),
                  SizedBox(height: screenWidth * 0.03),
                  Text(
                    'Discover Local Suppliers',
                    style: AppTextStyles.headline.copyWith(
                      fontSize: screenWidth * 0.06,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.02),
                  Text(
                    'Find fresh produce from suppliers near you',
                    style: AppTextStyles.body.copyWith(
                      fontSize: screenWidth * 0.04,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          // Map Section
          Expanded(
            child: Neumorphic(
              style: AppNeumorphic.card,
              margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(screenWidth * 0.05),
                child: _buildMapSection(screenWidth),
              ),
            ),
          ),
          // Farm List Section
          SizedBox(
            height: screenHeight * 0.25,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Row(
                    children: [
                      Text(
                        'Nearby Suppliers',
                        style: AppTextStyles.headline.copyWith(fontSize: screenWidth * 0.055),
                      ),
                      const Spacer(),
                      NeumorphicButton(
                        style: AppNeumorphic.button.copyWith(
                          color: AppColors.primaryGreen,
                        ),
                        onPressed: _refreshGPSLocation,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenWidth * 0.02),
                          child: Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: screenWidth * 0.05,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildFarmList(screenWidth),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(double screenWidth) {
    if (_isLoading) {
      return Container(
        color: AppColors.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
              ),
              SizedBox(height: screenWidth * 0.03),
              Text(
                'Loading map...',
                style: AppTextStyles.body.copyWith(
                  fontSize: screenWidth * 0.04,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_allSupplierLocations.isEmpty) {
      return Container(
        color: AppColors.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map,
                size: screenWidth * 0.15,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: screenWidth * 0.03),
              Text(
                'No suppliers found nearby',
                style: AppTextStyles.headline.copyWith(
                  fontSize: screenWidth * 0.05,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: screenWidth * 0.02),
              Text(
                'Try expanding your search area',
                style: AppTextStyles.body.copyWith(
                  fontSize: screenWidth * 0.04,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _userLocation ?? const LatLng(11.0474, 124.0051), // Default to Bogo City
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
              point: const LatLng(11.0474, 124.0051), // Bogo City center
              radius: 5000, // 5km radius in meters
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderColor: AppColors.primaryGreen.withOpacity(0.5),
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
                    color: AppColors.primaryGreen,
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
          markers: _allSupplierLocations.map((supplier) {
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
                            ? AppColors.accentRed 
                            : (isNearby ? AppColors.accentGreen : AppColors.textSecondary.withOpacity(0.2)),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white, 
                          width: isVeryNearby ? 3 : 2,
                        ),
                        boxShadow: isVeryNearby ? [
                          BoxShadow(
                            color: AppColors.accentRed.withOpacity(0.5),
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
                          decoration:  BoxDecoration(
                            color: AppColors.primaryRed,
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
        // Route polyline layer
        if (_routeLine != null && _routeLine!.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routeLine!,
                color: Colors.blue,
                strokeWidth: 5.0,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildFarmList(double screenWidth) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
        ),
      );
    }

    if (_allSupplierLocations.isEmpty) {
      return Center(
        child: Neumorphic(
          style: AppNeumorphic.card,
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.08),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.agriculture,
                  size: screenWidth * 0.15,
                  color: AppColors.primaryGreen,
                ),
                SizedBox(height: screenWidth * 0.04),
                Text(
                  'No Suppliers Found',
                  style: AppTextStyles.headline.copyWith(
                    fontSize: screenWidth * 0.06,
                    color: AppColors.primaryGreen,
                  ),
                ),
                SizedBox(height: screenWidth * 0.02),
                Text(
                  'No suppliers are currently registered in your area',
                  style: AppTextStyles.body.copyWith(
                    fontSize: screenWidth * 0.04,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      itemCount: _allSupplierLocations.length,
      itemBuilder: (context, index) {
        final farm = _allSupplierLocations[index];
        return _buildFarmCard(screenWidth, farm);
      },
    );
  }

  Widget _buildFarmCard(double screenWidth, SupplierLocation farm) {
    return Neumorphic(
      style: AppNeumorphic.card,
      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
      child: InkWell(
        onTap: () => _showSupplierDetails(farm),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Row(
            children: [
              // Farm Icon
              Container(
                width: screenWidth * 0.15,
                height: screenWidth * 0.15,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(screenWidth * 0.075),
                ),
                child: Icon(
                  Icons.agriculture,
                  color: AppColors.primaryGreen,
                  size: screenWidth * 0.08,
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
              // Farm Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farm.locationName,
                      style: AppTextStyles.headline.copyWith(
                        fontSize: screenWidth * 0.045,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.01),
                    Text(
                      farm.address,
                      style: AppTextStyles.body.copyWith(
                        fontSize: screenWidth * 0.035,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.01),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: screenWidth * 0.04,
                          color: Colors.orange,
                        ),
                        SizedBox(width: screenWidth * 0.01),
                        Text(
                          farm.rating.toString(),
                          style: AppTextStyles.body.copyWith(
                            fontSize: screenWidth * 0.035,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Icon(
                          Icons.location_on,
                          size: screenWidth * 0.04,
                          color: AppColors.primaryGreen,
                        ),
                        SizedBox(width: screenWidth * 0.01),
                        Text(
                          '${_mapService.calculateDistance(_userLocation!, LatLng(farm.latitude, farm.longitude)).toStringAsFixed(1)} km',
                          style: AppTextStyles.body.copyWith(
                            fontSize: screenWidth * 0.035,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // View Button
              NeumorphicButton(
                style: AppNeumorphic.button.copyWith(
                  color: AppColors.primaryGreen,
                ),
                onPressed: () => _showSupplierDetails(farm),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenWidth * 0.02),
                  child: Text(
                    'View',
                    style: AppTextStyles.button.copyWith(
                      color: Colors.white,
                      fontSize: screenWidth * 0.035,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 