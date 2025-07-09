# Vicinity Detection and Automatic Guides

This document describes the implementation of automatic vicinity detection and guide system that provides buyers with helpful information and directions when they are near supplier-added farm locations.

## Overview

The vicinity detection system automatically identifies when buyers are within 1km of farm locations and provides them with comprehensive guides, tips, and navigation assistance. This enhances the customer experience by proactively offering relevant information when it's most useful.

## Features Implemented

### 1. Automatic Vicinity Detection

**Detection Logic:**
- Monitors user location in real-time
- Automatically detects farms within 1km radius
- Triggers guide system when farms are nearby
- Prevents duplicate notifications during the same session

**Technical Implementation:**
```dart
double _vicinityRadius = 1.0; // 1km radius for automatic guides
List<FarmLocation> _veryNearbyFarms = []; // Farms within vicinity radius
bool _hasShownVicinityGuide = false; // Track if guide has been shown
```

### 2. Automatic Guide Dialog

**When Triggered:**
- User enters within 1km of any farm location
- Only shows once per session to avoid spam
- Non-dismissible dialog to ensure user sees the information

**Guide Content:**
- **Farm Information**: Name, supplier, distance, address
- **Visual Guide**: Tips for visiting the farm
- **Navigation Options**: Direct access to directions
- **Helpful Tips**: Best practices for farm visits

**Guide Tips Include:**
- Look for farm signs or markers
- Contact the supplier before visiting
- Check farm operating hours
- Bring cash for purchases
- Ask about available products

### 3. Enhanced Visual Indicators

**Map Markers:**
- **Very Nearby Farms** (≤1km): Orange markers with red "!" badge
- **Nearby Farms** (≤search radius): Green markers
- **Other Farms**: Grey markers
- **Special Effects**: Larger size, glow effect, and attention badge

**Status Indicators:**
- **Vicinity Badge**: Shows count of nearby farms at top-right
- **Dynamic Updates**: Real-time updates as user moves
- **Visual Hierarchy**: Clear distinction between proximity levels

### 4. Comprehensive Navigation System

**Multiple Navigation Options:**
1. **Walking Directions**: For distances ≤2km
2. **Driving Directions**: For all distances
3. **External Maps**: Open in preferred navigation app

**Route Information:**
- Distance and duration estimates
- Step-by-step directions
- Route summary with mode selection
- Integration with OpenRouteService API

### 5. Farm Visit Tips

**Contextual Advice:**
- Call ahead to confirm availability
- Check if the farm is open today
- Ask about parking availability
- Bring containers for fresh produce
- Consider weather conditions

## User Experience Flow

### 1. Automatic Detection
```
User enters 1km radius of farm
↓
System detects very nearby farms
↓
Sorts farms by distance
↓
Shows automatic guide dialog
```

### 2. Guide Interaction
```
Guide dialog appears
↓
User sees farm info and tips
↓
User can:
- Close dialog
- Get detailed directions
- Access navigation options
```

### 3. Navigation Assistance
```
User requests directions
↓
Detailed directions dialog opens
↓
Multiple navigation options:
- Walking directions (if ≤2km)
- Driving directions
- Open in external maps
```

## Technical Implementation

### State Management

```dart
class _FarmLocationsPageState extends State<FarmLocationsPage> {
  List<FarmLocation> _veryNearbyFarms = [];
  double _vicinityRadius = 1.0;
  bool _hasShownVicinityGuide = false;
}
```

### Key Methods

1. **`_filterNearbyFarms()`**:
   - Filters farms by search radius
   - Identifies very nearby farms
   - Triggers guide system

2. **`_checkAndShowVicinityGuide()`**:
   - Checks if guide should be shown
   - Prevents duplicate notifications
   - Calls guide display method

3. **`_showVicinityGuide()`**:
   - Displays comprehensive guide dialog
   - Shows farm information and tips
   - Provides navigation options

4. **`_showDetailedDirections()`**:
   - Enhanced directions interface
   - Multiple navigation modes
   - Farm visit tips

### Visual Enhancements

**Marker Styling:**
```dart
// Very nearby farms get special treatment
bool isVeryNearby = distance <= _vicinityRadius;
width: isVeryNearby ? 50 : 40,
height: isVeryNearby ? 50 : 40,
color: isVeryNearby ? Colors.orange : Colors.green,
boxShadow: isVeryNearby ? [glow effect] : null,
```

**Status Indicators:**
```dart
// Vicinity badge
if (_veryNearbyFarms.isNotEmpty)
  Positioned(
    child: Container(
      child: Text('${_veryNearbyFarms.length} Farm(s) Nearby'),
    ),
  ),
```

## Benefits

1. **Proactive Assistance**: Automatically provides relevant information
2. **Enhanced Navigation**: Multiple direction options for different needs
3. **Visual Clarity**: Clear distinction between proximity levels
4. **User Guidance**: Helpful tips for successful farm visits
5. **Contextual Information**: Shows information when most relevant
6. **Improved UX**: Reduces friction in finding and visiting farms

## User Scenarios

### Scenario 1: Walking to Nearby Farm
1. User walks within 1km of farm
2. Automatic guide appears with walking directions
3. User gets step-by-step navigation
4. Tips help ensure successful visit

### Scenario 2: Driving to Farm
1. User drives near farm location
2. Guide shows driving directions option
3. User gets route with traffic considerations
4. Parking and visit tips provided

### Scenario 3: Multiple Farms Nearby
1. User in area with several farms
2. Guide shows nearest farm first
3. Vicinity badge shows total count
4. User can explore all nearby options

## Error Handling

1. **Location Services**: Graceful fallback if GPS unavailable
2. **Network Issues**: Offline-friendly with cached data
3. **API Failures**: Fallback to basic directions
4. **Permission Denied**: Clear messaging about location access

## Future Enhancements

1. **Push Notifications**: Alert users when approaching farms
2. **Offline Maps**: Download maps for offline use
3. **Voice Navigation**: Audio directions for hands-free use
4. **Farm Reviews**: User-generated tips and reviews
5. **Real-time Updates**: Live farm status and availability
6. **Social Features**: Share farm visits with friends

## Testing Scenarios

1. **Vicinity Detection**:
   - Move within 1km of farm
   - Verify guide appears
   - Check no duplicate guides

2. **Visual Indicators**:
   - Verify marker colors and sizes
   - Check vicinity badge updates
   - Test attention indicators

3. **Navigation Options**:
   - Test walking directions (≤2km)
   - Test driving directions
   - Verify external map integration

4. **Error Handling**:
   - Test with location services off
   - Test with network issues
   - Verify graceful degradation 