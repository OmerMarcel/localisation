class ExchangeRequestResult {
  final String exchangeId;
  final int pointsExchanged;
  final double amountCfa;
  final double ratePerPoint;
  final String status;
  final int newTotalPoints;

  ExchangeRequestResult({
    required this.exchangeId,
    required this.pointsExchanged,
    required this.amountCfa,
    required this.ratePerPoint,
    required this.status,
    required this.newTotalPoints,
  });

  factory ExchangeRequestResult.fromJson(Map<String, dynamic> json) {
    return ExchangeRequestResult(
      exchangeId: (json['exchange_id'] ?? '').toString(),
      pointsExchanged: _parseInt(json['points_exchanged']),
      amountCfa: _parseDouble(json['amount_cfa']),
      ratePerPoint: _parseDouble(json['rate_per_point']),
      status: (json['status'] ?? '').toString(),
      newTotalPoints: _parseInt(json['new_total_points']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exchange_id': exchangeId,
      'points_exchanged': pointsExchanged,
      'amount_cfa': amountCfa,
      'rate_per_point': ratePerPoint,
      'status': status,
      'new_total_points': newTotalPoints,
    };
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
