import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/app_providers.dart';
import 'core/localization/app_localizations.dart';
import 'core/services/storage_service.dart';
import 'core/services/api_service.dart';
import 'core/models/infrastructure_hive.dart';
import 'features/home/home_screen.dart';
import 'features/notifications/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Initialisation Firebase obligatoire
  await Firebase.initializeApp();

  // 🔥 Enregistrer le handler pour les messages en arrière-plan AVANT toute autre chose
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // 🔥 Activation Firebase App Check - DÉSACTIVÉ TEMPORAIREMENT
  // App Check bloque l'authentification avant configuration complète
  // À RÉACTIVER après publication sur Play Store (voir guide ci-dessous)

  // ÉTAPE 1 : Publier l'app sur Play Store (Internal Testing minimum)
  // ÉTAPE 2 : Activer Play Integrity API dans Google Cloud Console
  // ÉTAPE 3 : Configurer App Check dans Firebase Console
  // ÉTAPE 4 : Décommenter le code ci-dessous et republier

  /*
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode 
        ? AndroidProvider.debug 
        : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode 
        ? AppleProvider.debug 
        : AppleProvider.deviceCheck,
  );
  
  if (kDebugMode) {
    try {
      final token = await FirebaseAppCheck.instance.getToken(true);
      debugPrint('🔥 AppCheck token: $token');
    } catch (e) {
      debugPrint('⚠️ AppCheck error: $e');
    }
  }
  print("🔥 AppCheck activé");
  */

  print("⚠️ App Check désactivé - À réactiver après publication Play Store");

  // 💾 Initialiser Hive pour le cache local
  await Hive.initFlutter();
  // Enregistrer l'adaptateur Hive pour InfrastructureHive
  Hive.registerAdapter(InfrastructureHiveAdapter());
  print("💾 Hive initialisé — Cache local prêt pour les marqueurs");

  // 📦 Initialiser le storage
  await StorageService().init();

  // 🔐 Supabase Auth (OTP, mot de passe oublié)
  if (AppConstants.supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
    print(
      '✅ Supabase initialisé — OTP et récupération de mot de passe disponibles',
    );
  }

  // 🔐 Charger le token Firebase stocké (si existe)
  final apiService = ApiService();
  await apiService.loadAuthToken();

  // 🌐 Tester la connexion backend
  try {
    print('🔄 Initialisation API backend…');
    final ok = await apiService.testConnection();
    if (ok) {
      print('✅ Backend connecté !');
    } else {
      print('⚠️ Backend injoignable');
    }
  } catch (e) {
    print('❌ Erreur API: $e');
  }

  runApp(Phoenix(child: const ProviderScope(child: MyApp())));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    final locale = ref.watch(languageProvider);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Géolocalisation Cotonou',
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            const AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.lightTheme.copyWith(
            textTheme: GoogleFonts.robotoTextTheme(
              AppTheme.lightTheme.textTheme,
            ),
            appBarTheme: AppTheme.lightTheme.appBarTheme.copyWith(
              titleTextStyle: AppTextStyles.h4.copyWith(
                color: AppColors.textLight,
              ),
            ),
          ),
          darkTheme: AppTheme.darkTheme.copyWith(
            textTheme: GoogleFonts.robotoTextTheme(
              AppTheme.darkTheme.textTheme,
            ),
            appBarTheme: AppTheme.darkTheme.appBarTheme.copyWith(
              titleTextStyle: AppTextStyles.h4.copyWith(
                color: AppColors.textLight,
              ),
            ),
          ),
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const HomeScreen(),
        );
      },
    );
  }
}
