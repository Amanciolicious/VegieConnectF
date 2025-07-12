import 'package:open_route_service/open_route_service.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MapService {
  static const String _apiKey = 'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImUzNDFmOTFmNGJlODQxOWRiNDY2M2UxNWE3N2VhMWI2IiwiaCI6Im11cm11cjY0In0='; // Replace with your actual API key
  late final OpenRouteService _openRouteService;

  MapService() {
    _openRouteService = OpenRouteService(apiKey: _apiKey);
  }

  // Get route between two points
  Future<Map<String, dynamic>> getRoute({
    required LatLng start,
    required LatLng end,
    String profile = 'driving-car',
  }) async {
    try {
      final url = Uri.parse(
        'https://api.openrouteservice.org/v2/directions/$profile/geojson',
      );
      final body = jsonEncode({
        'coordinates': [
          [start.longitude, start.latitude],
          [end.longitude, end.latitude],
        ]
      });
      final response = await http.post(
        url,
        headers: {
          'Authorization': _apiKey,
          'Content-Type': 'application/json',
        },
        body: body,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get route: \\${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get route: $e');
    }
  }

  // Get address from coordinates
  Future<String> getAddressFromCoordinates(LatLng coordinates) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Compose a more detailed address
        String address = '';
        if (place.name != null && place.name!.isNotEmpty) address += '${place.name}, ';
        if (place.street != null && place.street!.isNotEmpty) address += '${place.street}, ';
        if (place.subLocality != null && place.subLocality!.isNotEmpty) address += '${place.subLocality}, ';
        if (place.locality != null && place.locality!.isNotEmpty) address += '${place.locality}, ';
        if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) address += '${place.subAdministrativeArea}, ';
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) address += '${place.administrativeArea}, ';
        if (place.postalCode != null && place.postalCode!.isNotEmpty) address += '${place.postalCode}, ';
        if (place.country != null && place.country!.isNotEmpty) address += '${place.country}';
        // Remove trailing comma and space
        address = address.trim();
        if (address.endsWith(',')) address = address.substring(0, address.length - 1);
        return address;
      }
      return 'Unknown location';
    } catch (e) {
      return 'Unknown location';
    }
  }

  // Get coordinates from address
  Future<LatLng?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations[0].latitude, locations[0].longitude);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Calculate distance between two points
  double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    double lat1Rad = point1.latitude * (pi / 180);
    double lat2Rad = point2.latitude * (pi / 180);
    double deltaLat = (point2.latitude - point1.latitude) * (pi / 180);
    double deltaLon = (point2.longitude - point1.longitude) * (pi / 180);

    double a = pow(sin(deltaLat / 2), 2) +
        cos(lat1Rad) * cos(lat2Rad) * pow(sin(deltaLon / 2), 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  // Check if a point is within a certain radius of another point
  bool isWithinRadius(LatLng center, LatLng point, double radiusKm) {
    double distance = calculateDistance(center, point);
    return distance <= radiusKm;
  }
} 