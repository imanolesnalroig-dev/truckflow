// Placeholder for Flutter localization
// Full implementation would use flutter_localizations and intl packages
// with .arb files for each supported language

class AppLocalizations {
  final String locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(String locale) {
    return AppLocalizations(locale);
  }

  // Common
  String get appName => _localizedValues[locale]?['appName'] ?? 'TruckFlow';
  String get cancel => _localizedValues[locale]?['cancel'] ?? 'Cancel';
  String get save => _localizedValues[locale]?['save'] ?? 'Save';
  String get delete => _localizedValues[locale]?['delete'] ?? 'Delete';
  String get edit => _localizedValues[locale]?['edit'] ?? 'Edit';
  String get ok => _localizedValues[locale]?['ok'] ?? 'OK';
  String get error => _localizedValues[locale]?['error'] ?? 'Error';
  String get loading => _localizedValues[locale]?['loading'] ?? 'Loading...';

  // Navigation
  String get map => _localizedValues[locale]?['map'] ?? 'Map';
  String get parking => _localizedValues[locale]?['parking'] ?? 'Parking';
  String get drivingTime => _localizedValues[locale]?['drivingTime'] ?? 'Time';
  String get profile => _localizedValues[locale]?['profile'] ?? 'Profile';

  // Onboarding
  String get getStarted => _localizedValues[locale]?['getStarted'] ?? 'Get Started';
  String get next => _localizedValues[locale]?['next'] ?? 'Next';
  String get skip => _localizedValues[locale]?['skip'] ?? 'Skip';
  String get alreadyHaveAccount => _localizedValues[locale]?['alreadyHaveAccount'] ?? 'Already have an account? Sign in';

  // Auth
  String get signIn => _localizedValues[locale]?['signIn'] ?? 'Sign In';
  String get signUp => _localizedValues[locale]?['signUp'] ?? 'Sign Up';
  String get email => _localizedValues[locale]?['email'] ?? 'Email';
  String get password => _localizedValues[locale]?['password'] ?? 'Password';
  String get forgotPassword => _localizedValues[locale]?['forgotPassword'] ?? 'Forgot password?';
  String get continueWithGoogle => _localizedValues[locale]?['continueWithGoogle'] ?? 'Continue with Google';

  // Map
  String get whereTo => _localizedValues[locale]?['whereTo'] ?? 'Where to?';
  String get reportHazard => _localizedValues[locale]?['reportHazard'] ?? 'Report Hazard';
  String get untilBreak => _localizedValues[locale]?['untilBreak'] ?? 'until break';

  // Hazards
  String get police => _localizedValues[locale]?['police'] ?? 'Police';
  String get camera => _localizedValues[locale]?['camera'] ?? 'Camera';
  String get accident => _localizedValues[locale]?['accident'] ?? 'Accident';
  String get roadWorks => _localizedValues[locale]?['roadWorks'] ?? 'Road Works';
  String get closed => _localizedValues[locale]?['closed'] ?? 'Closed';
  String get hazard => _localizedValues[locale]?['hazard'] ?? 'Hazard';
  String get weather => _localizedValues[locale]?['weather'] ?? 'Weather';
  String get border => _localizedValues[locale]?['border'] ?? 'Border';

  // Parking
  String get truckParking => _localizedValues[locale]?['truckParking'] ?? 'Truck Parking';
  String get free => _localizedValues[locale]?['free'] ?? 'Free';
  String get secured => _localizedValues[locale]?['secured'] ?? 'Secured';
  String get available => _localizedValues[locale]?['available'] ?? 'Available';
  String get addParking => _localizedValues[locale]?['addParking'] ?? 'Add Parking';

  // Compliance
  String get drivingTimeTitle => _localizedValues[locale]?['drivingTimeTitle'] ?? 'Driving Time';
  String get currentStatus => _localizedValues[locale]?['currentStatus'] ?? 'Current Status';
  String get driving => _localizedValues[locale]?['driving'] ?? 'DRIVING';
  String get resting => _localizedValues[locale]?['resting'] ?? 'RESTING';
  String get onBreak => _localizedValues[locale]?['onBreak'] ?? 'ON BREAK';
  String get startBreak => _localizedValues[locale]?['startBreak'] ?? 'Start Break';
  String get startRest => _localizedValues[locale]?['startRest'] ?? 'Start Rest';
  String get dailyLimits => _localizedValues[locale]?['dailyLimits'] ?? 'Daily Limits';
  String get weeklyLimits => _localizedValues[locale]?['weeklyLimits'] ?? 'Weekly Limits';

  // Profile
  String get myVehicle => _localizedValues[locale]?['myVehicle'] ?? 'My Vehicle';
  String get tripHistory => _localizedValues[locale]?['tripHistory'] ?? 'Trip History';
  String get savedPlaces => _localizedValues[locale]?['savedPlaces'] ?? 'Saved Places';
  String get offlineMaps => _localizedValues[locale]?['offlineMaps'] ?? 'Offline Maps';
  String get language => _localizedValues[locale]?['language'] ?? 'Language';
  String get appearance => _localizedValues[locale]?['appearance'] ?? 'Appearance';
  String get notifications => _localizedValues[locale]?['notifications'] ?? 'Notifications';
  String get helpSupport => _localizedValues[locale]?['helpSupport'] ?? 'Help & Support';
  String get about => _localizedValues[locale]?['about'] ?? 'About TruckFlow';
  String get signOut => _localizedValues[locale]?['signOut'] ?? 'Sign Out';

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appName': 'TruckFlow',
      'cancel': 'Cancel',
      'save': 'Save',
      'map': 'Map',
      'parking': 'Parking',
      'drivingTime': 'Time',
      'profile': 'Profile',
    },
    'pl': {
      'appName': 'TruckFlow',
      'cancel': 'Anuluj',
      'save': 'Zapisz',
      'map': 'Mapa',
      'parking': 'Parking',
      'drivingTime': 'Czas',
      'profile': 'Profil',
      'signIn': 'Zaloguj się',
      'signOut': 'Wyloguj się',
      'email': 'Email',
      'password': 'Hasło',
    },
    'de': {
      'appName': 'TruckFlow',
      'cancel': 'Abbrechen',
      'save': 'Speichern',
      'map': 'Karte',
      'parking': 'Parken',
      'drivingTime': 'Zeit',
      'profile': 'Profil',
      'signIn': 'Anmelden',
      'signOut': 'Abmelden',
    },
    'ro': {
      'appName': 'TruckFlow',
      'cancel': 'Anulează',
      'save': 'Salvează',
      'map': 'Hartă',
      'parking': 'Parcare',
      'drivingTime': 'Timp',
      'profile': 'Profil',
    },
    'es': {
      'appName': 'TruckFlow',
      'cancel': 'Cancelar',
      'save': 'Guardar',
      'map': 'Mapa',
      'parking': 'Aparcamiento',
      'drivingTime': 'Tiempo',
      'profile': 'Perfil',
    },
  };

  static const List<String> supportedLocales = ['en', 'pl', 'de', 'ro', 'es', 'bg', 'lt', 'tr'];
}
