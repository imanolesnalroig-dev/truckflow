import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

/// Location detail model
class LocationDetail {
  final String id;
  final String name;
  final String? address;
  final String locationType;
  final double lat;
  final double lng;
  final int? avgWaitingTimeMin;
  final double? avgRating;
  final int totalReviews;
  final String? aiSummary;
  final DateTime? aiSummaryUpdatedAt;

  LocationDetail({
    required this.id,
    required this.name,
    this.address,
    required this.locationType,
    required this.lat,
    required this.lng,
    this.avgWaitingTimeMin,
    this.avgRating,
    this.totalReviews = 0,
    this.aiSummary,
    this.aiSummaryUpdatedAt,
  });

  factory LocationDetail.fromJson(Map<String, dynamic> json) {
    return LocationDetail(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      locationType: json['location_type'] ?? json['locationType'] ?? 'warehouse',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      avgWaitingTimeMin: json['avg_waiting_time_min'] ?? json['avgWaitingTimeMin'],
      avgRating: (json['avg_rating'] ?? json['avgRating'])?.toDouble(),
      totalReviews: json['total_reviews'] ?? json['totalReviews'] ?? 0,
      aiSummary: json['ai_summary'] ?? json['aiSummary'],
      aiSummaryUpdatedAt: json['ai_summary_updated_at'] != null
          ? DateTime.parse(json['ai_summary_updated_at'])
          : null,
    );
  }
}

/// Location review model
class LocationReview {
  final String id;
  final int overallRating;
  final int? waitingTimeRating;
  final int? accessRating;
  final int? staffRating;
  final int? facilitiesRating;
  final int? actualWaitingTimeMin;
  final bool? megaTrailerOk;
  final bool? hasTruckParking;
  final bool? hasToilets;
  final bool? hasWater;
  final bool? requiresPpe;
  final String? ppeDetails;
  final String? comment;
  final DateTime createdAt;
  final String? visitDate;
  final String? reviewerName;
  final String? reviewerCountry;

  LocationReview({
    required this.id,
    required this.overallRating,
    this.waitingTimeRating,
    this.accessRating,
    this.staffRating,
    this.facilitiesRating,
    this.actualWaitingTimeMin,
    this.megaTrailerOk,
    this.hasTruckParking,
    this.hasToilets,
    this.hasWater,
    this.requiresPpe,
    this.ppeDetails,
    this.comment,
    required this.createdAt,
    this.visitDate,
    this.reviewerName,
    this.reviewerCountry,
  });

  factory LocationReview.fromJson(Map<String, dynamic> json) {
    return LocationReview(
      id: json['id'] as String,
      overallRating: json['overall_rating'] ?? json['overallRating'] ?? 3,
      waitingTimeRating: json['waiting_time_rating'] ?? json['waitingTimeRating'],
      accessRating: json['access_rating'] ?? json['accessRating'],
      staffRating: json['staff_rating'] ?? json['staffRating'],
      facilitiesRating: json['facilities_rating'] ?? json['facilitiesRating'],
      actualWaitingTimeMin: json['actual_waiting_time_min'] ?? json['actualWaitingTimeMin'],
      megaTrailerOk: json['mega_trailer_ok'] ?? json['megaTrailerOk'],
      hasTruckParking: json['has_truck_parking'] ?? json['hasTruckParking'],
      hasToilets: json['has_toilets'] ?? json['hasToilets'],
      hasWater: json['has_water'] ?? json['hasWater'],
      requiresPpe: json['requires_ppe'] ?? json['requiresPpe'],
      ppeDetails: json['ppe_details'] ?? json['ppeDetails'],
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt']),
      visitDate: json['visit_date'] ?? json['visitDate'],
      reviewerName: json['reviewer_name'] ?? json['reviewerName'],
      reviewerCountry: json['reviewer_country'] ?? json['reviewerCountry'],
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 30) {
      return '${diff.inDays ~/ 30} months ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} days ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hours ago';
    } else {
      return 'Just now';
    }
  }
}

/// Provider for fetching location details
final locationDetailProvider = FutureProvider.family<LocationDetail?, String>((ref, locationId) async {
  final apiClient = ref.read(apiClientProvider);

  try {
    final response = await apiClient.get('/api/locations/$locationId');
    if (response.data != null && response.data['location'] != null) {
      return LocationDetail.fromJson(response.data['location']);
    }
    return null;
  } catch (e) {
    return null;
  }
});

/// Provider for fetching location reviews
final locationReviewsProvider = FutureProvider.family<List<LocationReview>, String>((ref, locationId) async {
  final apiClient = ref.read(apiClientProvider);

  try {
    final response = await apiClient.get('/api/locations/$locationId/reviews');
    if (response.data != null && response.data['reviews'] != null) {
      return (response.data['reviews'] as List)
          .map((r) => LocationReview.fromJson(r))
          .toList();
    }
    return [];
  } catch (e) {
    return [];
  }
});

/// Provider for fetching AI summary
final locationAiSummaryProvider = FutureProvider.family<String?, String>((ref, locationId) async {
  final apiClient = ref.read(apiClientProvider);

  try {
    final response = await apiClient.get('/api/locations/$locationId/summary');
    if (response.data != null) {
      return response.data['summary'] as String?;
    }
    return null;
  } catch (e) {
    return null;
  }
});
