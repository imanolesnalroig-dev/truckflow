import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/map/screens/main_map_screen.dart';
import '../features/routing/screens/route_planning_screen.dart';
import '../features/compliance/screens/driving_time_dashboard.dart';
import '../features/parking/screens/parking_screen.dart';
import '../features/locations/screens/location_detail_screen.dart';
import '../features/profile/screens/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainMapScreen(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: '/route',
            builder: (context, state) => const RoutePlanningScreen(),
          ),
          GoRoute(
            path: '/compliance',
            builder: (context, state) => const DrivingTimeDashboard(),
          ),
          GoRoute(
            path: '/parking',
            builder: (context, state) => const ParkingScreen(),
          ),
          GoRoute(
            path: '/location/:id',
            builder: (context, state) => LocationDetailScreen(
              locationId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
