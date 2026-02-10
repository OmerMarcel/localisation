import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';

class DemoCategoriesApp extends StatelessWidget {
  const DemoCategoriesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Démo Catégories Extensibles',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const DemoCategoriesScreen(),
    );
  }
}

class DemoCategoriesScreen extends StatefulWidget {
  const DemoCategoriesScreen({super.key});

  @override
  State<DemoCategoriesScreen> createState() => _DemoCategoriesScreenState();
}

class _DemoCategoriesScreenState extends State<DemoCategoriesScreen> {
  final Set<String> _expandedCategories = {};

  void _toggleCategory(String category) {
    setState(() {
      if (_expandedCategories.contains(category)) {
        _expandedCategories.remove(category);
      } else {
        _expandedCategories.add(category);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catégories de Services'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Services Publics de Cotonou',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Appuyez sur une catégorie pour voir les sous-services',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          ...AppConstants.infrastructureServices.entries.map((entry) {
            final category = entry.key;
            final subServices = entry.value;
            final isExpanded = _expandedCategories.contains(category);
            final categoryColor =
                AppConstants.categoryColors[category] ?? AppColors.primary;
            final categoryIcon =
                AppConstants.categoryIcons[category] ?? Icons.location_on;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              child: Column(
                children: [
                  // Catégorie principale
                  Container(
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: categoryColor.withOpacity(0.3)),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          categoryIcon,
                          color: categoryColor,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        category,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: categoryColor,
                        ),
                      ),
                      subtitle: Text(
                        '${subServices.length} services disponibles',
                        style: TextStyle(
                          fontSize: 14,
                          color: categoryColor.withOpacity(0.7),
                        ),
                      ),
                      trailing: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: categoryColor,
                        size: 28,
                      ),
                      onTap: () => _toggleCategory(category),
                    ),
                  ),

                  // Sous-services (si la catégorie est étendue)
                  if (isExpanded) ...[
                    Container(
                      margin: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 8,
                        bottom: 8,
                      ),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: categoryColor.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        children: subServices.map((subService) {
                          final subServiceIcon =
                              AppConstants.subServiceIcons[subService] ??
                              Icons.circle;

                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            leading: Icon(
                              subServiceIcon,
                              color: categoryColor.withOpacity(0.8),
                              size: 20,
                            ),
                            title: Text(
                              subService,
                              style: TextStyle(
                                fontSize: 14,
                                color: categoryColor.withOpacity(0.9),
                              ),
                            ),
                            trailing: Icon(
                              Icons.search,
                              color: categoryColor.withOpacity(0.6),
                              size: 18,
                            ),
                            onTap: () {
                              // Montrer un message quand on clique sur un sous-service
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Recherche pour: $subService'),
                                  backgroundColor: categoryColor,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// Point d'entrée pour la démo
void main() {
  runApp(const DemoCategoriesApp());
}
