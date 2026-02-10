class TruckProfile {
  final String id;
  final String userId;
  final String name;
  final int heightCm;
  final int weightKg;
  final int lengthCm;
  final int widthCm;
  final int axleCount;
  final int axleWeightKg;
  final bool hasTrailer;
  final TrailerType? trailerType;
  final HazmatClass? hazmatClass;
  final EmissionClass? emissionClass;
  final bool isDefault;
  final DateTime createdAt;

  TruckProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.heightCm,
    required this.weightKg,
    required this.lengthCm,
    this.widthCm = 260,
    this.axleCount = 5,
    this.axleWeightKg = 10000,
    this.hasTrailer = true,
    this.trailerType,
    this.hazmatClass,
    this.emissionClass,
    this.isDefault = false,
    required this.createdAt,
  });

  // Convenience getters in meters
  double get heightM => heightCm / 100;
  double get weightT => weightKg / 1000;
  double get lengthM => lengthCm / 100;
  double get widthM => widthCm / 100;

  factory TruckProfile.fromJson(Map<String, dynamic> json) {
    return TruckProfile(
      id: json['id'] as String,
      userId: json['userId'] ?? json['user_id'] as String,
      name: json['name'] as String,
      heightCm: json['heightCm'] ?? json['height_cm'] as int,
      weightKg: json['weightKg'] ?? json['weight_kg'] as int,
      lengthCm: json['lengthCm'] ?? json['length_cm'] as int,
      widthCm: json['widthCm'] ?? json['width_cm'] ?? 260,
      axleCount: json['axleCount'] ?? json['axle_count'] ?? 5,
      axleWeightKg: json['axleWeightKg'] ?? json['axle_weight_kg'] ?? 10000,
      hasTrailer: json['hasTrailer'] ?? json['has_trailer'] ?? true,
      trailerType: json['trailerType'] != null || json['trailer_type'] != null
          ? TrailerType.fromString(json['trailerType'] ?? json['trailer_type'])
          : null,
      hazmatClass: json['hazmatClass'] != null || json['hazmat_class'] != null
          ? HazmatClass.fromString(json['hazmatClass'] ?? json['hazmat_class'])
          : null,
      emissionClass: json['emissionClass'] != null || json['emission_class'] != null
          ? EmissionClass.fromString(json['emissionClass'] ?? json['emission_class'])
          : null,
      isDefault: json['isDefault'] ?? json['is_default'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'lengthCm': lengthCm,
      'widthCm': widthCm,
      'axleCount': axleCount,
      'axleWeightKg': axleWeightKg,
      'hasTrailer': hasTrailer,
      'trailerType': trailerType?.value,
      'hazmatClass': hazmatClass?.value,
      'emissionClass': emissionClass?.value,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  TruckProfile copyWith({
    String? id,
    String? userId,
    String? name,
    int? heightCm,
    int? weightKg,
    int? lengthCm,
    int? widthCm,
    int? axleCount,
    int? axleWeightKg,
    bool? hasTrailer,
    TrailerType? trailerType,
    HazmatClass? hazmatClass,
    EmissionClass? emissionClass,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return TruckProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      lengthCm: lengthCm ?? this.lengthCm,
      widthCm: widthCm ?? this.widthCm,
      axleCount: axleCount ?? this.axleCount,
      axleWeightKg: axleWeightKg ?? this.axleWeightKg,
      hasTrailer: hasTrailer ?? this.hasTrailer,
      trailerType: trailerType ?? this.trailerType,
      hazmatClass: hazmatClass ?? this.hazmatClass,
      emissionClass: emissionClass ?? this.emissionClass,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum TrailerType {
  tilt('tilt', 'Tilt/Curtainsider'),
  reefer('reefer', 'Refrigerated'),
  mega('mega', 'Mega Trailer'),
  tank('tank', 'Tank'),
  flatbed('flatbed', 'Flatbed'),
  container('container', 'Container'),
  other('other', 'Other');

  final String value;
  final String displayName;
  const TrailerType(this.value, this.displayName);

  static TrailerType? fromString(String? value) {
    if (value == null) return null;
    return TrailerType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TrailerType.other,
    );
  }
}

enum HazmatClass {
  class1('1', 'Explosives'),
  class2('2', 'Gases'),
  class3('3', 'Flammable Liquids'),
  class4('4', 'Flammable Solids'),
  class5('5', 'Oxidizers'),
  class6('6', 'Toxic Substances'),
  class7('7', 'Radioactive'),
  class8('8', 'Corrosives'),
  class9('9', 'Misc Dangerous');

  final String value;
  final String displayName;
  const HazmatClass(this.value, this.displayName);

  static HazmatClass? fromString(String? value) {
    if (value == null) return null;
    return HazmatClass.values.firstWhere(
      (e) => e.value == value,
      orElse: () => HazmatClass.class9,
    );
  }
}

enum EmissionClass {
  euro3('euro3', 'Euro 3'),
  euro4('euro4', 'Euro 4'),
  euro5('euro5', 'Euro 5'),
  euro6('euro6', 'Euro 6'),
  euro6d('euro6d', 'Euro 6d');

  final String value;
  final String displayName;
  const EmissionClass(this.value, this.displayName);

  static EmissionClass? fromString(String? value) {
    if (value == null) return null;
    return EmissionClass.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EmissionClass.euro6,
    );
  }
}
