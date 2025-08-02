// ignore_for_file: deprecated_member_use

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../services/map_service.dart';
import 'package:vegieconnect/theme.dart'; // For AppColors
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

class LocationSelectionPage extends StatefulWidget {
  final Function(LatLng location, String address) onLocationSelected;
  
  const LocationSelectionPage({
    super.key,
    required this.onLocationSelected,
  });

  @override
  State<LocationSelectionPage> createState() => _LocationSelectionPageState();
}

class _LocationSelectionPageState extends State<LocationSelectionPage> {
  final TextEditingController _addressController = TextEditingController();
  final MapService _mapService = MapService();
  
  bool _isLoading = false;
  bool _useCurrentLocation = false;
  bool _useManualLocation = false;
  LatLng? _currentLocation;
  String _currentAddress = '';
  String _manualAddress = '';
  LatLng? _manualLocation;
  String? _selectedLocationId;
  List<Map<String, dynamic>> _filteredLocations = [];

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _initializeLocations();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _initializeLocations() {
    _filteredLocations = [
      {
        'id': 'bogo_city',
        'name': 'Bogo City',
        'description': 'Cebu, Philippines',
        'coordinates': LatLng(11.0474, 124.0051),
      },
      {
        'id': 'cebu_city',
        'name': 'Cebu City',
        'description': 'Cebu, Philippines',
        'coordinates': LatLng(10.3157, 123.8854),
      },
      {
        'id': 'mandaue_city',
        'name': 'Mandaue City',
        'description': 'Cebu, Philippines',
        'coordinates': LatLng(10.3233, 123.9400),
      },
      {
        'id': 'lapu_lapu_city',
        'name': 'Lapu-Lapu City',
        'description': 'Cebu, Philippines',
        'coordinates': LatLng(10.3103, 123.9494),
      },
      {
        'id': 'talamban',
        'name': 'Talamban',
        'description': 'Cebu City, Philippines',
        'coordinates': LatLng(10.3500, 123.9500),
      },
    ];
  }

  void _filterLocations(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredLocations = _getAllLocations();
      });
    } else {
      setState(() {
        _filteredLocations = _getAllLocations().where((location) {
          return location['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
                 location['description'].toString().toLowerCase().contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  List<Map<String, dynamic>> _getAllLocations() {
    return [
      {
        'id': 'bogo_city',
        'name': 'Bogo City',
        'description': 'Cebu, Philippines',
        'coordinates': LatLng(11.0474, 124.0051),
      },
      {
        'id': 'cebu_city',
        'name': 'Cebu City',
        'description': 'Cebu, Philippines',
        'coordinates': LatLng(10.3157, 123.8854),
      },
      {
        'id': 'mandaue_city',
        'name': 'Mandaue City',
        'description': 'Cebu, Philippines',
        'coordinates': LatLng(10.3233, 123.9400),
      },
      {
        'id': 'lapu_lapu_city',
        'name': 'Lapu-Lapu City',
        'description': 'Cebu, Philippines',
        'coordinates': LatLng(10.3103, 123.9494),
      },
      {
        'id': 'talamban',
        'name': 'Talamban',
        'description': 'Cebu City, Philippines',
        'coordinates': LatLng(10.3500, 123.9500),
      },
    ];
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.whileInUse || 
        permission == LocationPermission.always) {
      setState(() {
        _useCurrentLocation = true;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorDialog('Location services are disabled. Please enable location services in your device settings.');
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorDialog('Location permission denied. Please enable location permission in app settings.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showErrorDialog('Location permissions are permanently denied. Please enable them in app settings.');
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final location = LatLng(position.latitude, position.longitude);
      
      // Get address from coordinates
      final address = await _mapService.getAddressFromCoordinates(location);

      setState(() {
        _currentLocation = location;
        _currentAddress = address;
        _useCurrentLocation = true;
        _useManualLocation = false;
        _isLoading = false;
      });

      _showSuccessSnackBar('Current location obtained successfully!');

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to get current location: $e');
    }
  }

  Future<void> _getManualLocation() async {
    if (_addressController.text.trim().isEmpty) {
      _showErrorDialog('Please enter an address');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final location = await _mapService.getCoordinatesFromAddress(_addressController.text.trim());
      
      if (location == null) {
        _showErrorDialog('Could not find coordinates for the entered address. Please check the address and try again.');
        return;
      }

      setState(() {
        _manualLocation = location;
        _manualAddress = _addressController.text.trim();
        _useManualLocation = true;
        _useCurrentLocation = false;
        _isLoading = false;
      });

      _showSuccessSnackBar('Location found successfully!');

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to get location from address: $e');
    }
  }

  void _confirmLocation() {
    if (_useCurrentLocation && _currentLocation != null) {
      widget.onLocationSelected(_currentLocation!, _currentAddress);
      Navigator.of(context).pop();
    } else if (_useManualLocation && _manualLocation != null) {
      widget.onLocationSelected(_manualLocation!, _manualAddress);
      Navigator.of(context).pop();
    } else {
      _showErrorDialog('Please select a location first');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: Text('Select Location', style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: screenWidth * 0.055)),
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
                    'Choose Your Location',
                    style: AppTextStyles.headline.copyWith(
                      fontSize: screenWidth * 0.06,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.02),
                  Text(
                    'Select your delivery location to find nearby suppliers',
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
          // Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
            child: Neumorphic(
              style: AppNeumorphic.inset,
              child: TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  hintText: 'Enter your address (e.g., Bogo City, Cebu)',
                  hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  prefixIcon: Icon(Icons.search, color: AppColors.primaryGreen),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.04),
                ),
                style: AppTextStyles.body,
                onChanged: (value) {
                  setState(() {
                    _useManualLocation = false;
                  });
                  _filterLocations(value);
                },
              ),
            ),
          ),
          SizedBox(height: screenWidth * 0.04),
          // Location List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              itemCount: _filteredLocations.length,
              itemBuilder: (context, index) {
                final location = _filteredLocations[index];
                return _buildLocationCard(screenWidth, location);
              },
            ),
          ),
          // Action Buttons
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Row(
              children: [
                Expanded(
                  child: NeumorphicButton(
                    style: AppNeumorphic.button.copyWith(
                      color: AppColors.primaryGreen,
                    ),
                    onPressed: _isLoading ? null : _getCurrentLocation,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.04),
                      child: _isLoading
                          ? SizedBox(
                              height: screenWidth * 0.05,
                              width: screenWidth * 0.05,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Use Current Location',
                              style: AppTextStyles.button.copyWith(
                                color: Colors.white,
                                fontSize: screenWidth * 0.045,
                              ),
                            ),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),
                Expanded(
                  child: NeumorphicButton(
                    style: AppNeumorphic.button.copyWith(
                      color: _selectedLocationId != null ? AppColors.primaryGreen : AppColors.textSecondary,
                    ),
                    onPressed: _selectedLocationId != null ? _confirmLocation : null,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.04),
                      child: Text(
                        'Confirm Location',
                        style: AppTextStyles.button.copyWith(
                          color: Colors.white,
                          fontSize: screenWidth * 0.045,
                        ),
                      ),
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

  Widget _buildLocationCard(double screenWidth, Map<String, dynamic> location) {
    final isSelected = _selectedLocationId == location['id'];
    
    return Neumorphic(
      style: AppNeumorphic.card.copyWith(
        color: isSelected ? AppColors.primaryGreen.withOpacity(0.1) : Colors.white,
      ),
      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedLocationId = location['id'];
            _manualLocation = location['coordinates'];
            _manualAddress = '${location['name']}, ${location['description']}';
            _useManualLocation = true;
            _useCurrentLocation = false;
          });
        },
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Row(
            children: [
              Container(
                width: screenWidth * 0.12,
                height: screenWidth * 0.12,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(screenWidth * 0.06),
                ),
                child: Icon(
                  Icons.location_city,
                  color: AppColors.primaryGreen,
                  size: screenWidth * 0.06,
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location['name'] ?? 'Unknown Location',
                      style: AppTextStyles.headline.copyWith(
                        fontSize: screenWidth * 0.045,
                        color: isSelected ? AppColors.primaryGreen : AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.01),
                    Text(
                      location['description'] ?? 'No description available',
                      style: AppTextStyles.body.copyWith(
                        fontSize: screenWidth * 0.035,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppColors.primaryGreen,
                  size: screenWidth * 0.06,
                ),
            ],
          ),
        ),
      ),
    );
  }
} 