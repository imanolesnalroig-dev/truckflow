import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

final locationSearchServiceProvider = Provider<LocationSearchService>((ref) {
  return LocationSearchService();
});

class SearchResult {
  final String displayName;
  final String name;
  final LatLng location;
  final String? address;
  final String? type;

  SearchResult({
    required this.displayName,
    required this.name,
    required this.location,
    this.address,
    this.type,
  });

  factory SearchResult.fromNominatim(Map<String, dynamic> json) {
    return SearchResult(
      displayName: json['display_name'] ?? '',
      name: json['name'] ?? json['display_name']?.split(',').first ?? '',
      location: LatLng(
        double.parse(json['lat'].toString()),
        double.parse(json['lon'].toString()),
      ),
      address: json['display_name'],
      type: json['type'],
    );
  }
}

class LocationSearchService {
  final Dio _dio = Dio();

  // Nominatim (OSM) free geocoding service
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org';

  Future<List<SearchResult>> search(String query, {LatLng? nearLocation}) async {
    if (query.trim().isEmpty) return [];

    try {
      final params = <String, dynamic>{
        'q': query,
        'format': 'json',
        'addressdetails': 1,
        'limit': 10,
        'accept-language': 'en',
      };

      // Bias results towards user's location if available
      if (nearLocation != null) {
        params['viewbox'] = '${nearLocation.longitude - 5},${nearLocation.latitude - 5},${nearLocation.longitude + 5},${nearLocation.latitude + 5}';
        params['bounded'] = 0;
      }

      final response = await _dio.get(
        '$_nominatimUrl/search',
        queryParameters: params,
        options: Options(headers: {
          'User-Agent': 'TruckFlow/1.0 (contact@truckflow.app)',
        }),
      );

      if (response.data is List) {
        return (response.data as List)
            .map((json) => SearchResult.fromNominatim(json))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<SearchResult?> reverseGeocode(LatLng location) async {
    try {
      final response = await _dio.get(
        '$_nominatimUrl/reverse',
        queryParameters: {
          'lat': location.latitude,
          'lon': location.longitude,
          'format': 'json',
          'addressdetails': 1,
        },
        options: Options(headers: {
          'User-Agent': 'TruckFlow/1.0 (contact@truckflow.app)',
        }),
      );

      if (response.data != null && response.data['lat'] != null) {
        return SearchResult.fromNominatim(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
