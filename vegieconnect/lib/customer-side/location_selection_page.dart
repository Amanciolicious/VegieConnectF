// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../services/map_service.dart';

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

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
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
    final screenHeight = MediaQuery.of(context).size.height;
    final green = const Color(0xFFA7C957);
    final cardRadius = BorderRadius.circular(screenWidth * 0.05);
    final neumorphicShadow = [
      BoxShadow(
        color: Colors.grey.shade300,
        offset: Offset(screenWidth * 0.015, screenWidth * 0.015),
        blurRadius: screenWidth * 0.04,
      ),
      BoxShadow(
        color: Colors.white,
        offset: Offset(-screenWidth * 0.015, -screenWidth * 0.015),
        blurRadius: screenWidth * 0.04,
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text('Choose Your Location', style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold)),
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: green),
                  SizedBox(height: screenWidth * 0.04),
                  Text('Getting location...', style: TextStyle(fontSize: screenWidth * 0.04)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    decoration: BoxDecoration(
                      color: green.withOpacity(0.1),
                      borderRadius: cardRadius,
                      border: Border.all(color: green.withOpacity(0.3)),
                      boxShadow: neumorphicShadow,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: screenWidth * 0.12,
                          color: green,
                        ),
                        SizedBox(height: screenWidth * 0.03),
                        Text(
                          'Select Your Location',
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.02),
                        Text(
                          'Choose how you want to set your location for finding nearby suppliers',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: screenWidth * 0.035,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.06),

                  // Current Location Option
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _useCurrentLocation ? Colors.green : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: InkWell(
                      onTap: _getCurrentLocation,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.my_location,
                                color: Colors.green,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Use My Current Location',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Automatically detect your location using GPS',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (_useCurrentLocation && _currentAddress.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _currentAddress,
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (_useCurrentLocation)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Manual Location Option
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _useManualLocation ? Colors.green : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.edit_location,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Set My Location Manually',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Enter your address or preferred location',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_useManualLocation)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 24,
                                ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          TextField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              hintText: 'Enter your address (e.g., Bogo City, Cebu)',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey.withOpacity(0.05),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _useManualLocation = false;
                              });
                            },
                          ),
                          
                          const SizedBox(height: 12),
                          
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _getManualLocation,
                              icon: const Icon(Icons.search),
                              label: const Text('Find Location'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          
                          if (_useManualLocation && _manualAddress.isNotEmpty) ...[
                            const SizedBox(height: 12),
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
                                  const Text(
                                    'Selected Location:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _manualAddress,
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Confirm Button
                  ElevatedButton(
                    onPressed: (_useCurrentLocation && _currentLocation != null) ||
                              (_useManualLocation && _manualLocation != null)
                        ? _confirmLocation
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Confirm Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 