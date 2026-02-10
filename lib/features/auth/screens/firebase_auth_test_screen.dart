import 'package:flutter/material.dart';
import '../widgets/firebase_auth_test_widget.dart';

/// Écran de test Firebase Auth
/// À utiliser uniquement en développement pour tester l'authentification
///
/// Pour l'utiliser, ajoutez cette route dans votre app ou
/// créez un bouton temporaire dans HomeScreen qui navigue ici.
///
/// Exemple d'ajout depuis HomeScreen:
/// ```dart
/// FloatingActionButton(
///   onPressed: () {
///     Navigator.push(
///       context,
///       MaterialPageRoute(
///         builder: (context) => const FirebaseAuthTestScreen(),
///       ),
///     );
///   },
///   child: Icon(Icons.science),
/// )
/// ```
class FirebaseAuthTestScreen extends StatelessWidget {
  const FirebaseAuthTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FirebaseAuthTestWidget();
  }
}
