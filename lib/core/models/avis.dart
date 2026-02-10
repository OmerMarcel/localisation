class Avis {
  final String id;
  final String infrastructureId;
  final String userId;
  final int note; // 1-5
  final String commentaire;
  final List<String> photos;
  final bool approuve;
  final DateTime createdAt;
  final AvisUtilisateur? utilisateur;

  Avis({
    required this.id,
    required this.infrastructureId,
    required this.userId,
    required this.note,
    this.commentaire = '',
    this.photos = const [],
    this.approuve = true,
    required this.createdAt,
    this.utilisateur,
  });

  factory Avis.fromJson(Map<String, dynamic> json) {
    final rawUtilisateur = json['utilisateur'] ?? json['utilisateur_id'];
    AvisUtilisateur? utilisateur;
    if (rawUtilisateur is Map<String, dynamic>) {
      utilisateur = AvisUtilisateur.fromJson(rawUtilisateur);
    }

    return Avis(
      id: json['id'] ?? '',
      infrastructureId:
          json['infrastructure_id'] ?? json['infrastructureId'] ?? '',
      userId: json['utilisateur_id'] ?? json['userId'] ?? '',
      note: (json['note'] ?? 0).toInt(),
      commentaire: json['commentaire'] ?? '',
      photos: (json['photos'] ?? [])
          .map((p) => p is String ? p : (p['url'] ?? ''))
          .where((url) => url.isNotEmpty)
          .cast<String>()
          .toList(),
      approuve: json['approuve'] ?? true,
      createdAt:
          DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ??
          DateTime.now(),
      utilisateur: utilisateur,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'infrastructureId': infrastructureId,
      'note': note,
      'commentaire': commentaire,
      'photos': photos,
    };
  }
}

class AvisUtilisateur {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String? avatar;

  AvisUtilisateur({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    this.avatar,
  });

  factory AvisUtilisateur.fromJson(Map<String, dynamic> json) {
    return AvisUtilisateur(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'],
    );
  }

  String get displayName {
    final parts = [prenom, nom].where((s) => s.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(' ') : email;
  }

  String get initials {
    final parts = [prenom, nom].where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return email.isNotEmpty ? email[0].toUpperCase() : '?';
    return parts.map((s) => s.isNotEmpty ? s[0].toUpperCase() : '').join('');
  }
}
