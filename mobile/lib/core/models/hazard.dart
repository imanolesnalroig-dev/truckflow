class Hazard {
  final String id;
  final String userId;
  final double lat;
  final double lng;
  final HazardType type;
  final String? subtype;
  final String? description;
  final HazardSeverity severity;
  final int? direction;
  final bool isActive;
  final int confirmedCount;
  final int deniedCount;
  final DateTime expiresAt;
  final DateTime createdAt;

  Hazard({
    required this.id,
    required this.userId,
    required this.lat,
    required this.lng,
    required this.type,
    this.subtype,
    this.description,
    this.severity = HazardSeverity.medium,
    this.direction,
    this.isActive = true,
    this.confirmedCount = 0,
    this.deniedCount = 0,
    required this.expiresAt,
    required this.createdAt,
  });

  factory Hazard.fromJson(Map<String, dynamic> json) {
    return Hazard(
      id: json['id'] as String,
      userId: json['userId'] ?? json['user_id'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      type: HazardType.fromString(json['hazardType'] ?? json['hazard_type']),
      subtype: json['subtype'] as String?,
      description: json['description'] as String?,
      severity: HazardSeverity.fromString(json['severity']),
      direction: json['direction'] as int?,
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      confirmedCount: json['confirmedCount'] ?? json['confirmed_count'] ?? 0,
      deniedCount: json['deniedCount'] ?? json['denied_count'] ?? 0,
      expiresAt: DateTime.parse(json['expiresAt'] ?? json['expires_at']),
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'lat': lat,
      'lng': lng,
      'hazardType': type.value,
      'subtype': subtype,
      'description': description,
      'severity': severity.value,
      'direction': direction,
      'isActive': isActive,
      'confirmedCount': confirmedCount,
      'deniedCount': deniedCount,
      'expiresAt': expiresAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  int get reliability {
    final total = confirmedCount + deniedCount;
    if (total == 0) return 50;
    return ((confirmedCount / total) * 100).round();
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

enum HazardType {
  police('police', 'Police', '👮'),
  camera('camera', 'Speed Camera', '📸'),
  accident('accident', 'Accident', '🚗'),
  roadWorks('road_works', 'Road Works', '🚧'),
  roadClosure('road_closure', 'Road Closed', '🚫'),
  roadHazard('road_hazard', 'Road Hazard', '⚠️'),
  weather('weather', 'Bad Weather', '🌧️'),
  borderDelay('border_delay', 'Border Delay', '🛂');

  final String value;
  final String displayName;
  final String emoji;
  const HazardType(this.value, this.displayName, this.emoji);

  static HazardType fromString(String value) {
    return HazardType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => HazardType.roadHazard,
    );
  }
}

enum HazardSeverity {
  low('low'),
  medium('medium'),
  high('high'),
  critical('critical');

  final String value;
  const HazardSeverity(this.value);

  static HazardSeverity fromString(String? value) {
    if (value == null) return HazardSeverity.medium;
    return HazardSeverity.values.firstWhere(
      (e) => e.value == value,
      orElse: () => HazardSeverity.medium,
    );
  }
}
