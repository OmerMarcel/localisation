class RewardExchange {
  final String id;
  final int pointsExchanged;
  final double amountCfa;
  final double ratePerPoint;
  final String status;
  final DateTime createdAt;

  RewardExchange({
    required this.id,
    required this.pointsExchanged,
    required this.amountCfa,
    required this.ratePerPoint,
    required this.status,
    required this.createdAt,
  });

  factory RewardExchange.fromJson(Map<String, dynamic> json) {
    return RewardExchange(
      id: (json['id'] ?? '').toString(),
      pointsExchanged: _parseInt(json['points_exchanged']),
      amountCfa: _parseDouble(json['amount_cfa']),
      ratePerPoint: _parseDouble(json['rate_per_point']),
      status: (json['status'] ?? '').toString(),
      createdAt: DateTime.parse(
        (json['created_at'] ?? json['processed_at']).toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'points_exchanged': pointsExchanged,
      'amount_cfa': amountCfa,
      'rate_per_point': ratePerPoint,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get statusLabel {
    switch (status) {
      case 'completed':
        return 'Termine';
      case 'cancelled':
        return 'Annule';
      case 'failed':
        return 'Echec';
      default:
        return status;
    }
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

class PaginatedExchangeHistory {
  final List<RewardExchange> exchanges;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  PaginatedExchangeHistory({
    required this.exchanges,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
  });

  factory PaginatedExchangeHistory.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] ?? json['exchanges'] ?? [];
    final pagination = json['pagination'] as Map<String, dynamic>?;

    if (rawData is List && pagination != null) {
      return PaginatedExchangeHistory(
        exchanges: rawData
            .map(
              (item) => RewardExchange.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
        totalCount: _parseInt(pagination['total']),
        currentPage: _parseInt(pagination['page']),
        totalPages: _parseInt(pagination['pages']),
      );
    }

    return PaginatedExchangeHistory(
      exchanges: (rawData as List<dynamic>)
          .map((item) => RewardExchange.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalCount: _parseInt(json['total_count']),
      currentPage: _parseInt(json['current_page']),
      totalPages: _parseInt(json['total_pages']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exchanges': exchanges.map((e) => e.toJson()).toList(),
      'total_count': totalCount,
      'current_page': currentPage,
      'total_pages': totalPages,
    };
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
