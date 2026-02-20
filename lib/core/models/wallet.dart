import 'package:flutter/material.dart';

/// Modèle représentant un portefeuille utilisateur
class Wallet {
  final String userId;
  final double totalBalance; // Montant total en F CFA
  final double availableBalance; // Montant disponible pour retrait
  final double pendingBalance; // Montant en attente
  final int totalTransactions;
  final DateTime lastUpdated;
  final List<Transaction> recentTransactions;

  Wallet({
    required this.userId,
    required this.totalBalance,
    required this.availableBalance,
    required this.pendingBalance,
    required this.totalTransactions,
    required this.lastUpdated,
    required this.recentTransactions,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    final transactions = ((json['recent_transactions'] as List<dynamic>?) ?? [])
        .map((t) => Transaction.fromJson(t as Map<String, dynamic>))
        .toList();

    return Wallet(
      userId: json['user_id'] as String? ?? '',
      totalBalance: _parseDouble(json['total_balance']),
      availableBalance: _parseDouble(json['available_balance']),
      pendingBalance: _parseDouble(json['pending_balance']),
      totalTransactions: json['total_transactions'] as int? ?? 0,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : DateTime.now(),
      recentTransactions: transactions,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'total_balance': totalBalance,
      'available_balance': availableBalance,
      'pending_balance': pendingBalance,
      'total_transactions': totalTransactions,
      'last_updated': lastUpdated.toIso8601String(),
      'recent_transactions': recentTransactions.map((t) => t.toJson()).toList(),
    };
  }

  Wallet copyWith({
    String? userId,
    double? totalBalance,
    double? availableBalance,
    double? pendingBalance,
    int? totalTransactions,
    DateTime? lastUpdated,
    List<Transaction>? recentTransactions,
  }) {
    return Wallet(
      userId: userId ?? this.userId,
      totalBalance: totalBalance ?? this.totalBalance,
      availableBalance: availableBalance ?? this.availableBalance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      recentTransactions: recentTransactions ?? this.recentTransactions,
    );
  }
}

/// Modèle représentant une transaction du portefeuille
class Transaction {
  final String id;
  final String type; // 'contribution', 'exchange', 'withdrawal', 'refund'
  final String description;
  final double amount;
  final String status; // 'completed', 'pending', 'failed'
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? referenceId;
  final String? qrCode;

  Transaction({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.referenceId,
    this.qrCode,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'unknown',
      description: json['description'] as String? ?? '',
      amount: _parseDouble(json['amount']),
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      referenceId: json['reference_id'] as String?,
      qrCode: json['qr_code'] as String?,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'amount': amount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'reference_id': referenceId,
      'qr_code': qrCode,
    };
  }

  String getStatusLabel() {
    switch (status) {
      case 'completed':
        return '✅ Complété';
      case 'pending':
        return '⏳ En attente';
      case 'failed':
        return '❌ Échoué';
      default:
        return status;
    }
  }

  String getTypeLabel() {
    switch (type) {
      case 'contribution':
        return 'Contribution';
      case 'exchange':
        return 'Échange de points';
      case 'withdrawal':
        return 'Retrait';
      case 'refund':
        return 'Remboursement';
      default:
        return type;
    }
  }

  Color getStatusColor() {
    switch (status) {
      case 'completed':
        return const Color(0xFF10B981); // vert
      case 'pending':
        return const Color(0xFFF59E0B); // orange
      case 'failed':
        return const Color(0xFFEF4444); // rouge
      default:
        return const Color(0xFF6B7280); // gris
    }
  }
}
