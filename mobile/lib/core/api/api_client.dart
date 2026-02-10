import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(AuthInterceptor(_storage, _dio));
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  Dio get dio => _dio;

  // Auth endpoints
  Future<Response> login(String email, String password) async {
    return _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> register({
    required String email,
    required String password,
    required String displayName,
    String? language,
    String? country,
  }) async {
    return _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'displayName': displayName,
      if (language != null) 'language': language,
      if (country != null) 'country': country,
    });
  }

  Future<Response> getProfile() async {
    return _dio.get('/auth/me');
  }

  // Truck profiles
  Future<Response> getTruckProfiles() async {
    return _dio.get('/trucks');
  }

  Future<Response> createTruckProfile(Map<String, dynamic> data) async {
    return _dio.post('/trucks', data: data);
  }

  Future<Response> updateTruckProfile(String id, Map<String, dynamic> data) async {
    return _dio.put('/trucks/$id', data: data);
  }

  Future<Response> deleteTruckProfile(String id) async {
    return _dio.delete('/trucks/$id');
  }

  // Hazards
  Future<Response> getHazards({
    required double lat,
    required double lng,
    int radiusKm = 50,
  }) async {
    return _dio.get('/hazards', queryParameters: {
      'lat': lat,
      'lng': lng,
      'radiusKm': radiusKm,
    });
  }

  Future<Response> reportHazard(Map<String, dynamic> data) async {
    return _dio.post('/hazards', data: data);
  }

  Future<Response> confirmHazard(String id) async {
    return _dio.post('/hazards/$id/confirm');
  }

  Future<Response> denyHazard(String id) async {
    return _dio.post('/hazards/$id/deny');
  }

  // Locations (warehouses, etc.)
  Future<Response> searchLocations({
    String? query,
    double? lat,
    double? lng,
    int radiusKm = 50,
    String? type,
  }) async {
    return _dio.get('/locations', queryParameters: {
      if (query != null) 'query': query,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      'radiusKm': radiusKm,
      if (type != null) 'type': type,
    });
  }

  Future<Response> getLocation(String id) async {
    return _dio.get('/locations/$id');
  }

  Future<Response> reviewLocation(String id, Map<String, dynamic> review) async {
    return _dio.post('/locations/$id/reviews', data: review);
  }

  // Parking
  Future<Response> searchParking({
    required double lat,
    required double lng,
    int radiusKm = 50,
    bool? free,
    bool? secured,
  }) async {
    return _dio.get('/parking', queryParameters: {
      'lat': lat,
      'lng': lng,
      'radiusKm': radiusKm,
      if (free != null) 'free': free,
      if (secured != null) 'secured': secured,
    });
  }

  // Compliance
  Future<Response> getComplianceStatus() async {
    return _dio.get('/compliance/status');
  }

  Future<Response> startDrivingSession() async {
    return _dio.post('/compliance/session/start');
  }

  Future<Response> endDrivingSession() async {
    return _dio.post('/compliance/session/end');
  }

  Future<Response> startBreak() async {
    return _dio.post('/compliance/break/start');
  }

  Future<Response> endBreak() async {
    return _dio.post('/compliance/break/end');
  }

  // Telemetry
  Future<Response> sendTelemetry(Map<String, dynamic> data) async {
    return _dio.post('/telemetry', data: data);
  }

  // Route planning
  Future<Response> calculateRoute(Map<String, dynamic> routeRequest) async {
    return _dio.post('/route/calculate', data: routeRequest);
  }
}

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  // ignore: unused_field - kept for future token refresh implementation
  final Dio _dio;

  AuthInterceptor(this._storage, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip auth header for login/register
    if (options.path.contains('/auth/login') ||
        options.path.contains('/auth/register')) {
      return handler.next(options);
    }

    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Token expired - try to refresh or logout
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
    }
    handler.next(err);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  factory ApiException.fromDioError(DioException error) {
    String message = 'An error occurred';

    if (error.response?.data is Map) {
      message = error.response?.data['message'] ?? message;
    } else if (error.message != null) {
      message = error.message!;
    }

    return ApiException(
      message: message,
      statusCode: error.response?.statusCode,
      data: error.response?.data,
    );
  }

  @override
  String toString() => message;
}
