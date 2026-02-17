import 'dart:math';
import 'package:kutonoutche/core/models/infrastructure.dart';
import 'package:kutonoutche/core/services/infrastructure_cache_service.dart';
import 'package:flutter/material.dart';

/// Widget de test pour vérifier le système de cache local
class CacheTestScreen extends StatefulWidget {
  const CacheTestScreen({super.key});

  @override
  State<CacheTestScreen> createState() => _CacheTestScreenState();
}

class _CacheTestScreenState extends State<CacheTestScreen> {
  final _cacheService = InfrastructureCacheService();
  String _status = "Prêt pour les tests";
  Map<String, dynamic>? _stats;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initCache();
  }

  Future<void> _initCache() async {
    setState(() => _isLoading = true);
    await _cacheService.init();
    await _loadStats();
    setState(() => _isLoading = false);
  }

  Future<void> _loadStats() async {
    final stats = await _cacheService.getCacheStats();
    setState(() => _stats = stats);
  }

  // Test 1: Sauvegarder des infrastructures de test
  Future<void> _testSaveInfrastructures() async {
    setState(() {
      _status = "🔄 Sauvegarde de 5 infrastructures de test...";
      _isLoading = true;
    });

    final testInfras = List.generate(5, (i) {
      return Infrastructure(
        id: 'test_${i + 1}',
        name: 'Infrastructure Test ${i + 1}',
        description: 'Description de test pour l\'infrastructure ${i + 1}',
        category: i % 2 == 0 ? 'Toilettes publiques' : 'Aires de jeux',
        latitude: 6.3654 + (Random().nextDouble() * 0.1),
        longitude: 2.4183 + (Random().nextDouble() * 0.1),
        address: '${i + 1} Rue de Test, Cotonou',
        images: ['https://example.com/image${i + 1}.jpg'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    await _cacheService.saveInfrastructures(testInfras);
    await _loadStats();

    setState(() {
      _status = "✅ 5 infrastructures sauvegardées avec succès !";
      _isLoading = false;
    });
  }

  // Test 2: Charger toutes les infrastructures
  Future<void> _testLoadAll() async {
    setState(() {
      _status = "🔄 Chargement de toutes les infrastructures...";
      _isLoading = true;
    });

    final infrastructures = await _cacheService.getAllInfrastructures();

    setState(() {
      _status = "✅ ${infrastructures.length} infrastructure(s) chargée(s) !";
      _isLoading = false;
    });

    await _loadStats();
  }

  // Test 3: Filtrer par catégorie
  Future<void> _testFilterByCategory() async {
    setState(() {
      _status = "🔄 Filtrage par catégorie 'Toilettes publiques'...";
      _isLoading = true;
    });

    final filtered = await _cacheService.getInfrastructuresByCategory(
      'Toilettes publiques',
    );

    setState(() {
      _status = "✅ ${filtered.length} toilette(s) publique(s) trouvée(s) !";
      _isLoading = false;
    });
  }

  // Test 4: Filtrer par rayon
  Future<void> _testFilterByRadius() async {
    setState(() {
      _status = "🔄 Recherche dans un rayon de 5 km...";
      _isLoading = true;
    });

    final inRadius = await _cacheService.getInfrastructuresInRadius(
      latitude: 6.3654,
      longitude: 2.4183,
      radiusKm: 5.0,
    );

    setState(() {
      _status =
          "✅ ${inRadius.length} infrastructure(s) dans un rayon de 5 km !";
      _isLoading = false;
    });
  }

  // Test 5: Nettoyer le cache
  Future<void> _testCleanCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirmation'),
        content: const Text('Voulez-vous vraiment vider le cache ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vider'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _status = "🗑️ Nettoyage du cache...";
        _isLoading = true;
      });

      await _cacheService.clearAllCache();
      await _loadStats();

      setState(() {
        _status = "✅ Cache vidé avec succès !";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🧪 Test du Cache Local')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Statut
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _status,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Statistiques
                  if (_stats != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📊 Statistiques du Cache',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            _buildStatRow('Total', '${_stats!['total']}'),
                            _buildStatRow('Valides', '${_stats!['valid']}'),
                            _buildStatRow('Expirés', '${_stats!['expired']}'),
                            const SizedBox(height: 8),
                            const Text(
                              'Catégories:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ...(_stats!['categories'] as Map<String, int>)
                                .entries
                                .map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.only(left: 16),
                                    child: Text('${e.key}: ${e.value}'),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Boutons de test
                  const Text(
                    '🧪 Tests Disponibles',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: _testSaveInfrastructures,
                    icon: const Icon(Icons.save),
                    label: const Text('1️⃣ Sauvegarder 5 infrastructures'),
                  ),
                  const SizedBox(height: 8),

                  ElevatedButton.icon(
                    onPressed: _testLoadAll,
                    icon: const Icon(Icons.download),
                    label: const Text('2️⃣ Charger toutes les infrastructures'),
                  ),
                  const SizedBox(height: 8),

                  ElevatedButton.icon(
                    onPressed: _testFilterByCategory,
                    icon: const Icon(Icons.filter_list),
                    label: const Text('3️⃣ Filtrer par catégorie'),
                  ),
                  const SizedBox(height: 8),

                  ElevatedButton.icon(
                    onPressed: _testFilterByRadius,
                    icon: const Icon(Icons.radio_button_checked),
                    label: const Text('4️⃣ Filtrer par rayon (5 km)'),
                  ),
                  const SizedBox(height: 8),

                  ElevatedButton.icon(
                    onPressed: _testCleanCache,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('🗑️ Vider le cache'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
