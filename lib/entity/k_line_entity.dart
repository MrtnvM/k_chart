import 'candle_entity.dart';

class KLineEntity implements CandleEntity {
  final double open;
  final double high;
  final double low;
  final double close;
  final double? amount;
  final double? change;
  final double? ratio;
  final int? time;

  KLineEntity.fromCustom({
    this.amount,
    required this.open,
    required this.close,
    this.change,
    this.ratio,
    this.time,
    required this.high,
    required this.low,
  });

  static KLineEntity fromJson(Map<String, dynamic> json) {
    final open = (json['open'] as num?)?.toDouble();
    final high = (json['high'] as num?)?.toDouble();
    final low = (json['low'] as num?)?.toDouble();
    final close = (json['close'] as num?)?.toDouble();
    final amount = (json['amount'] as num?)?.toDouble();
    final ratio = (json['ratio'] as num?)?.toDouble();
    final change = (json['change'] as num?)?.toDouble();

    final parsedTime = (json['time'] as num?)?.toInt();
    final time = parsedTime ??
        // Need only for example project test API
        (json['id'] as num).toInt() * 1000;

    if (open == null) throw Exception('KLineEntity: open should not be null');
    if (high == null) throw Exception('KLineEntity: high should not be null');
    if (close == null) throw Exception('KLineEntity: close should not be null');
    if (low == null) throw Exception('KLineEntity: low should not be null');

    return KLineEntity.fromCustom(
      open: open,
      high: high,
      low: low,
      close: close,
      amount: amount,
      change: change,
      ratio: ratio,
      time: time,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['time'] = this.time;
    data['open'] = this.open;
    data['close'] = this.close;
    data['high'] = this.high;
    data['low'] = this.low;
    data['amount'] = this.amount;
    data['ratio'] = this.ratio;
    data['change'] = this.change;
    return data;
  }

  @override
  String toString() {
    return 'MarketModel'
        '{open: $open, high: $high, low: $low, close: $close, '
        'time: $time, amount: $amount, ratio: $ratio, '
        'change: $change}';
  }
}
