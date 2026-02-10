import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

// Provider pour le service d'authentification
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Provider pour l'état d'authentification
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Provider pour l'utilisateur courant
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authServiceProvider).currentUser;
});

// Provider pour les informations utilisateur
final userInfoProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(authServiceProvider).getUserInfo();
});

// Provider pour vérifier si l'email est vérifié
final isEmailVerifiedProvider = Provider<bool>((ref) {
  return ref.watch(authServiceProvider).isEmailVerified;
});
