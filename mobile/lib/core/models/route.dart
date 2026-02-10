import 'package:latlong2/latlong.dart';

class TruckRoute {
  final List<LatLng> path;
  final double distanceKm;
  final int durationMin;
  final double? tollCostEur;
  final List<RouteWarning> warnings;
  final List<RouteRestriction> restrictions;
  final List<RouteManeuver> maneuvers;

  TruckRoute({
    required this.path,
    required this.distanceKm,
    required this.durationMin,
    this.tollCostEur,
    this.warnings = const [],
    this.restrictions = const [],
    this.maneuvers = const [],
  });

  factory TruckRoute.fromJson(Map<String, dynamic> json) {
    // Parse GeoJSON route
    List<LatLng> path = [];
    if (json['route'] != null && json['route']['geometry'] != null) {
      final coords = json['route']['geometry']['coordinates'] as List;
      path = coords.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
    }

    // Parse warnings
    List<RouteWarning> warnings = [];
    if (json['warnings'] != null) {
      warnings = (json['warnings'] as List)
          .map((w) => RouteWarning.fromJson(w))
          .toList();
    }

    // Parse restrictions
    List<RouteRestriction> restrictions = [];
    if (json['restrictions_on_route'] != null) {
      restrictions = (json['restrictions_on_route'] as List)
          .map((r) => RouteRestriction.fromJson(r))
          .toList();
    }

    // Parse maneuvers (turn-by-turn)
    List<RouteManeuver> maneuvers = [];
    if (json['maneuvers'] != null) {
      maneuvers = (json['maneuvers'] as List)
          .map((m) => RouteManeuver.fromJson(m))
          .toList();
    }

    return TruckRoute(
      path: path,
      distanceKm: (json['distance_km'] ?? json['distanceKm'] ?? 0).toDouble(),
      durationMin: (json['duration_min'] ?? json['durationMin'] ?? 0).toInt(),
      tollCostEur: json['toll_cost_eur']?.toDouble(),
      warnings: warnings,
      restrictions: restrictions,
      maneuvers: maneuvers,
    );
  }

  String get formattedDistance {
    if (distanceKm >= 1000) {
      return '${(distanceKm / 1000).toStringAsFixed(0)}k km';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  String get formattedDuration {
    final hours = durationMin ~/ 60;
    final minutes = durationMin % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  int get requiredBreaks {
    // EC 561/2006: 45 min break after 4.5 hours of driving
    return (durationMin / 270).floor();
  }
}

class RouteWarning {
  final String type;
  final String message;
  final LatLng? location;

  RouteWarning({
    required this.type,
    required this.message,
    this.location,
  });

  factory RouteWarning.fromJson(Map<String, dynamic> json) {
    LatLng? location;
    if (json['location'] != null) {
      location = LatLng(
        json['location']['lat'].toDouble(),
        json['location']['lng'].toDouble(),
      );
    }

    return RouteWarning(
      type: json['type'] ?? 'warning',
      message: json['message'] ?? '',
      location: location,
    );
  }
}

class RouteRestriction {
  final String type;
  final String value;
  final LatLng? location;
  final double confidence;

  RouteRestriction({
    required this.type,
    required this.value,
    this.location,
    this.confidence = 0.5,
  });

  factory RouteRestriction.fromJson(Map<String, dynamic> json) {
    LatLng? location;
    if (json['location'] != null) {
      location = LatLng(
        json['location']['lat'].toDouble(),
        json['location']['lng'].toDouble(),
      );
    }

    return RouteRestriction(
      type: json['type'] ?? '',
      value: json['value'] ?? '',
      location: location,
      confidence: (json['confidence'] ?? 0.5).toDouble(),
    );
  }
}

class RouteManeuver {
  final String instruction;
  final double distanceKm;
  final int durationMin;
  final String? streetName;
  final ManeuverType type;
  final LatLng location;

  RouteManeuver({
    required this.instruction,
    required this.distanceKm,
    required this.durationMin,
    this.streetName,
    required this.type,
    required this.location,
  });

  factory RouteManeuver.fromJson(Map<String, dynamic> json) {
    return RouteManeuver(
      instruction: json['instruction'] ?? '',
      distanceKm: (json['distance_km'] ?? json['length'] ?? 0).toDouble() / 1000,
      durationMin: ((json['time'] ?? 0) / 60).round(),
      streetName: json['street_name'] ?? json['streetName'],
      type: ManeuverType.fromString(json['type']?.toString()),
      location: LatLng(
        (json['lat'] ?? json['location']?['lat'] ?? 0).toDouble(),
        (json['lng'] ?? json['location']?['lng'] ?? 0).toDouble(),
      ),
    );
  }
}

enum ManeuverType {
  depart,
  arrive,
  turnLeft,
  turnRight,
  slightLeft,
  slightRight,
  sharpLeft,
  sharpRight,
  straight,
  roundaboutLeft,
  roundaboutRight,
  merge,
  rampLeft,
  rampRight,
  ferry,
  destination,
  unknown;

  static ManeuverType fromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'depart':
        return ManeuverType.depart;
      case 'arrive':
        return ManeuverType.arrive;
      case 'turn-left':
      case 'left':
        return ManeuverType.turnLeft;
      case 'turn-right':
      case 'right':
        return ManeuverType.turnRight;
      case 'slight-left':
      case 'bear-left':
        return ManeuverType.slightLeft;
      case 'slight-right':
      case 'bear-right':
        return ManeuverType.slightRight;
      case 'sharp-left':
        return ManeuverType.sharpLeft;
      case 'sharp-right':
        return ManeuverType.sharpRight;
      case 'straight':
      case 'continue':
        return ManeuverType.straight;
      case 'roundabout-left':
        return ManeuverType.roundaboutLeft;
      case 'roundabout-right':
        return ManeuverType.roundaboutRight;
      case 'merge':
        return ManeuverType.merge;
      case 'ramp-left':
        return ManeuverType.rampLeft;
      case 'ramp-right':
        return ManeuverType.rampRight;
      case 'ferry':
        return ManeuverType.ferry;
      case 'destination':
        return ManeuverType.destination;
      default:
        return ManeuverType.unknown;
    }
  }
}

class RouteRequest {
  final LatLng origin;
  final LatLng destination;
  final List<LatLng> waypoints;
  final String? truckProfileId;
  final bool avoidTolls;
  final bool avoidFerries;
  final bool avoidHighways;
  final List<String>? excludeCountries;
  final DateTime? departureTime;

  RouteRequest({
    required this.origin,
    required this.destination,
    this.waypoints = const [],
    this.truckProfileId,
    this.avoidTolls = false,
    this.avoidFerries = false,
    this.avoidHighways = false,
    this.excludeCountries,
    this.departureTime,
  });

  Map<String, dynamic> toJson() {
    final avoid = <String>[];
    if (avoidTolls) avoid.add('tolls');
    if (avoidFerries) avoid.add('ferries');
    if (avoidHighways) avoid.add('highways');

    return {
      'origin': {'lat': origin.latitude, 'lng': origin.longitude},
      'destination': {'lat': destination.latitude, 'lng': destination.longitude},
      if (waypoints.isNotEmpty)
        'waypoints': waypoints.map((w) => {'lat': w.latitude, 'lng': w.longitude}).toList(),
      if (truckProfileId != null) 'truck_profile_id': truckProfileId,
      if (avoid.isNotEmpty) 'avoid': avoid,
      if (excludeCountries != null) 'exclude_countries': excludeCountries,
      if (departureTime != null) 'departure_time': departureTime!.toIso8601String(),
    };
  }
}
