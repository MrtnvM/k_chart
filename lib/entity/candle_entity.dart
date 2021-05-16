// ignore_for_file: non_constant_identifier_names

abstract class CandleEntity {
  final double open;
  final double high;
  final double low;
  final double close;

  CandleEntity({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });
}
