import 'dart:io';
import '../models/contribution.dart';

/// Repository pour les contributions
/// NOTE: Ce repository a été désactivé suite à la suppression de Supabase.
/// Utilisez ContributionService à la place pour les opérations sur les contributions.
class ContributionRepository {
  // Ce repository utilisait Supabase et a été désactivé.
  // Utilisez ContributionService pour les opérations sur les contributions.

  /// Créer une nouvelle proposition avec images
  /// DÉSACTIVÉ - Utilisez ContributionService.createProposition() à la place
  @Deprecated('Utilisez ContributionService.createProposition() à la place')
  Future<void> createProposition(
    Map<String, dynamic> propositionData,
    List<File> imageFiles,
  ) async {
    throw UnimplementedError(
      'Cette méthode a été désactivée. Utilisez ContributionService.createProposition() à la place.',
    );
  }

  /// Récupérer toutes les contributions
  /// DÉSACTIVÉ - Utilisez ContributionService.getAllContributions() à la place
  @Deprecated('Utilisez ContributionService.getAllContributions() à la place')
  Future<List<Contribution>> getAllContributions() async {
    throw UnimplementedError(
      'Cette méthode a été désactivée. Utilisez ContributionService.getAllContributions() à la place.',
    );
  }

  /// Ajouter une contribution
  /// DÉSACTIVÉ - Utilisez ContributionService.createContribution() à la place
  @Deprecated('Utilisez ContributionService.createContribution() à la place')
  Future<void> addContribution(Contribution contribution) async {
    throw UnimplementedError(
      'Cette méthode a été désactivée. Utilisez ContributionService.createContribution() à la place.',
    );
  }

  /// Mettre à jour une contribution
  /// DÉSACTIVÉ - Utilisez ContributionService.updateContribution() à la place
  @Deprecated('Utilisez ContributionService.updateContribution() à la place')
  Future<void> updateContribution(String id, Contribution contribution) async {
    throw UnimplementedError(
      'Cette méthode a été désactivée. Utilisez ContributionService.updateContribution() à la place.',
    );
  }

  /// Supprimer une contribution
  /// DÉSACTIVÉ - Utilisez ApiService pour supprimer une contribution
  @Deprecated('Utilisez ApiService pour supprimer une contribution')
  Future<void> deleteContribution(String id) async {
    throw UnimplementedError(
      'Cette méthode a été désactivée. Utilisez ApiService pour supprimer une contribution.',
    );
  }
}
