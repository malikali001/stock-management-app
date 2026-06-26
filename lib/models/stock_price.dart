class StockPrice {
  final double currentPrice;
  final double dayChange;
  final double dayChangePct;
  final double dayHigh;
  final double dayLow;
  final int volume;
  final double w52High;
  final double w52Low;

  const StockPrice({
    required this.currentPrice,
    required this.dayChange,
    required this.dayChangePct,
    required this.dayHigh,
    required this.dayLow,
    required this.volume,
    required this.w52High,
    required this.w52Low,
  });

  static const empty = StockPrice(
    currentPrice: 0,
    dayChange: 0,
    dayChangePct: 0,
    dayHigh: 0,
    dayLow: 0,
    volume: 0,
    w52High: 0,
    w52Low: 0,
  );

  StockPrice copyWith({
    double? currentPrice,
    double? dayChange,
    double? dayChangePct,
    double? dayHigh,
    double? dayLow,
    int? volume,
    double? w52High,
    double? w52Low,
  }) {
    return StockPrice(
      currentPrice: currentPrice ?? this.currentPrice,
      dayChange: dayChange ?? this.dayChange,
      dayChangePct: dayChangePct ?? this.dayChangePct,
      dayHigh: dayHigh ?? this.dayHigh,
      dayLow: dayLow ?? this.dayLow,
      volume: volume ?? this.volume,
      w52High: w52High ?? this.w52High,
      w52Low: w52Low ?? this.w52Low,
    );
  }
}
