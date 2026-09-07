import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';

/// Écran de gestion de la base de données locale (cache Hive)
/// et guide pour vider les données distantes sur Supabase.
class DatabaseManagerScreen extends ConsumerStatefulWidget {
  const DatabaseManagerScreen({super.key});

  @override
  ConsumerState<DatabaseManagerScreen> createState() =>
      _DatabaseManagerScreenState();
}

class _DatabaseManagerScreenState
    extends ConsumerState<DatabaseManagerScreen> {
  Map<String, dynamic>? _cacheStats;
  bool _isLoadingStats = false;
  bool _isClearingCache = false;
  String? _statusMessage;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final stats = await ref
          .read(infrastructuresProvider.notifier)
          .getCacheStats();
      setState(() {
        _cacheStats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
        _statusMessage = 'Erreur lors du chargement des stats: $e';
        _isError = true;
      });
    }
  }

  Future<void> _clearLocalCache() async {
    final confirmed = await _showConfirmDialog(
      title: 'Vider le cache local',
      message:
          'Cette action supprimera toutes les infrastructures stockées localement sur l\'appareil.\n\nL\'application rechargera automatiquement les données depuis le serveur.\n\nContinuer ?',
      confirmLabel: 'Vider le cache',
      confirmColor: const Color(0xFFEF5350),
    );

    if (!confirmed) return;

    setState(() {
      _isClearingCache = true;
      _statusMessage = null;
      _isError = false;
    });

    try {
      await ref.read(infrastructuresProvider.notifier).clearLocalCache();
      await _loadStats();
      setState(() {
        _statusMessage =
            '✅ Cache local vidé avec succès. Rechargement depuis l\'API effectué.';
        _isError = false;
        _isClearingCache = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Erreur lors du vidage du cache: $e';
        _isError = true;
        _isClearingCache = false;
      });
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: confirmColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: const Text(
          'Gestion de la base de données',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Rafraîchir les stats',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ──────────── Bannière d'avertissement ────────────
            _buildWarningBanner(),
            const SizedBox(height: 20),

            // ──────────── Section : Cache Local Hive ────────────
            _buildSectionHeader(
              icon: Icons.storage,
              title: 'Cache Local (Hive)',
              subtitle: 'Données stockées sur l\'appareil',
              color: const Color(0xFF3B82F6),
            ),
            const SizedBox(height: 12),
            _buildCacheStatsCard(),
            const SizedBox(height: 12),
            _buildClearLocalCacheButton(),

            const SizedBox(height: 28),

            // ──────────── Section : Base distante Supabase ────────────
            _buildSectionHeader(
              icon: Icons.cloud_outlined,
              title: 'Base distante (Supabase)',
              subtitle: 'Données sur le serveur backend',
              color: const Color(0xFF10B981),
            ),
            const SizedBox(height: 12),
            _buildSupabaseGuideCard(),

            const SizedBox(height: 28),

            // ──────────── Message de statut ────────────
            if (_statusMessage != null) _buildStatusMessage(),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF535015),
        border: Border.all(color: const Color(0xFFEF5350).withOpacity(0.4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFEF5350), size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ces actions sont irréversibles. Vider le cache ou la base distante supprimera définitivement les données des infrastructures sur la carte.',
              style: TextStyle(color: Color(0xFFEF5350), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCacheStatsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.2),
        ),
      ),
      child: _isLoadingStats
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  color: Color(0xFF3B82F6),
                  strokeWidth: 2,
                ),
              ),
            )
          : _cacheStats == null
          ? const Text(
              'Impossible de charger les statistiques.',
              style: TextStyle(color: Colors.white54),
            )
          : Column(
              children: [
                _buildStatRow(
                  'Total en cache',
                  '${_cacheStats!['total']} infrastructures',
                  Icons.layers,
                  const Color(0xFF3B82F6),
                ),
                const Divider(color: Colors.white10, height: 20),
                _buildStatRow(
                  'Valides (< 30 jours)',
                  '${_cacheStats!['valid']} infrastructures',
                  Icons.check_circle_outline,
                  const Color(0xFF10B981),
                ),
                const Divider(color: Colors.white10, height: 20),
                _buildStatRow(
                  'Expirées',
                  '${_cacheStats!['expired']} infrastructures',
                  Icons.schedule,
                  const Color(0xFFF59E0B),
                ),
                if ((_cacheStats!['categories'] as Map?)?.isNotEmpty ==
                    true) ...[
                  const Divider(color: Colors.white10, height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Par catégorie :',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...((_cacheStats!['categories'] as Map)
                      .entries
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '• ${e.key}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${e.value}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList()),
                ],
              ],
            ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildClearLocalCacheButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isClearingCache ? null : _clearLocalCache,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF5350),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFEF5350).withOpacity(0.4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        icon: _isClearingCache
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.delete_sweep_outlined, size: 20),
        label: Text(
          _isClearingCache ? 'Vidage en cours...' : 'Vider le cache local',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSupabaseGuideCard() {
    const sqlCommand =
        'DELETE FROM infrastructures;\n-- OU pour garder la structure :\nTRUNCATE TABLE infrastructures RESTART IDENTITY CASCADE;';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Étape 1
          _buildStep(
            number: '1',
            title: 'Accéder au dashboard Supabase',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ouvrez votre navigateur et connectez-vous sur :',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 6),
                _buildCopyableText(
                  'https://supabase.com/dashboard',
                  icon: Icons.open_in_new,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Étape 2
          _buildStep(
            number: '2',
            title: 'Sélectionner votre projet',
            child: const Text(
              'Projet ID : yejligyctalvhrzesjrb\nCliquez sur votre projet "cotonav" (ou similaire).',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),

          // Étape 3
          _buildStep(
            number: '3',
            title: 'Ouvrir le SQL Editor',
            child: const Text(
              'Dans le menu de gauche → "SQL Editor" → cliquez sur "+ New query".',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),

          // Étape 4
          _buildStep(
            number: '4',
            title: 'Exécuter la commande SQL',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Copiez et collez ce SQL dans l\'éditeur, puis cliquez sur "Run" :',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sqlCommand,
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                              const ClipboardData(text: sqlCommand),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  '✅ Commande SQL copiée dans le presse-papiers',
                                ),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.copy,
                            size: 16,
                            color: Color(0xFF10B981),
                          ),
                          label: const Text(
                            'Copier le SQL',
                            style: TextStyle(color: Color(0xFF10B981)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Étape 5
          _buildStep(
            number: '5',
            title: 'Vider aussi le cache local',
            child: const Text(
              'Après avoir vidé Supabase, pensez aussi à vider le cache local (section ci-dessus) pour synchroniser l\'appareil.',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String number,
    required String title,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFF10B981),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              child,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCopyableText(String text, {IconData? icon}) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Copié : $text'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF10B981).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
            Icon(
              icon ?? Icons.copy,
              color: const Color(0xFF10B981),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMessage() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _isError
            ? const Color(0xFFEF5350).withOpacity(0.1)
            : const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isError
              ? const Color(0xFFEF5350).withOpacity(0.3)
              : const Color(0xFF10B981).withOpacity(0.3),
        ),
      ),
      child: Text(
        _statusMessage!,
        style: TextStyle(
          color: _isError ? const Color(0xFFEF5350) : const Color(0xFF10B981),
          fontSize: 13,
        ),
      ),
    );
  }
}
