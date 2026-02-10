class TruckPark {
  final String id;
  final String name;
  final String? address;
  final String? country;
  final double lat;
  final double lng;
  final int? totalSpaces;
  final bool hasSecurity;
  final bool hasCamera;
  final bool hasFence;
  final bool hasElectricity;
  final bool hasWater;
  final bool hasToilets;
  final bool hasShowers;
  final bool hasRestaurant;
  final bool hasShop;
  final bool hasAdblue;
  final bool hasWifi;
  final int? currentOccupancyPct;
  final DateTime? lastOccupancyUpdate;
  final double? avgRating;
  final int totalReviews;
  final double? pricePerNightEur;
  final bool isFree;
  final DateTime createdAt;

  // Computed from location
  double? distanceKm;

  TruckPark({
    required this.id,
    required this.name,
    this.address,
    this.country,
    required this.lat,
    required this.lng,
    this.totalSpaces,
    this.hasSecurity = false,
    this.hasCamera = false,
    this.hasFence = false,
    this.hasElectricity = false,
    this.hasWater = false,
    this.hasToilets = false,
    this.hasShowers = false,
    this.hasRestaurant = false,
    this.hasShop = false,
    this.hasAdblue = false,
    this.hasWifi = false,
    this.currentOccupancyPct,
    this.lastOccupancyUpdate,
    this.avgRating,
    this.totalReviews = 0,
    this.pricePerNightEur,
    this.isFree = false,
    required this.createdAt,
    this.distanceKm,
  });

  int? get freeSpaces {
    if (totalSpaces == null || currentOccupancyPct == null) return null;
    return (totalSpaces! * (100 - currentOccupancyPct!) / 100).round();
  }

  List<String> get amenities {
    final list = <String>[];
    if (hasShowers) list.add('shower');
    if (hasRestaurant) list.add('restaurant');
    if (hasWifi) list.add('wifi');
    if (hasSecurity || hasCamera || hasFence) list.add('security');
    if (hasShop) list.add('shop');
    if (hasAdblue) list.add('fuel');
    if (hasToilets) list.add('wc');
    if (hasElectricity) list.add('electricity');
    if (hasWater) list.add('water');
    return list;
  }

  String get priceDisplay {
    if (isFree) return 'Free';
    if (pricePerNightEur != null) return '€${pricePerNightEur!.toStringAsFixed(0)}/night';
    return 'Unknown';
  }

  factory TruckPark.fromJson(Map<String, dynamic> json) {
    return TruckPark(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      country: json['country'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      totalSpaces: json['totalSpaces'] ?? json['total_spaces'],
      hasSecurity: json['hasSecurity'] ?? json['has_security'] ?? false,
      hasCamera: json['hasCamera'] ?? json['has_camera'] ?? false,
      hasFence: json['hasFence'] ?? json['has_fence'] ?? false,
      hasElectricity: json['hasElectricity'] ?? json['has_electricity'] ?? false,
      hasWater: json['hasWater'] ?? json['has_water'] ?? false,
      hasToilets: json['hasToilets'] ?? json['has_toilets'] ?? false,
      hasShowers: json['hasShowers'] ?? json['has_showers'] ?? false,
      hasRestaurant: json['hasRestaurant'] ?? json['has_restaurant'] ?? false,
      hasShop: json['hasShop'] ?? json['has_shop'] ?? false,
      hasAdblue: json['hasAdblue'] ?? json['has_adblue'] ?? false,
      hasWifi: json['hasWifi'] ?? json['has_wifi'] ?? false,
      currentOccupancyPct: json['currentOccupancyPct'] ?? json['current_occupancy_pct'],
      lastOccupancyUpdate: json['lastOccupancyUpdate'] != null || json['last_occupancy_update'] != null
          ? DateTime.parse(json['lastOccupancyUpdate'] ?? json['last_occupancy_update'])
          : null,
      avgRating: (json['avgRating'] ?? json['avg_rating'])?.toDouble(),
      totalReviews: json['totalReviews'] ?? json['total_reviews'] ?? 0,
      pricePerNightEur: (json['pricePerNightEur'] ?? json['price_per_night_eur'])?.toDouble(),
      isFree: json['isFree'] ?? json['is_free'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
      distanceKm: (json['distanceKm'] ?? json['distance_km'])?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'country': country,
      'lat': lat,
      'lng': lng,
      'totalSpaces': totalSpaces,
      'hasSecurity': hasSecurity,
      'hasCamera': hasCamera,
      'hasFence': hasFence,
      'hasElectricity': hasElectricity,
      'hasWater': hasWater,
      'hasToilets': hasToilets,
      'hasShowers': hasShowers,
      'hasRestaurant': hasRestaurant,
      'hasShop': hasShop,
      'hasAdblue': hasAdblue,
      'hasWifi': hasWifi,
      'currentOccupancyPct': currentOccupancyPct,
      'lastOccupancyUpdate': lastOccupancyUpdate?.toIso8601String(),
      'avgRating': avgRating,
      'totalReviews': totalReviews,
      'pricePerNightEur': pricePerNightEur,
      'isFree': isFree,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
