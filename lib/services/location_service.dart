import 'dart:convert';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:http/http.dart' as http;
import '../constants/municipality_centers.dart';

class AddressSearchResult {
  final String displayName;
  final LatLng point;
  AddressSearchResult({required this.displayName, required this.point});
}

class LocationService {
  static const double _districtRadiusKm = 10.0;

  static double haversineDistanceKm(LatLng point1, LatLng point2) {
    const earthRadiusKm = 6371.0;

    final lat1Rad = point1.latitude * (pi / 180);
    final lat2Rad = point2.latitude * (pi / 180);
    final deltaLat = (point2.latitude - point1.latitude) * (pi / 180);
    final deltaLng = (point2.longitude - point1.longitude) * (pi / 180);

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLng / 2) * sin(deltaLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static double distanceToNearestMunicipalityKm(LatLng point) {
    double closest = double.infinity;
    for (final center in kMunicipalityCenters.values) {
      final distance = haversineDistanceKm(point, center);
      if (distance < closest) closest = distance;
    }
    return closest;
  }

  static bool isWithinBhaktapurDistrict(LatLng point) {
    return distanceToNearestMunicipalityKm(point) <= _districtRadiusKm;
  }

  static String detectNearestMunicipality(LatLng point) {
    String closest = kMunicipalityCenters.keys.first;
    double closestDistance = double.infinity;

    for (final entry in kMunicipalityCenters.entries) {
      final distance = haversineDistanceKm(point, entry.value);
      if (distance < closestDistance) {
        closestDistance = distance;
        closest = entry.key;
      }
    }

    return closest;
  }

  static Future<LatLng?> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      return null;
    }
  }

  static Future<List<AddressSearchResult>> searchAddress(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
          '?format=json&q=${Uri.encodeComponent(query)}'
          '&limit=6&bounded=1&viewbox=85.34,27.75,85.50,27.60',
    );

    try {
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'WardComplaintApp/1.0 (student project)'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final List<dynamic> results = jsonDecode(response.body);
      return results.map((item) {
        return AddressSearchResult(
          displayName: item['display_name'] ?? 'Unknown location',
          point: LatLng(
            double.parse(item['lat']),
            double.parse(item['lon']),
          ),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Reverse geocoding: given a coordinate, ask Nominatim for the
  /// human-readable address at that point. Returns null on failure,
  /// so the caller can fall back to showing raw coordinates instead.
  static Future<String?> reverseGeocode(LatLng point) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
          '?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1',
    );

    try {
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'WardComplaintApp/1.0 (student project)'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      return data['display_name'] as String?;
    } catch (e) {
      return null;
    }
  }
}