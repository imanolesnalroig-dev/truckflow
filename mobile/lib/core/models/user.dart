class User {
  final String id;
  final String email;
  final String displayName;
  final String? language;
  final String? country;
  final bool isActive;
  final int reputationScore;
  final double totalKmDriven;
  final int totalReports;
  final int totalReviews;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.displayName,
    this.language,
    this.country,
    this.isActive = true,
    this.reputationScore = 0,
    this.totalKmDriven = 0,
    this.totalReports = 0,
    this.totalReviews = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] ?? json['display_name'] as String,
      language: json['language'] as String?,
      country: json['country'] as String?,
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      reputationScore: json['reputationScore'] ?? json['reputation_score'] ?? 0,
      totalKmDriven: (json['totalKmDriven'] ?? json['total_km_driven'] ?? 0).toDouble(),
      totalReports: json['totalReports'] ?? json['total_reports'] ?? 0,
      totalReviews: json['totalReviews'] ?? json['total_reviews'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'language': language,
      'country': country,
      'isActive': isActive,
      'reputationScore': reputationScore,
      'totalKmDriven': totalKmDriven,
      'totalReports': totalReports,
      'totalReviews': totalReviews,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? language,
    String? country,
    bool? isActive,
    int? reputationScore,
    double? totalKmDriven,
    int? totalReports,
    int? totalReviews,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      language: language ?? this.language,
      country: country ?? this.country,
      isActive: isActive ?? this.isActive,
      reputationScore: reputationScore ?? this.reputationScore,
      totalKmDriven: totalKmDriven ?? this.totalKmDriven,
      totalReports: totalReports ?? this.totalReports,
      totalReviews: totalReviews ?? this.totalReviews,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
