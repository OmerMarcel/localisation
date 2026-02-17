class ExchangeConfig {
  final double ratePerPoint;
  final int minPoints;
  final double minAmountCfa;

  ExchangeConfig({
    required this.ratePerPoint,
    required this.minPoints,
    required this.minAmountCfa,
  });

  factory ExchangeConfig.fromJson(Map<String, dynamic> json) {
    return ExchangeConfig(
      ratePerPoint: _parseDouble(json['rate_per_point']),
      minPoints: _parseInt(json['min_points']),
      minAmountCfa: _parseDouble(json['min_amount_cfa']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rate_per_point': ratePerPoint,
      'min_points': minPoints,
      'min_amount_cfa': minAmountCfa,
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
