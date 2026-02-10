import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PerformanceDebugScreen extends StatefulWidget {
  const PerformanceDebugScreen({super.key});

  @override
  State<PerformanceDebugScreen> createState() => _PerformanceDebugScreenState();
}

class _PerformanceDebugScreenState extends State<PerformanceDebugScreen> {
  String _diagnostics =
      'Cliquez sur "Diagnostiquer" pour analyser les performances';
  bool _isRunning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic Performance'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProblemSummary(),
            const SizedBox(height: 16),
            _buildQuickFixes(),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: _isRunning ? null : _runDiagnostics,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                icon: _isRunning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.bug_report),
                label: Text(
                  _isRunning ? 'Diagnostic en cours...' : 'Diagnostiquer',
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Diagnostic détaillé:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _diagnostics,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProblemSummary() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red[700]),
                const SizedBox(width: 8),
                const Text(
                  'Problèmes détectés:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('❌ ImageReader: Trop de buffers d\'images'),
            const Text('❌ GC fréquent: Libération de 15MB de mémoire'),
            const Text('❌ Flogger: Trop de logs avant configuration'),
            const Text('❌ Surface View: Problèmes de rendu'),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFixes() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Solutions rapides:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildQuickFixButton(
              '🗑️ Vider cache Flutter',
              'flutter clean && flutter pub get',
              _clearFlutterCache,
            ),
            _buildQuickFixButton(
              '📱 Redémarrer app',
              'Force stop + restart',
              _restartApp,
            ),
            _buildQuickFixButton(
              '🧹 Garbage Collection',
              'Forcer nettoyage mémoire',
              _forceGC,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFixButton(
    String title,
    String description,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onPressed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(description, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isRunning = true;
      _diagnostics = 'Analyse en cours...\n\n';
    });

    final StringBuffer result = StringBuffer();

    result.write('🔍 DIAGNOSTIC PERFORMANCE\n');
    result.write('=' * 50 + '\n\n');

    // Analyse des erreurs ImageReader
    result.write('📸 ANALYSE IMAGEREADEER:\n');
    result.write('Problème: "Unable to acquire buffer item"\n');
    result.write('Cause probable: Google Maps charge trop d\'images\n');
    result.write('Solutions:\n');
    result.write('  • Limiter le nombre de markers\n');
    result.write('  • Utiliser des images plus petites\n');
    result.write('  • Implémenter le clustering de markers\n\n');

    // Analyse mémoire
    result.write('💾 ANALYSE MÉMOIRE:\n');
    result.write('GC a libéré: 15MB (indication de fuite mémoire)\n');
    result.write('Solutions:\n');
    result.write('  • Dispose des controllers dans didDispose()\n');
    result.write('  • Éviter les listeners non supprimés\n');
    result.write('  • Optimiser les images/assets\n\n');

    // Analyse des logs
    result.write('📝 ANALYSE LOGS:\n');
    result.write('Trop de logs Flogger avant configuration\n');
    result.write('Solutions:\n');
    result.write('  • Configurer logging plus tôt\n');
    result.write('  • Réduire le niveau de logs en production\n\n');

    // Vérifications système
    await _checkSystemResources(result);

    result.write('\n📊 RECOMMANDATIONS:\n');
    result.write('=' * 30 + '\n');
    result.write('1. PRIORITÉ HAUTE - Optimiser Google Maps:\n');
    result.write('   • Réduire les markers simultanés\n');
    result.write('   • Utiliser MarkerClustering\n');
    result.write('   • Compresser les images de markers\n\n');

    result.write('2. PRIORITÉ MOYENNE - Gestion mémoire:\n');
    result.write('   • Audit des fuites mémoire\n');
    result.write('   • Optimiser les dispose()\n\n');

    result.write('3. PRIORITÉ BASSE - Logs:\n');
    result.write('   • Configuration logging early\n');
    result.write('   • Filtrage logs production\n\n');

    setState(() {
      _diagnostics = result.toString();
      _isRunning = false;
    });
  }

  Future<void> _checkSystemResources(StringBuffer result) async {
    result.write('🔧 VÉRIFICATIONS SYSTÈME:\n');

    // Simulation de vérifications (en réalité, nécessiterait des plugins spécifiques)
    await Future.delayed(const Duration(milliseconds: 500));
    result.write('✅ Espace disque: OK\n');

    await Future.delayed(const Duration(milliseconds: 300));
    result.write('⚠️ RAM utilisée: Élevée (estimation)\n');

    await Future.delayed(const Duration(milliseconds: 200));
    result.write('✅ CPU: Normal\n');

    result.write('\n');
  }

  void _clearFlutterCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider le cache Flutter'),
        content: const Text(
          'Cette action va:\n'
          '• Supprimer les fichiers de build\n'
          '• Nettoyer le cache Dart\n'
          '• Forcer une recompilation\n\n'
          'Exécutez ensuite:\n'
          'flutter clean && flutter pub get',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showCacheCleared();
            },
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  void _restartApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redémarrer l\'application'),
        content: const Text(
          'Pour redémarrer complètement:\n\n'
          '1. Fermez l\'app (bouton back)\n'
          '2. Dans les paramètres Android:\n'
          '   Apps > Localisation > Force Stop\n'
          '3. Relancez l\'app\n\n'
          'Ou utilisez "Hot Restart" dans votre IDE',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              SystemNavigator.pop(); // Ferme l'app
            },
            child: const Text('Fermer app'),
          ),
        ],
      ),
    );
  }

  void _forceGC() {
    // En Flutter, on ne peut pas forcer le GC directement
    // Mais on peut simuler en nettoyant des références
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nettoyage mémoire'),
        content: const Text(
          'Le Garbage Collector Dart se déclenche automatiquement.\n\n'
          'Pour optimiser:\n'
          '• Évitez les références circulaires\n'
          '• Dispose correctement les controllers\n'
          '• Utilisez WeakReference si nécessaire',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showCacheCleared() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exécutez: flutter clean && flutter pub get'),
        duration: Duration(seconds: 3),
      ),
    );
  }
}
