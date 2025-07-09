# Farm Map Setup Guide

This guide explains how to set up the farm location mapping feature in VegieConnect.

## Features Implemented

### For Suppliers:
- **Farm Map Page**: Interactive map where suppliers can add farm locations by tapping
- **Farm Management**: Add, view, and delete farm locations
- **Location Details**: Farm name, description, and address geocoding

### For Buyers:
- **Farm Discovery**: View all farm locations on an interactive map
- **Nearby Farms**: Filter farms within a configurable radius (1-50km)
- **GPS Directions**: Get turn-by-turn directions to farms using OpenRouteService
- **Distance Calculation**: See distance from current location to farms

## Dependencies Added

The following dependencies have been added to `pubspec.yaml`:

```yaml
flutter_map: ^6.1.0          # Interactive map widget
open_route_service: ^1.2.7   # Routing and directions API
latlong2: ^0.9.1             # Coordinate handling
geocoding: ^4.0.0            # Address geocoding
geolocator: ^11.0.0          # Location services
```

## Setup Instructions

### 1. Get OpenRouteService API Key

1. Visit [OpenRouteService](https://openrouteservice.org/dev/#/signup)
2. Sign up for a free account
3. Get your API key from the dashboard
4. Replace the API key in `lib/services/map_service.dart`:

```dart
static const String _apiKey = 'YOUR_ACTUAL_API_KEY_HERE';
```

### 2. Location Permissions

For Android, add the following permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

For iOS, add the following to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to location to show nearby farms and provide directions.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs access to location to show nearby farms and provide directions.</string>
```

### 3. Firestore Collection

The app will automatically create a `farm_locations` collection in Firestore with the following structure:

```json
{
  "id": "unique_farm_id",
  "name": "Farm Name",
  "description": "Farm description",
  "latitude": 14.5995,
  "longitude": 120.9842,
  "supplierId": "supplier_user_id",
  "supplierName": "Supplier Name",
  "address": "Geocoded address",
  "createdAt": "timestamp",
  "isActive": true
}
```

## Usage

### Suppliers:
1. Navigate to Supplier Dashboard
2. Open the drawer menu
3. Tap "Farm Locations"
4. Tap anywhere on the map to add a farm location
5. Enter farm name and description
6. View and manage existing farm locations

### Buyers:
1. Navigate to Customer Home
2. Open the drawer menu
3. Tap "Farm Locations"
4. Use the radius slider to filter nearby farms
5. Tap farm markers to view details
6. Get directions to farms

## Files Created/Modified

### New Files:
- `lib/models/farm_location.dart` - Farm location data model
- `lib/services/map_service.dart` - OpenRouteService integration
- `lib/services/farm_location_service.dart` - Firestore operations
- `lib/supplier-side/farm_map_page.dart` - Supplier farm management
- `lib/customer-side/farm_locations_page.dart` - Buyer farm discovery

### Modified Files:
- `pubspec.yaml` - Added new dependencies
- `lib/supplier-side/supplier_dashboard.dart` - Added farm locations menu
- `lib/customer-side/customer_home_page.dart` - Added farm locations menu

## API Usage

The app uses OpenRouteService for:
- Route calculation between user location and farms
- Distance and duration estimation
- Turn-by-turn directions

Free tier includes 2,000 requests per day, which should be sufficient for most use cases.

## Troubleshooting

### Map not loading:
- Check internet connection
- Verify OpenRouteService API key is correct
- Ensure location permissions are granted

### Directions not working:
- Verify OpenRouteService API key
- Check if start and end coordinates are valid
- Ensure user location is available

### Location services not working:
- Check device location permissions
- Ensure GPS is enabled
- Verify geolocator package is properly configured

## Security Notes

- API keys should be stored securely in production
- Consider implementing rate limiting for API calls
- Validate coordinates before saving to Firestore
- Implement proper error handling for API failures 