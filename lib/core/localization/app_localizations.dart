import 'package:flutter/material.dart';

/// Classe pour gérer les traductions de l'application
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const List<Locale> supportedLocales = [
    Locale('fr', ''), // Français
    Locale('en', ''), // Anglais
    Locale('fon', ''), // Fon
    Locale('yo', ''), // Yoruba
    Locale('guw', ''), // Goun
  ];

  // Traductions
  String get appName {
    switch (locale.languageCode) {
      case 'en':
        return 'Cotonou Geolocation';
      case 'fon':
        return 'Cotonou Gbɛtɔnɔ';
      case 'yo':
        return 'Cotonou Ipilẹ';
      case 'guw':
        return 'Cotonou Gbɛtɔnɔ';
      default:
        return 'Géolocalisation Cotonou';
    }
  }

  String get language {
    switch (locale.languageCode) {
      case 'en':
        return 'Language';
      case 'fon':
        return 'Gle';
      case 'yo':
        return 'Èdè';
      case 'guw':
        return 'Gle';
      default:
        return 'Langue';
    }
  }

  String get french {
    switch (locale.languageCode) {
      case 'en':
        return 'French';
      case 'fon':
        return 'Francɛ';
      case 'yo':
        return 'Faranse';
      case 'guw':
        return 'Francɛ';
      default:
        return 'Français';
    }
  }

  String get english {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'fon':
        return 'Glejis';
      case 'yo':
        return 'Gẹẹsi';
      case 'guw':
        return 'Glejis';
      default:
        return 'Anglais';
    }
  }

  String get fon {
    switch (locale.languageCode) {
      case 'en':
        return 'Fon';
      case 'fon':
        return 'Fɔngbe';
      case 'yo':
        return 'Fọn';
      case 'guw':
        return 'Fɔngbe';
      default:
        return 'Fon';
    }
  }

  String get yoruba {
    switch (locale.languageCode) {
      case 'en':
        return 'Yoruba';
      case 'fon':
        return 'Yorubagbe';
      case 'yo':
        return 'Yorùbá';
      case 'guw':
        return 'Yorubagbe';
      default:
        return 'Yoruba';
    }
  }

  String get goun {
    switch (locale.languageCode) {
      case 'en':
        return 'Goun';
      case 'fon':
        return 'Gungbe';
      case 'yo':
        return 'Gun';
      case 'guw':
        return 'Gungbe';
      default:
        return 'Goun';
    }
  }

  String get selectLanguage {
    switch (locale.languageCode) {
      case 'en':
        return 'Select Language';
      case 'fon':
        return 'Kpɔn gle';
      case 'yo':
        return 'Yan èdè';
      case 'guw':
        return 'Kpɔn gle';
      default:
        return 'Choisir la langue';
    }
  }

  String get close {
    switch (locale.languageCode) {
      case 'en':
        return 'Close';
      case 'fon':
        return 'Xlɔ';
      case 'yo':
        return 'Pa';
      case 'guw':
        return 'Xlɔ';
      default:
        return 'Fermer';
    }
  }

  String get settings {
    switch (locale.languageCode) {
      case 'en':
        return 'Settings';
      case 'fon':
        return 'Kpɔkpɔ';
      case 'yo':
        return 'Àwọn ètò';
      case 'guw':
        return 'Kpɔkpɔ';
      default:
        return 'Paramètres';
    }
  }

  String get darkTheme {
    switch (locale.languageCode) {
      case 'en':
        return 'Dark Theme';
      case 'fon':
        return 'Kpɔkpɔ ɖo';
      case 'yo':
        return 'Àwòrán dudu';
      case 'guw':
        return 'Kpɔkpɔ ɖo';
      default:
        return 'Thème sombre';
    }
  }

  String get location {
    switch (locale.languageCode) {
      case 'en':
        return 'Location';
      case 'fon':
        return 'Fǐ';
      case 'yo':
        return 'Ibi';
      case 'guw':
        return 'Fǐ';
      default:
        return 'Localisation';
    }
  }

  String get alwaysAllowed {
    switch (locale.languageCode) {
      case 'en':
        return 'Always allowed';
      case 'fon':
        return 'Nɔ ɖo ɖo';
      case 'yo':
        return 'Nigbagbogbo ti gba';
      case 'guw':
        return 'Nɔ ɖo ɖo';
      default:
        return 'Toujours autorisée';
    }
  }
}

/// Délégué pour la localisation
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((l) => l.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

