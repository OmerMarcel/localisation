import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/providers/auth_providers.dart';

/// Widget de test pour l'authentification Firebase
/// Utile pour tester rapidement toutes les fonctionnalités d'auth
class FirebaseAuthTestWidget extends ConsumerStatefulWidget {
  const FirebaseAuthTestWidget({super.key});

  @override
  ConsumerState<FirebaseAuthTestWidget> createState() =>
      _FirebaseAuthTestWidgetState();
}

class _FirebaseAuthTestWidgetState
    extends ConsumerState<FirebaseAuthTestWidget> {
  final _emailController = TextEditingController(text: 'test@example.com');
  final _passwordController = TextEditingController(text: 'Test123456');
  final _nameController = TextEditingController(text: 'Test User');
  final List<String> _logs = [];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _addLog(String message, {bool isError = false}) {
    setState(() {
      final timestamp = DateTime.now().toString().substring(11, 19);
      final prefix = isError ? '❌' : '✅';
      _logs.insert(0, '[$timestamp] $prefix $message');
    });
  }

  Future<void> _testRegister() async {
    _addLog('Test inscription...');
    final authService = ref.read(authServiceProvider);

    final result = await authService.registerWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
    );

    if (result != null) {
      _addLog(
        'Inscription réussie - UID: ${result.user?.uid?.substring(0, 8)}...',
      );
    } else {
      _addLog('Échec inscription', isError: true);
    }
  }

  Future<void> _testLogin() async {
    _addLog('Test connexion...');
    final authService = ref.read(authServiceProvider);

    final result = await authService.signInWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (result != null) {
      _addLog('Connexion réussie - User: ${result.user?.email}');
    } else {
      _addLog('Échec connexion', isError: true);
    }
  }

  Future<void> _testPasswordReset() async {
    _addLog('Test mot de passe oublié...');
    final authService = ref.read(authServiceProvider);

    final error = await authService.resetPassword(_emailController.text.trim());

    if (error == null) {
      _addLog('Email de réinitialisation envoyé à ${_emailController.text}');
    } else {
      _addLog('Échec: $error', isError: true);
    }
  }

  Future<void> _testGoogleSignIn() async {
    _addLog('Test Google Sign-In...');
    final authService = ref.read(authServiceProvider);

    final result = await authService.signInWithGoogle();

    if (result != null) {
      _addLog('Google Sign-In réussi - User: ${result.user?.displayName}');
    } else {
      _addLog('Échec Google Sign-In (annulé ou erreur)', isError: true);
    }
  }

  Future<void> _testSendEmailVerification() async {
    _addLog('Test envoi email de vérification...');
    final authService = ref.read(authServiceProvider);

    final success = await authService.sendEmailVerification();

    if (success) {
      _addLog('Email de vérification envoyé');
    } else {
      _addLog('Échec envoi email', isError: true);
    }
  }

  Future<void> _testSignOut() async {
    _addLog('Test déconnexion...');
    final authService = ref.read(authServiceProvider);

    await authService.signOut();
    _addLog('Déconnexion réussie');
  }

  Future<void> _checkCurrentUser() async {
    _addLog('Vérification utilisateur courant...');
    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;

    if (user != null) {
      _addLog(
        'Utilisateur connecté: ${user.email} (Vérifié: ${user.emailVerified})',
      );
    } else {
      _addLog('Aucun utilisateur connecté', isError: true);
    }
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Test Firebase Auth'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearLogs,
            tooltip: 'Effacer les logs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Info utilisateur courant
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: authState.when(
              data: (user) {
                if (user != null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '👤 Connecté',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Email: ${user.email ?? "N/A"}'),
                      Text('UID: ${user.uid.substring(0, 8)}...'),
                      Text(
                        'Email vérifié: ${user.emailVerified ? "Oui ✅" : "Non ❌"}',
                      ),
                    ],
                  );
                } else {
                  return const Text(
                    '🔓 Non connecté',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  );
                }
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text('Erreur: $err'),
            ),
          ),

          // Champs de saisie
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),

          // Boutons de test
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _testRegister,
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('Inscription'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _testLogin,
                  icon: const Icon(Icons.login, size: 16),
                  label: const Text('Connexion'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _testPasswordReset,
                  icon: const Icon(Icons.lock_reset, size: 16),
                  label: const Text('Reset MdP'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _testGoogleSignIn,
                  icon: const Icon(Icons.g_translate, size: 16),
                  label: const Text('Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _testSendEmailVerification,
                  icon: const Icon(Icons.mark_email_read, size: 16),
                  label: const Text('Vérif Email'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _checkCurrentUser,
                  icon: const Icon(Icons.info, size: 16),
                  label: const Text('Check User'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _testSignOut,
                  icon: const Icon(Icons.logout, size: 16),
                  label: const Text('Déconnexion'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Logs
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _logs.isEmpty
                  ? const Center(
                      child: Text(
                        '📝 Les logs apparaîtront ici...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      reverse: false,
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            _logs[index],
                            style: TextStyle(
                              color: _logs[index].contains('❌')
                                  ? Colors.red.shade300
                                  : Colors.green.shade300,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
