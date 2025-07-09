# Bogo City Map Scope Implementation

This document describes the implementation of map scope limitations to Bogo City, Cebu, Philippines with a barrier interface in the VegieConnect application.

## Overview

The map functionality has been updated to limit the scope to Bogo City, Cebu, Philippines (coordinates: 11.0474° N, 124.0051° E) with a 5km radius boundary. This creates a focused local marketplace for farmers and buyers within the Bogo City area.

## Changes Made

### 1. Map Center and Zoom Settings

**Files Modified:**
- `lib/supplier-side/farm_map_page.dart`
- `lib/customer-side/farm_locations_page.dart`

**Changes:**
- Updated initial map center from Manila (14.5995, 120.9842) to Bogo City (11.0474, 124.0051)
- Set initial zoom level to 12 (appropriate for city-level view)
- Added zoom limits: min zoom 10, max zoom 16
- Updated app bar titles to include "Bogo City"

### 2. Barrier Interface Implementation

**Visual Elements Added:**
- **Blue Circle Boundary**: 5km radius circle centered on Bogo City
  - Semi-transparent blue fill (10% opacity)
  - Blue border (50% opacity, 3px width)
  - Clearly marks the operational area

- **Boundary Indicator**: Floating label at top-left of map
  - Blue background with white text
  - Shows "📍 Bogo City Boundary"
  - Rounded corners with shadow for better visibility

### 3. Location Validation

**Supplier Map (`farm_map_page.dart`):**
- Added validation in `_onMapTap()` method
- Prevents adding farm locations outside the 5km radius
- Shows error message: "Farm locations can only be added within Bogo City boundaries"
- Uses `MapService.calculateDistance()` to check distance from city center

### 4. Default Location Updates

**Customer Map (`farm_locations_page.dart`):**
- Updated all default location fallbacks to use Bogo City coordinates
- Modified `_initializeLocation()` method
- Updated floating action button to center on Bogo City when user location unavailable

## Technical Implementation

### Coordinates Used
```dart
const LatLng bogoCityCenter = LatLng(11.0474, 124.0051);
const double bogoCityRadius = 5000; // 5km in meters
```

### Distance Calculation
```dart
double distance = _mapService.calculateDistance(bogoCityCenter, point);
if (distance > 5.0) { // 5km radius
  // Show error and prevent action
}
```

### Visual Elements
```dart
// Boundary circle
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

// Boundary indicator
Positioned(
  top: 16,
  left: 16,
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.blue.withOpacity(0.9),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [/* shadow properties */],
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
```

## User Experience

### For Suppliers:
1. Map automatically centers on Bogo City
2. Blue boundary circle shows operational area
3. Cannot add farms outside the boundary (validation prevents it)
4. Clear visual feedback when attempting to add location outside boundary
5. Floating action button centers map on Bogo City

### For Customers:
1. Map shows Bogo City area with boundary indicator
2. Can view all farms within the city boundary
3. Search radius slider works within the 5km limit
4. Distance calculations are accurate for the local area
5. Default location is Bogo City if GPS unavailable

## Benefits

1. **Local Focus**: Creates a concentrated marketplace for Bogo City
2. **Clear Boundaries**: Users understand the operational area
3. **Data Quality**: Prevents irrelevant farm locations from being added
4. **User Experience**: Intuitive visual indicators guide user behavior
5. **Scalability**: Framework can be easily adapted for other cities

## Future Enhancements

1. **Dynamic Boundaries**: Load city boundaries from database
2. **Multiple Cities**: Support for multiple city boundaries
3. **Boundary Editing**: Admin interface to adjust boundaries
4. **Geofencing**: Real-time location validation
5. **Analytics**: Track usage within boundaries

## Testing

To test the implementation:
1. Open supplier farm map
2. Try tapping outside the blue boundary circle
3. Verify error message appears
4. Tap inside boundary - should allow farm addition
5. Check customer map shows boundary indicator
6. Verify floating action button centers on Bogo City 