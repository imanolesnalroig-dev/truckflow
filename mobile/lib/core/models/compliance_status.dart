class ComplianceStatus {
  final DriverStatus status;
  final Duration drivingToday;
  final Duration breakToday;
  final Duration drivingThisWeek;
  final Duration drivingLastTwoWeeks;
  final Duration untilBreakRequired;
  final Duration untilDailyRestRequired;
  final int extendedDaysUsedThisWeek;
  final int reducedRestsUsedThisWeek;
  final DateTime? lastDailyRestEnded;
  final DateTime? lastWeeklyRestEnded;
  final bool isCompliant;
  final List<String> warnings;

  ComplianceStatus({
    required this.status,
    required this.drivingToday,
    required this.breakToday,
    required this.drivingThisWeek,
    required this.drivingLastTwoWeeks,
    required this.untilBreakRequired,
    required this.untilDailyRestRequired,
    this.extendedDaysUsedThisWeek = 0,
    this.reducedRestsUsedThisWeek = 0,
    this.lastDailyRestEnded,
    this.lastWeeklyRestEnded,
    this.isCompliant = true,
    this.warnings = const [],
  });

  // EC 561/2006 limits
  static const maxDrivingPerDayHours = 9;
  static const maxDrivingPerDayExtendedHours = 10;
  static const maxExtendedDaysPerWeek = 2;
  static const maxDrivingPerWeekHours = 56;
  static const maxDrivingPerTwoWeeksHours = 90;
  static const maxDrivingBeforeBreakHours = 4.5;
  static const minBreakMinutes = 45;
  static const minDailyRestHours = 11;
  static const minDailyRestReducedHours = 9;
  static const minWeeklyRestHours = 45;
  static const minWeeklyRestReducedHours = 24;

  double get drivingTodayHours => drivingToday.inMinutes / 60;
  double get breakTodayMinutes => breakToday.inMinutes.toDouble();
  double get drivingThisWeekHours => drivingThisWeek.inMinutes / 60;
  double get drivingLastTwoWeeksHours => drivingLastTwoWeeks.inMinutes / 60;
  double get untilBreakRequiredHours => untilBreakRequired.inMinutes / 60;

  double get dailyDrivingProgress => drivingTodayHours / maxDrivingPerDayHours;
  double get weeklyDrivingProgress => drivingThisWeekHours / maxDrivingPerWeekHours;
  double get biWeeklyDrivingProgress => drivingLastTwoWeeksHours / maxDrivingPerTwoWeeksHours;

  factory ComplianceStatus.fromJson(Map<String, dynamic> json) {
    return ComplianceStatus(
      status: DriverStatus.fromString(json['status']),
      drivingToday: Duration(minutes: json['drivingTodayMinutes'] ?? json['driving_today_minutes'] ?? 0),
      breakToday: Duration(minutes: json['breakTodayMinutes'] ?? json['break_today_minutes'] ?? 0),
      drivingThisWeek: Duration(minutes: json['drivingThisWeekMinutes'] ?? json['driving_this_week_minutes'] ?? 0),
      drivingLastTwoWeeks: Duration(minutes: json['drivingLastTwoWeeksMinutes'] ?? json['driving_last_two_weeks_minutes'] ?? 0),
      untilBreakRequired: Duration(minutes: json['untilBreakRequiredMinutes'] ?? json['until_break_required_minutes'] ?? 270),
      untilDailyRestRequired: Duration(minutes: json['untilDailyRestRequiredMinutes'] ?? json['until_daily_rest_required_minutes'] ?? 540),
      extendedDaysUsedThisWeek: json['extendedDaysUsedThisWeek'] ?? json['extended_days_used_this_week'] ?? 0,
      reducedRestsUsedThisWeek: json['reducedRestsUsedThisWeek'] ?? json['reduced_rests_used_this_week'] ?? 0,
      lastDailyRestEnded: json['lastDailyRestEnded'] != null || json['last_daily_rest_ended'] != null
          ? DateTime.parse(json['lastDailyRestEnded'] ?? json['last_daily_rest_ended'])
          : null,
      lastWeeklyRestEnded: json['lastWeeklyRestEnded'] != null || json['last_weekly_rest_ended'] != null
          ? DateTime.parse(json['lastWeeklyRestEnded'] ?? json['last_weekly_rest_ended'])
          : null,
      isCompliant: json['isCompliant'] ?? json['is_compliant'] ?? true,
      warnings: List<String>.from(json['warnings'] ?? []),
    );
  }

  factory ComplianceStatus.initial() {
    return ComplianceStatus(
      status: DriverStatus.resting,
      drivingToday: Duration.zero,
      breakToday: Duration.zero,
      drivingThisWeek: Duration.zero,
      drivingLastTwoWeeks: Duration.zero,
      untilBreakRequired: const Duration(hours: 4, minutes: 30),
      untilDailyRestRequired: const Duration(hours: 9),
    );
  }
}

enum DriverStatus {
  driving('driving', 'DRIVING'),
  onBreak('on_break', 'ON BREAK'),
  resting('resting', 'RESTING'),
  available('available', 'AVAILABLE');

  final String value;
  final String displayName;
  const DriverStatus(this.value, this.displayName);

  static DriverStatus fromString(String? value) {
    if (value == null) return DriverStatus.resting;
    return DriverStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DriverStatus.resting,
    );
  }
}
