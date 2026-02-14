import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/reward_providers.dart';
import '../../../core/models/contribution_history.dart';

/// Page de l'historique complet des contributions
class ContributionHistoryPage extends ConsumerStatefulWidget {
  const ContributionHistoryPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ContributionHistoryPage> createState() =>
      _ContributionHistoryPageState();
}

class _ContributionHistoryPageState
    extends ConsumerState<ContributionHistoryPage> {
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      // Charger la page suivante
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    final historyAsync = ref.read(contributionHistoryProvider(_currentPage));
    await historyAsync.when(
      data: (historyPage) {
        if (_currentPage < historyPage.totalPages) {
          setState(() {
            _currentPage++;
          });
        }
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(contributionHistoryProvider(_currentPage));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des contributions'),
        backgroundColor: Colors.indigo,
      ),
      body: historyAsync.when(
        data: (historyPage) {
          if (historyPage.contributions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune contribution',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Commencez à contribuer pour voir votre historique',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _currentPage = 1;
              });
              ref.invalidate(contributionHistoryProvider(_currentPage));
            },
            child: Column(
              children: [
                // En-tête avec statistiques
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.indigo[50],
                    border: Border(
                      bottom: BorderSide(color: Colors.indigo[100]!),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total de contributions',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${historyPage.totalCount}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Page ${historyPage.currentPage} sur ${historyPage.totalPages}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Liste des contributions
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: historyPage.contributions.length + 1,
                    itemBuilder: (context, index) {
                      if (index == historyPage.contributions.length) {
                        // Indicateur de chargement en bas
                        if (_currentPage < historyPage.totalPages) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return const SizedBox();
                      }

                      final contribution = historyPage.contributions[index];
                      return _buildContributionTile(contribution);
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Erreur de chargement',
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentPage = 1;
                  });
                  ref.invalidate(contributionHistoryProvider(_currentPage));
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContributionTile(ContributionHistory contribution) {
    Color typeColor;
    switch (contribution.contributionType) {
      case 'avis':
        typeColor = Colors.amber;
        break;
      case 'proposition':
        typeColor = Colors.blue;
        break;
      case 'signalement':
        typeColor = Colors.orange;
        break;
      case 'proposition_approuvee':
        typeColor = Colors.green;
        break;
      case 'bonus_admin':
        typeColor = Colors.purple;
        break;
      default:
        typeColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),

        // Icône
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              contribution.icon,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),

        // Type et date
        title: Text(
          contribution.typeLabel,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              DateFormat(
                'dd MMMM yyyy à HH:mm',
                'fr',
              ).format(contribution.createdAt),
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            if (contribution.details != null) ...[
              const SizedBox(height: 4),
              Text(
                _getDetailsText(contribution.details!),
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),

        // Points gagnés
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '+${contribution.pointsEarned}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(
                'pts',
                style: TextStyle(fontSize: 10, color: Colors.green[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDetailsText(Map<String, dynamic> details) {
    if (details.containsKey('comment')) {
      return details['comment'] as String;
    }
    if (details.containsKey('description')) {
      return details['description'] as String;
    }
    if (details.containsKey('title')) {
      return details['title'] as String;
    }
    return 'Détails de la contribution';
  }
}
