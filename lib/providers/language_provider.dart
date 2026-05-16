// ============================================================
// RailGuide — Language Provider
// providers/language_provider.dart
// ============================================================

import 'package:flutter/material.dart';

/// Manages the active locale for the application.
/// Supported: English (en), Hindi (hi), Kannada (kn).
class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;

  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('hi'), // Hindi
    Locale('kn'), // Kannada
  ];

  static const Map<String, String> languageLabels = {
    'en': 'English',
    'hi': 'हिन्दी',
    'kn': 'ಕನ್ನಡ',
  };

  String get currentLanguageLabel =>
      languageLabels[_currentLocale.languageCode] ?? 'English';

  void setLanguage(String languageCode) {
    _currentLocale = Locale(languageCode);
    notifyListeners();
  }

  // ── Localised strings ─────────────────────────────────────
  // A lightweight in-code i18n map. For production, use
  // flutter_localizations + ARB files.
  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'app_title': 'RailGuide',
      'home': 'Home',
      'navigate': 'Navigate',
      'support': 'Support',
      'scan_qr': 'Scan QR Code',
      'select_destination': 'Select Destination',
      'find_path': 'Find Shortest Path',
      'train_info': 'Train Information',
      'platform': 'Platform',
      'arrival': 'Arrival',
      'on_time': 'On Time',
      'delayed': 'Delayed',
      'shortest_path': 'Shortest Path',
      'step_instructions': 'Step-by-Step',
      'report_issue': 'Report an Issue',
      'help_center': 'Help Center',
      'emergency': 'Emergency Contacts',
      'login': 'Login',
      'signup': 'Sign Up',
      'guest': 'Continue as Guest',
      'email': 'Email Address',
      'password': 'Password',
      'start_node': 'Start Location',
      'not_scanned': 'Not scanned yet',
    },
    'hi': {
      'app_title': 'रेलगाइड',
      'home': 'होम',
      'navigate': 'नेविगेट',
      'support': 'सहायता',
      'scan_qr': 'QR कोड स्कैन करें',
      'select_destination': 'गंतव्य चुनें',
      'find_path': 'सबसे छोटा रास्ता खोजें',
      'train_info': 'ट्रेन जानकारी',
      'platform': 'प्लेटफॉर्म',
      'arrival': 'आगमन',
      'on_time': 'समय पर',
      'delayed': 'विलंबित',
      'shortest_path': 'सबसे छोटा रास्ता',
      'step_instructions': 'कदम-दर-कदम',
      'report_issue': 'समस्या रिपोर्ट करें',
      'help_center': 'सहायता केंद्र',
      'emergency': 'आपातकालीन संपर्क',
      'login': 'लॉग इन',
      'signup': 'साइन अप',
      'guest': 'अतिथि के रूप में जारी रखें',
      'email': 'ईमेल पता',
      'password': 'पासवर्ड',
      'start_node': 'प्रारंभ स्थान',
      'not_scanned': 'अभी तक स्कैन नहीं किया',
    },
    'kn': {
      'app_title': 'ರೈಲ್‌ಗೈಡ್',
      'home': 'ಮನೆ',
      'navigate': 'ನ್ಯಾವಿಗೇಟ್',
      'support': 'ಬೆಂಬಲ',
      'scan_qr': 'QR ಕೋಡ್ ಸ್ಕ್ಯಾನ್ ಮಾಡಿ',
      'select_destination': 'ಗಮ್ಯಸ್ಥಾನ ಆಯ್ಕೆಮಾಡಿ',
      'find_path': 'ಅತ್ಯಂತ ಚಿಕ್ಕ ಮಾರ್ಗ ಹುಡುಕಿ',
      'train_info': 'ರೈಲು ಮಾಹಿತಿ',
      'platform': 'ಪ್ಲಾಟ್‌ಫಾರ್ಮ್',
      'arrival': 'ಆಗಮನ',
      'on_time': 'ಸಮಯಕ್ಕೆ',
      'delayed': 'ವಿಳಂಬ',
      'shortest_path': 'ಅತ್ಯಂತ ಚಿಕ್ಕ ಮಾರ್ಗ',
      'step_instructions': 'ಹಂತ-ಹಂತ',
      'report_issue': 'ಸಮಸ್ಯೆ ವರದಿ ಮಾಡಿ',
      'help_center': 'ಸಹಾಯ ಕೇಂದ್ರ',
      'emergency': 'ತುರ್ತು ಸಂಪರ್ಕಗಳು',
      'login': 'ಲಾಗಿನ್',
      'signup': 'ಸೈನ್ ಅಪ್',
      'guest': 'ಅತಿಥಿಯಾಗಿ ಮುಂದುವರಿಯಿರಿ',
      'email': 'ಇಮೇಲ್ ವಿಳಾಸ',
      'password': 'ಪಾಸ್‌ವರ್ಡ್',
      'start_node': 'ಪ್ರಾರಂಭ ಸ್ಥಳ',
      'not_scanned': 'ಇನ್ನೂ ಸ್ಕ್ಯಾನ್ ಮಾಡಿಲ್ಲ',
    },
  };

  /// Get a localised string by key
  String t(String key) {
    return _strings[_currentLocale.languageCode]?[key] ??
        _strings['en']?[key] ??
        key;
  }
}