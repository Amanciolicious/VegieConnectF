import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vegieconnect/theme.dart';
import 'package:vegieconnect/models/supplier_location.dart';
import 'package:vegieconnect/services/supplier_location_service.dart';
import 'package:vegieconnect/services/map_service.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

class SupplierLocationManagementPage extends StatefulWidget {
  const SupplierLocationManagementPage({super.key});

  @override
  State<SupplierLocationManagementPage> createState() => _SupplierLocationManagementPageState();
}

class _SupplierLocationManagementPageState extends State<SupplierLocationManagementPage> {
  final MapController _mapController = MapController();
  final SupplierLocationService _supplierLocationService = SupplierLocationService();
  final MapService _mapService = MapService();
  final TextEditingController _locationNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  SupplierLocation? _currentLocation;
  LatLng? _selectedLocation;
  String _currentAddress = '';
  bool _isLoading = true;
  bool _isUpdating = false;
  bool _isGettingCurrentLocation = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _locationNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final location = await _supplierLocationService.getCurrentUserSupplierLocation();
      
      if (location != null) {
        setState(() {
          _currentLocation = location;
          _selectedLocation = LatLng(location.latitude, location.longitude);
          _currentAddress = location.address;
          _locationNameController.text = location.locationName;
          _descriptionController.text = location.description;
        });
      } else {
        // No existing location, get current device location
        await _getCurrentDeviceLocation();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load location: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentDeviceLocation() async {
    try {
      setState(() {
        _isGettingCurrentLocation = true;
        _errorMessage = null;
      });

      final locationData = await _mapService.getCurrentLocationWithAddress();
      final location = locationData['location'] as LatLng;
      final address = locationData['address'] as String;

      setState(() {
        _selectedLocation = location;
        _currentAddress = address;
        _isGettingCurrentLocation = false;
      });

      // Fit map to show the location
      _mapController.move(location, 15);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get current location: $e';
        _isGettingCurrentLocation = false;
      });
    }
  }

  Future<void> _updateLocation() async {
    if (_selectedLocation == null) {
      setState(() {
        _errorMessage = 'Please select a location first';
      });
      return;
    }

    if (_locationNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a location name';
      });
      return;
    }

    try {
      setState(() {
        _isUpdating = true;
        _errorMessage = null;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _supplierLocationService.createOrUpdateSupplierLocation(
        supplierId: user.uid,
        supplierName: user.displayName ?? user.email ?? 'Unknown Supplier',
        locationName: _locationNameController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _selectedLocation,
        address: _currentAddress,
      );

      // Reload the current location
      await _loadCurrentLocation();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update location: $e';
      });
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
    _updateAddressFromLocation(point);
  }

  Future<void> _updateAddressFromLocation(LatLng location) async {
    try {
      final address = await _mapService.getAddressFromCoordinates(location);
      setState(() {
        _currentAddress = address;
      });
    } catch (e) {
      setState(() {
        _currentAddress = 'Address not available';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: Text(
          'Manage Location',
          style: AppTextStyles.headline.copyWith(
            color: Colors.white,
            fontSize: screenWidth * 0.055,
          ),
        ),
        elevation: 0,
        actions: [
          if (_currentLocation != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadCurrentLocation,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Map Section
                Expanded(
                  flex: 2,
                  child: Neumorphic(
                    style: AppNeumorphic.card,
                    margin: EdgeInsets.all(screenWidth * 0.04),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(screenWidth * 0.05),
                      child: _buildMapSection(screenWidth),
                    ),
                  ),
                ),
                // Form Section
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: _buildFormSection(screenWidth),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMapSection(double screenWidth) {
    if (_selectedLocation == null) {
      return Container(
        color: AppColors.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: screenWidth * 0.15,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: screenWidth * 0.03),
              Text(
                'No location selected',
                style: AppTextStyles.headline.copyWith(
                  fontSize: screenWidth * 0.05,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: screenWidth * 0.02),
              Text(
                'Tap "Get Current Location" or tap on the map',
                style: AppTextStyles.body.copyWith(
                  fontSize: screenWidth * 0.04,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _selectedLocation!,
        initialZoom: 15,
        maxZoom: 18,
        minZoom: 10,
        onTap: _onMapTap,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.vegieconnect',
        ),
        // Bogo City boundary
        CircleLayer(
          circles: [
            CircleMarker(
              point: const LatLng(11.0474, 124.0051),
              radius: 15000, // 15km radius
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderColor: AppColors.primaryGreen.withOpacity(0.5),
              borderStrokeWidth: 3,
            ),
          ],
        ),
        // Selected location marker
        MarkerLayer(
          markers: [
            Marker(
              point: _selectedLocation!,
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormSection(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location Info Card
        Neumorphic(
          style: AppNeumorphic.card,
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: AppColors.primaryGreen,
                      size: screenWidth * 0.06,
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Text(
                      'Location Information',
                      style: AppTextStyles.headline.copyWith(
                        fontSize: screenWidth * 0.05,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenWidth * 0.03),
                if (_currentAddress.isNotEmpty) ...[
                  Text(
                    'Address:',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.04,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.01),
                  Text(
                    _currentAddress,
                    style: AppTextStyles.body.copyWith(
                      fontSize: screenWidth * 0.035,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.03),
                ],
                if (_selectedLocation != null) ...[
                  Text(
                    'Coordinates:',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.04,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.01),
                  Text(
                    '${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                    style: AppTextStyles.body.copyWith(
                      fontSize: screenWidth * 0.035,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(height: screenWidth * 0.04),

        // Location Name Field
        Neumorphic(
          style: AppNeumorphic.inset,
          child: TextField(
            controller: _locationNameController,
            decoration: InputDecoration(
              labelText: 'Location Name *',
              prefixIcon: Icon(Icons.store, color: AppColors.primaryGreen),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(screenWidth * 0.04),
            ),
          ),
        ),
        SizedBox(height: screenWidth * 0.03),

        // Description Field
        Neumorphic(
          style: AppNeumorphic.inset,
          child: TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description',
              prefixIcon: Icon(Icons.description, color: AppColors.primaryGreen),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(screenWidth * 0.04),
            ),
          ),
        ),
        SizedBox(height: screenWidth * 0.04),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: NeumorphicButton(
                style: AppNeumorphic.button.copyWith(
                  color: Colors.blue,
                ),
                onPressed: _isGettingCurrentLocation ? null : _getCurrentDeviceLocation,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isGettingCurrentLocation)
                        SizedBox(
                          width: screenWidth * 0.04,
                          height: screenWidth * 0.04,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else
                        Icon(Icons.my_location, color: Colors.white, size: screenWidth * 0.05),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        'Get Current Location',
                        style: AppTextStyles.button.copyWith(
                          color: Colors.white,
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: screenWidth * 0.03),

        // Update Button
        SizedBox(
          width: double.infinity,
          child: NeumorphicButton(
            style: AppNeumorphic.button.copyWith(
              color: AppColors.primaryGreen,
            ),
            onPressed: _isUpdating ? null : _updateLocation,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isUpdating)
                    SizedBox(
                      width: screenWidth * 0.04,
                      height: screenWidth * 0.04,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    Icon(Icons.save, color: Colors.white, size: screenWidth * 0.05),
                  SizedBox(width: screenWidth * 0.02),
                  Text(
                    _currentLocation != null ? 'Update Location' : 'Save Location',
                    style: AppTextStyles.button.copyWith(
                      color: Colors.white,
                      fontSize: screenWidth * 0.04,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Error Message
        if (_errorMessage != null) ...[
          SizedBox(height: screenWidth * 0.03),
          Container(
            padding: EdgeInsets.all(screenWidth * 0.03),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: screenWidth * 0.04),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: AppTextStyles.body.copyWith(
                      color: Colors.red,
                      fontSize: screenWidth * 0.035,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Instructions
        SizedBox(height: screenWidth * 0.04),
        Container(
          padding: EdgeInsets.all(screenWidth * 0.04),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: screenWidth * 0.04),
                  SizedBox(width: screenWidth * 0.02),
                  Text(
                    'Instructions:',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      fontSize: screenWidth * 0.04,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenWidth * 0.02),
              Text(
                '• Tap "Get Current Location" to use your device GPS',
                style: AppTextStyles.body.copyWith(fontSize: screenWidth * 0.035),
              ),
              Text(
                '• Tap anywhere on the map to manually select location',
                style: AppTextStyles.body.copyWith(fontSize: screenWidth * 0.035),
              ),
              Text(
                '• Location must be within Bogo City limits',
                style: AppTextStyles.body.copyWith(fontSize: screenWidth * 0.035),
              ),
              Text(
                '• Green circle shows Bogo City boundary',
                style: AppTextStyles.body.copyWith(fontSize: screenWidth * 0.035),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 