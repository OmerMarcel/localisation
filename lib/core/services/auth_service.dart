import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream pour écouter les changements d'état
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Obtenir l'utilisateur courant
  User? get currentUser => _auth.currentUser;

  // Inscription avec email et mot de passe
  Future<UserCredential?> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Mettre à jour le profil
      await result.user?.updateDisplayName(displayName);
      await result.user?.reload();

      return result;
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur inscription: $e');
      return null;
    }
  }

  // Connexion avec email et mot de passe
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur connexion: $e');
      return null;
    }
  }

  // Connexion avec Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur connexion Google: $e');
      return null;
    }
  }

  // Mot de passe oublié
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('Erreur reset password: ${e.code} ${e.message}');
      }
      switch (e.code) {
        case 'user-not-found':
          return 'Aucun utilisateur trouvé avec cet email.';
        case 'invalid-email':
          return 'Email invalide.';
        case 'missing-android-pkg-name':
        case 'missing-continue-uri':
        case 'invalid-continue-uri':
        case 'unauthorized-continue-uri':
          return 'Configuration du lien de réinitialisation invalide.';
        default:
          return e.message ?? 'Erreur lors de l\'envoi de l\'email.';
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur reset password: $e');
      return 'Erreur lors de l\'envoi de l\'email.';
    }
  }

  // Vérification email
  Future<bool> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur envoi email verification: $e');
      return false;
    }
  }

  // Mettre à jour le profil
  Future<bool> updateProfile({String? displayName, String? photoURL}) async {
    try {
      if (displayName != null) {
        await _auth.currentUser?.updateDisplayName(displayName);
      }
      if (photoURL == null || (photoURL.startsWith('http') && photoURL.length < 2000)) {
        try {
          await _auth.currentUser?.updatePhotoURL(photoURL);
        } catch (_) {}
      }
      await _auth.currentUser?.reload();
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur mise à jour profil: $e');
      return false;
    }
  }

  // Changer le mot de passe
  Future<bool> changePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur changement mot de passe: $e');
      return false;
    }
  }

  // Supprimer le compte
  Future<bool> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur suppression compte: $e');
      return false;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur déconnexion: $e');
    }
  }

  // Rafraîchir l'utilisateur
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur rechargement utilisateur: $e');
    }
  }

  // Obtenir le token ID
  Future<String?> getIdToken() async {
    try {
      return await _auth.currentUser?.getIdToken();
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur obtention token: $e');
      return null;
    }
  }

  // Vérifier si l'email est vérifié
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Obtenir les informations de l'utilisateur
  Map<String, dynamic>? getUserInfo() {
    final user = _auth.currentUser;
    if (user == null) return null;

    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'emailVerified': user.emailVerified,
      'creationTime': user.metadata.creationTime,
      'lastSignInTime': user.metadata.lastSignInTime,
    };
  }
}
