import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('pl'),
    Locale('de'),
    Locale('ro'),
    Locale('es'),
    Locale('bg'),
    Locale('lt'),
    Locale('tr'),
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appName': 'TruckFlow',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'ok': 'OK',
      'error': 'Error',
      'loading': 'Loading...',
      'map': 'Map',
      'parking': 'Parking',
      'drivingTime': 'Time',
      'profile': 'Profile',
      'getStarted': 'Get Started',
      'next': 'Next',
      'skip': 'Skip',
      'alreadyHaveAccount': 'Already have an account? Sign in',
      'signIn': 'Sign In',
      'signUp': 'Sign Up',
      'email': 'Email',
      'password': 'Password',
      'forgotPassword': 'Forgot password?',
      'continueWithGoogle': 'Continue with Google',
      'whereTo': 'Where to?',
      'reportHazard': 'Report Hazard',
      'untilBreak': 'until break',
      'police': 'Police',
      'camera': 'Camera',
      'accident': 'Accident',
      'roadWorks': 'Road Works',
      'closed': 'Closed',
      'hazard': 'Hazard',
      'weather': 'Weather',
      'border': 'Border',
      'truckParking': 'Truck Parking',
      'free': 'Free',
      'secured': 'Secured',
      'available': 'Available',
      'addParking': 'Add Parking',
      'drivingTimeTitle': 'Driving Time',
      'currentStatus': 'Current Status',
      'driving': 'DRIVING',
      'resting': 'RESTING',
      'onBreak': 'ON BREAK',
      'startBreak': 'Start Break',
      'startRest': 'Start Rest',
      'dailyLimits': 'Daily Limits',
      'weeklyLimits': 'Weekly Limits',
      'myVehicle': 'My Vehicle',
      'tripHistory': 'Trip History',
      'savedPlaces': 'Saved Places',
      'offlineMaps': 'Offline Maps',
      'language': 'Language',
      'appearance': 'Appearance',
      'notifications': 'Notifications',
      'helpSupport': 'Help & Support',
      'about': 'About TruckFlow',
      'signOut': 'Sign Out',
    },
    'pl': {
      'appName': 'TruckFlow',
      'cancel': 'Anuluj',
      'save': 'Zapisz',
      'delete': 'Usuń',
      'edit': 'Edytuj',
      'ok': 'OK',
      'error': 'Błąd',
      'loading': 'Ładowanie...',
      'map': 'Mapa',
      'parking': 'Parking',
      'drivingTime': 'Czas',
      'profile': 'Profil',
      'getStarted': 'Rozpocznij',
      'next': 'Dalej',
      'skip': 'Pomiń',
      'alreadyHaveAccount': 'Masz już konto? Zaloguj się',
      'signIn': 'Zaloguj się',
      'signUp': 'Zarejestruj się',
      'email': 'Email',
      'password': 'Hasło',
      'forgotPassword': 'Zapomniałeś hasła?',
      'continueWithGoogle': 'Kontynuuj z Google',
      'whereTo': 'Dokąd?',
      'reportHazard': 'Zgłoś zagrożenie',
      'untilBreak': 'do przerwy',
      'police': 'Policja',
      'camera': 'Fotoradar',
      'accident': 'Wypadek',
      'roadWorks': 'Roboty drogowe',
      'closed': 'Zamknięte',
      'hazard': 'Zagrożenie',
      'weather': 'Pogoda',
      'border': 'Granica',
      'truckParking': 'Parking dla ciężarówek',
      'free': 'Bezpłatny',
      'secured': 'Strzeżony',
      'available': 'Dostępne',
      'addParking': 'Dodaj parking',
      'drivingTimeTitle': 'Czas jazdy',
      'currentStatus': 'Aktualny status',
      'driving': 'JAZDA',
      'resting': 'ODPOCZYNEK',
      'onBreak': 'PRZERWA',
      'startBreak': 'Rozpocznij przerwę',
      'startRest': 'Rozpocznij odpoczynek',
      'dailyLimits': 'Limity dzienne',
      'weeklyLimits': 'Limity tygodniowe',
      'myVehicle': 'Mój pojazd',
      'tripHistory': 'Historia tras',
      'savedPlaces': 'Zapisane miejsca',
      'offlineMaps': 'Mapy offline',
      'language': 'Język',
      'appearance': 'Wygląd',
      'notifications': 'Powiadomienia',
      'helpSupport': 'Pomoc i wsparcie',
      'about': 'O TruckFlow',
      'signOut': 'Wyloguj się',
    },
    'de': {
      'appName': 'TruckFlow',
      'cancel': 'Abbrechen',
      'save': 'Speichern',
      'delete': 'Löschen',
      'edit': 'Bearbeiten',
      'ok': 'OK',
      'error': 'Fehler',
      'loading': 'Laden...',
      'map': 'Karte',
      'parking': 'Parken',
      'drivingTime': 'Zeit',
      'profile': 'Profil',
      'getStarted': 'Loslegen',
      'next': 'Weiter',
      'skip': 'Überspringen',
      'alreadyHaveAccount': 'Haben Sie bereits ein Konto? Anmelden',
      'signIn': 'Anmelden',
      'signUp': 'Registrieren',
      'email': 'E-Mail',
      'password': 'Passwort',
      'forgotPassword': 'Passwort vergessen?',
      'continueWithGoogle': 'Mit Google fortfahren',
      'whereTo': 'Wohin?',
      'reportHazard': 'Gefahr melden',
      'untilBreak': 'bis zur Pause',
      'police': 'Polizei',
      'camera': 'Blitzer',
      'accident': 'Unfall',
      'roadWorks': 'Baustelle',
      'closed': 'Gesperrt',
      'hazard': 'Gefahr',
      'weather': 'Wetter',
      'border': 'Grenze',
      'truckParking': 'LKW-Parkplatz',
      'free': 'Kostenlos',
      'secured': 'Bewacht',
      'available': 'Verfügbar',
      'addParking': 'Parkplatz hinzufügen',
      'drivingTimeTitle': 'Fahrzeit',
      'currentStatus': 'Aktueller Status',
      'driving': 'FAHREN',
      'resting': 'RUHEZEIT',
      'onBreak': 'PAUSE',
      'startBreak': 'Pause starten',
      'startRest': 'Ruhezeit starten',
      'dailyLimits': 'Tageslimits',
      'weeklyLimits': 'Wochenlimits',
      'myVehicle': 'Mein Fahrzeug',
      'tripHistory': 'Fahrtverlauf',
      'savedPlaces': 'Gespeicherte Orte',
      'offlineMaps': 'Offline-Karten',
      'language': 'Sprache',
      'appearance': 'Erscheinungsbild',
      'notifications': 'Benachrichtigungen',
      'helpSupport': 'Hilfe & Support',
      'about': 'Über TruckFlow',
      'signOut': 'Abmelden',
    },
    'ro': {
      'appName': 'TruckFlow',
      'cancel': 'Anulează',
      'save': 'Salvează',
      'delete': 'Șterge',
      'edit': 'Editează',
      'ok': 'OK',
      'error': 'Eroare',
      'loading': 'Se încarcă...',
      'map': 'Hartă',
      'parking': 'Parcare',
      'drivingTime': 'Timp',
      'profile': 'Profil',
      'signOut': 'Deconectare',
    },
    'es': {
      'appName': 'TruckFlow',
      'cancel': 'Cancelar',
      'save': 'Guardar',
      'delete': 'Eliminar',
      'edit': 'Editar',
      'ok': 'OK',
      'error': 'Error',
      'loading': 'Cargando...',
      'map': 'Mapa',
      'parking': 'Aparcamiento',
      'drivingTime': 'Tiempo',
      'profile': 'Perfil',
      'signOut': 'Cerrar sesión',
    },
  };

  String _translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  // Common
  String get appName => _translate('appName');
  String get cancel => _translate('cancel');
  String get save => _translate('save');
  String get delete => _translate('delete');
  String get edit => _translate('edit');
  String get ok => _translate('ok');
  String get error => _translate('error');
  String get loading => _translate('loading');

  // Navigation
  String get map => _translate('map');
  String get parking => _translate('parking');
  String get drivingTime => _translate('drivingTime');
  String get profile => _translate('profile');

  // Onboarding
  String get getStarted => _translate('getStarted');
  String get next => _translate('next');
  String get skip => _translate('skip');
  String get alreadyHaveAccount => _translate('alreadyHaveAccount');

  // Auth
  String get signIn => _translate('signIn');
  String get signUp => _translate('signUp');
  String get email => _translate('email');
  String get password => _translate('password');
  String get forgotPassword => _translate('forgotPassword');
  String get continueWithGoogle => _translate('continueWithGoogle');

  // Map
  String get whereTo => _translate('whereTo');
  String get reportHazard => _translate('reportHazard');
  String get untilBreak => _translate('untilBreak');

  // Hazards
  String get police => _translate('police');
  String get camera => _translate('camera');
  String get accident => _translate('accident');
  String get roadWorks => _translate('roadWorks');
  String get closed => _translate('closed');
  String get hazard => _translate('hazard');
  String get weather => _translate('weather');
  String get border => _translate('border');

  // Parking
  String get truckParking => _translate('truckParking');
  String get free => _translate('free');
  String get secured => _translate('secured');
  String get available => _translate('available');
  String get addParking => _translate('addParking');

  // Compliance
  String get drivingTimeTitle => _translate('drivingTimeTitle');
  String get currentStatus => _translate('currentStatus');
  String get driving => _translate('driving');
  String get resting => _translate('resting');
  String get onBreak => _translate('onBreak');
  String get startBreak => _translate('startBreak');
  String get startRest => _translate('startRest');
  String get dailyLimits => _translate('dailyLimits');
  String get weeklyLimits => _translate('weeklyLimits');

  // Profile
  String get myVehicle => _translate('myVehicle');
  String get tripHistory => _translate('tripHistory');
  String get savedPlaces => _translate('savedPlaces');
  String get offlineMaps => _translate('offlineMaps');
  String get language => _translate('language');
  String get appearance => _translate('appearance');
  String get notifications => _translate('notifications');
  String get helpSupport => _translate('helpSupport');
  String get about => _translate('about');
  String get signOut => _translate('signOut');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .map((l) => l.languageCode)
        .contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
