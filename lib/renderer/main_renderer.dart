import 'package:flutter/material.dart';
import 'package:k_chart/k_chart_widget.dart';
import '../entity/candle_entity.dart';
import 'base_chart_renderer.dart';

class MainRenderer extends BaseChartRenderer<CandleEntity> {
  late double _candleWidth;
  late double _candleLineWidth;
  final bool isLine;
  late Rect _contentRect;
  double _contentPadding = 20.0;
  final ChartStyle chartStyle;
  final ChartColors chartColors;
  final int gridRows;
  final int gridColumns;
  late Paint _linePaint;

  MainRenderer(
    Rect mainRect,
    double maxValue,
    double minValue,
    double topPadding,
    this.isLine,
    this.chartStyle,
    this.chartColors,
    PriceFormatter priceFormatter, {
    required this.gridRows,
    required this.gridColumns,
  }) : super(
          chartRect: mainRect,
          maxValue: maxValue,
          minValue: minValue,
          topPadding: topPadding,
          priceFormatter: priceFormatter,
          chartColors: chartColors,
        ) {
    _candleWidth = this.chartStyle.candleWidth;
    _candleLineWidth = this.chartStyle.candleLineWidth;

    _linePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = this.chartColors.kLineColor;

    _contentRect = Rect.fromLTRB(
        chartRect.left,
        chartRect.top + _contentPadding,
        chartRect.right,
        chartRect.bottom - _contentPadding);

    if (maxValue == minValue) {
      maxValue *= 1.5;
      minValue /= 2;
    }

    scaleY = _contentRect.height / (maxValue - minValue);
  }

  @override
  void drawText(Canvas canvas, CandleEntity data, double x) {}

  @override
  void drawChart(
    CandleEntity lastPoint,
    CandleEntity curPoint,
    double lastX,
    double curX,
    Size size,
    Canvas canvas,
  ) {
    if (isLine == true) {
      drawPolyline(lastPoint.close, curPoint.close, canvas, lastX, curX);
    } else {
      drawCandle(curPoint, canvas, curX);
    }
  }

  Shader? mLineFillShader;
  Path? mLinePath, mLineFillPath;
  Paint mLineFillPaint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  //画折线图
  drawPolyline(double lastPrice, double curPrice, Canvas canvas, double lastX,
      double curX) {
//    drawLine(lastPrice + 100, curPrice + 100, canvas, lastX, curX, ChartColors.kLineColor);
    mLinePath ??= Path();

//    if (lastX == curX) {
//      mLinePath.moveTo(lastX, getY(lastPrice));
//    } else {
////      mLinePath.lineTo(curX, getY(curPrice));
//      mLinePath.cubicTo(
//          (lastX + curX) / 2, getY(lastPrice), (lastX + curX) / 2, getY(curPrice), curX, getY(curPrice));
//    }
    if (lastX == curX) lastX = 0; //起点位置填充
    mLinePath!.moveTo(lastX, getY(lastPrice));
    mLinePath!.cubicTo((lastX + curX) / 2, getY(lastPrice), (lastX + curX) / 2,
        getY(curPrice), curX, getY(curPrice));

//    //画阴影
    mLineFillShader ??= LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      tileMode: TileMode.clamp,
      colors: [this.chartColors.lineFillColor, Colors.transparent],
    ).createShader(Rect.fromLTRB(
        chartRect.left, chartRect.top, chartRect.right, chartRect.bottom));
    mLineFillPaint..shader = mLineFillShader;

    mLineFillPath ??= Path();

    mLineFillPath!.moveTo(lastX, chartRect.height + chartRect.top);
    mLineFillPath!.lineTo(lastX, getY(lastPrice));
    mLineFillPath!.cubicTo((lastX + curX) / 2, getY(lastPrice),
        (lastX + curX) / 2, getY(curPrice), curX, getY(curPrice));
    mLineFillPath!.lineTo(curX, chartRect.height + chartRect.top);
    mLineFillPath!.close();

    canvas.drawPath(mLineFillPath!, mLineFillPaint);
    mLineFillPath!.reset();

    canvas.drawPath(mLinePath!, _linePaint);
    mLinePath!.reset();
  }

  void drawCandle(CandleEntity curPoint, Canvas canvas, double curX) {
    var high = getY(curPoint.high);
    var low = getY(curPoint.low);
    var open = getY(curPoint.open);
    var close = getY(curPoint.close);
    double r = _candleWidth / 2;
    double lineR = _candleLineWidth / 2;
    if (open >= close) {
      // 实体高度>= CandleLineWidth
      if (open - close < _candleLineWidth) {
        open = close + _candleLineWidth;
      }
      chartPaint.color = this.chartColors.upCandleColor;
      canvas.drawRect(
          Rect.fromLTRB(curX - r, close, curX + r, open), chartPaint);
      canvas.drawRect(
          Rect.fromLTRB(curX - lineR, high, curX + lineR, low), chartPaint);
    } else if (close > open) {
      // 实体高度>= CandleLineWidth
      if (close - open < _candleLineWidth) {
        open = close - _candleLineWidth;
      }
      chartPaint.color = this.chartColors.downCandleColor;
      canvas.drawRect(
          Rect.fromLTRB(curX - r, open, curX + r, close), chartPaint);
      canvas.drawRect(
          Rect.fromLTRB(curX - lineR, high, curX + lineR, low), chartPaint);
    }
  }

  @override
  void drawRightText(canvas, TextStyle textStyle, int gridRows) {
    double rowSpace = chartRect.height / gridRows;

    for (var i = 0; i <= gridRows; ++i) {
      final value = (gridRows - i) * rowSpace / scaleY + minValue;
      final span = TextSpan(
        text: "${priceFormatter(value)}",
        style: textStyle.copyWith(
            backgroundColor: chartColors.yAxisLabelBackground),
      );
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr);

      tp.layout();
      if (i == 0) {
        tp.paint(canvas, Offset(chartRect.width - tp.width, topPadding));
      } else {
        tp.paint(
          canvas,
          Offset(
            chartRect.width - tp.width,
            rowSpace * i - tp.height + topPadding - 2,
          ),
        );
      }
    }
  }

  @override
  void drawGrid(Canvas canvas, int gridRows, int gridColumns) {
    double rowSpace = chartRect.height / gridRows;

    for (int i = 0; i <= gridRows; i++) {
      canvas.drawLine(
        Offset(0, rowSpace * i + topPadding),
        Offset(chartRect.width, rowSpace * i + topPadding),
        gridPaint,
      );
    }

    double columnSpace = chartRect.width / gridColumns;
    for (int i = 0; i <= columnSpace; i++) {
      canvas.drawLine(
        Offset(columnSpace * i, topPadding / 3),
        Offset(columnSpace * i, chartRect.bottom),
        gridPaint,
      );
    }
  }

  @override
  double getY(double y) {
    return (maxValue - y) * scaleY + _contentRect.top;
  }
}
