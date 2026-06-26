class PortfolioStock {
  final String id;
  final String symbol;
  final String name;
  final String sector;
  final double avgCost;
  final int qty;

  const PortfolioStock({
    required this.id,
    required this.symbol,
    required this.name,
    required this.sector,
    required this.avgCost,
    required this.qty,
  });

  double get invested => avgCost * qty;

  PortfolioStock copyWith({
    String? id,
    String? symbol,
    String? name,
    String? sector,
    double? avgCost,
    int? qty,
  }) {
    return PortfolioStock(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      sector: sector ?? this.sector,
      avgCost: avgCost ?? this.avgCost,
      qty: qty ?? this.qty,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'name': name,
        'sector': sector,
        'avgCost': avgCost,
        'qty': qty,
      };

  factory PortfolioStock.fromJson(Map<String, dynamic> json) {
    return PortfolioStock(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String? ?? '',
      sector: json['sector'] as String? ?? 'other',
      avgCost: (json['avgCost'] as num).toDouble(),
      qty: (json['qty'] as num).toInt(),
    );
  }
}
