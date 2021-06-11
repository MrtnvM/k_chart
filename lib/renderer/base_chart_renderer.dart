import 'package:flutter/material.dart';
import 'package:k_chart/chart_style.dart';
import 'package:k_chart/k_chart_widget.dart';
export '../chart_style.dart';

abstract class BaseChartRenderer<T> {
  double maxValue, minValue;
  late double scaleY;
  double topPadding;
  Rect chartRect;
  PriceFormatter priceFormatter;
  ChartColors chartColors;

  late Paint chartPaint;
  late Paint gridPaint;

  BaseChartRenderer({
    required this.chartRect,
    required this.maxValue,
    required this.minValue,
    required this.topPadding,
    required this.priceFormatter,
    required this.chartColors,
  })   : assert(maxValue != 0),
        assert(minValue != 0),
        assert(topPadding != 0) {
    if (maxValue == minValue) {
      maxValue *= 1.5;
      minValue /= 2;
    }

    scaleY = chartRect.height / (maxValue - minValue);

    gridPaint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high
      ..strokeWidth = 0.5
      ..color = chartColors.gridColor;

    chartPaint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high
      ..strokeWidth = 1.0
      ..color = Colors.red;
  }

  double getY(double y) => (maxValue - y) * scaleY + chartRect.top;

  void drawGrid(Canvas canvas, int gridRows, int gridColumns);

  void drawText(Canvas canvas, T data, double x);

  void drawRightText(canvas, TextStyle textStyle, int gridRows);

  void drawChart(T lastPoint, T curPoint, double lastX, double curX, Size size,
      Canvas canvas);

  void drawLine(
    double lastPrice,
    double curPrice,
    Canvas canvas,
    double lastX,
    double curX,
    Color color,
  ) {
    double lastY = getY(lastPrice);
    double curY = getY(curPrice);

    canvas.drawLine(
      Offset(lastX, lastY),
      Offset(curX, curY),
      chartPaint..color = color,
    );
  }

  TextStyle getTextStyle(Color color) {
    return TextStyle(fontSize: 10.0, color: color);
  }
}
