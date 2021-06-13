import 'dart:async' show StreamSink;

import 'package:flutter/material.dart';
import '../entity/k_line_entity.dart';
import '../k_chart_widget.dart';
import '../utils/date_format_util.dart';
import '../entity/info_window_entity.dart';

import 'base_chart_painter.dart';
import 'base_chart_renderer.dart';
import 'main_renderer.dart';

class ChartPainter extends BaseChartPainter {
  static get maxScrollX => BaseChartPainter.maxScrollX;

  final ChartColors chartColors;
  final ChartStyle chartStyle;

  BaseChartRenderer? mMainRenderer;
  StreamSink<InfoWindowEntity?>? sink;
  List<Color>? bgColor;
  late Paint selectPointPaint, selectorBorderPaint;

  final List<String> datetimeFormat;
  final KChartLanguage language;
  final String Function(double) priceFormatter;

  final int gridRows;
  final int gridColumns;

  ChartPainter(
    this.chartStyle,
    this.chartColors, {
    required List<KLineEntity> datas,
    required double scaleX,
    required double scrollX,
    required bool isLongPass,
    required double selectX,
    required this.datetimeFormat,
    required this.priceFormatter,
    required this.language,
    required this.gridRows,
    required this.gridColumns,
    this.sink,
    required bool isLine,
    this.bgColor,
  })  : assert(bgColor == null || bgColor.length >= 2),
        super(
          chartStyle,
          datas: datas,
          scaleX: scaleX,
          scrollX: scrollX,
          isLongPress: isLongPass,
          selectX: selectX,
          isLine: isLine,
        ) {
    selectPointPaint = Paint()
      ..isAntiAlias = true
      ..strokeWidth = 0.5
      ..color = chartColors.selectFillColor;

    selectorBorderPaint = Paint()
      ..isAntiAlias = true
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke
      ..color = chartColors.selectBorderColor;
  }

  @override
  void initChartRenderer() {
    mMainRenderer ??= MainRenderer(
      mMainRect,
      mMainMaxValue,
      mMainMinValue,
      mTopPadding,
      isLine,
      chartStyle,
      chartColors,
      priceFormatter,
      gridRows: gridRows,
      gridColumns: gridColumns,
    );
  }

  @override
  void drawBg(Canvas canvas, Size size) {
    final mBgPaint = Paint();
    final mBgGradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: bgColor ?? [Color(0xff18191d), Color(0xff18191d)],
    );

    final mainRect = Rect.fromLTRB(
      0,
      0,
      mMainRect.width,
      mMainRect.height + mTopPadding,
    );

    canvas.drawRect(
      mainRect,
      mBgPaint..shader = mBgGradient.createShader(mainRect),
    );

    final dateRect = Rect.fromLTRB(
      0,
      size.height - mBottomPadding,
      size.width,
      size.height,
    );

    canvas.drawRect(
      dateRect,
      mBgPaint..shader = mBgGradient.createShader(dateRect),
    );
  }

  @override
  void drawGrid(canvas) {
    mMainRenderer?.drawGrid(canvas, gridRows, gridColumns);
  }

  @override
  void drawChart(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(mTranslateX * scaleX, 0.0);
    canvas.scale(scaleX, 1.0);
    for (int i = mStartIndex; i <= mStopIndex; i++) {
      KLineEntity curPoint = datas[i];
      KLineEntity lastPoint = i == 0 ? curPoint : datas[i - 1];
      double curX = getX(i);
      double lastX = i == 0 ? curX : getX(i - 1);

      mMainRenderer?.drawChart(lastPoint, curPoint, lastX, curX, size, canvas);
    }

    if (isLongPress == true) drawCrossLine(canvas, size);
    canvas.restore();
  }

  @override
  void drawRightText(canvas) {
    var textStyle = getTextStyle(this.chartColors.defaultTextColor);
    mMainRenderer?.drawRightText(canvas, textStyle, gridRows);
  }

  @override
  void drawDate(Canvas canvas, Size size) {
    double columnSpace = size.width / gridColumns;
    double startX = getX(mStartIndex) - mPointWidth / 2;
    double stopX = getX(mStopIndex) + mPointWidth / 2;
    double y = 0.0;

    for (var i = 0; i <= gridColumns; ++i) {
      double translateX = xToTranslateX(columnSpace * i);
      if (translateX >= startX && translateX <= stopX) {
        int index = indexOfTranslateX(translateX);
        TextPainter tp = getTextPainter(getDate(datas[index].time!), null);
        y = size.height - (mBottomPadding - tp.height) / 2 - tp.height;
        tp.paint(canvas, Offset(columnSpace * i - tp.width / 2, y));
      }
    }

//    double translateX = xToTranslateX(0);
//    if (translateX >= startX && translateX <= stopX) {
//      TextPainter tp = getTextPainter(getDate(datas[mStartIndex].id));
//      tp.paint(canvas, Offset(0, y));
//    }
//    translateX = xToTranslateX(size.width);
//    if (translateX >= startX && translateX <= stopX) {
//      TextPainter tp = getTextPainter(getDate(datas[mStopIndex].id));
//      tp.paint(canvas, Offset(size.width - tp.width, y));
//    }
  }

  @override
  void drawCrossLineText(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    KLineEntity point = getItem(index) as KLineEntity;

    TextPainter tp = getTextPainter(point.close, Colors.white);
    double textHeight = tp.height;
    double textWidth = tp.width;

    double w1 = 5;
    double w2 = 3;
    double r = textHeight / 2 + w2;
    double y = getMainY(point.close);
    double x;
    bool isLeft = false;
    if (translateXtoX(getX(index)) < mWidth / 2) {
      isLeft = false;
      x = 1;
      final path = Path();
      path.moveTo(x, y - r);
      path.lineTo(x, y + r);
      path.lineTo(textWidth + 2 * w1, y + r);
      path.lineTo(textWidth + 2 * w1 + w2, y);
      path.lineTo(textWidth + 2 * w1, y - r);
      path.close();

      canvas.drawPath(path, selectPointPaint);
      canvas.drawPath(path, selectorBorderPaint);

      tp.paint(canvas, Offset(x + w1, y - textHeight / 2));
    } else {
      isLeft = true;
      x = mWidth - textWidth - 1 - 2 * w1 - w2;
      final path = Path();
      path.moveTo(x, y);
      path.lineTo(x + w2, y + r);
      path.lineTo(mWidth - 2, y + r);
      path.lineTo(mWidth - 2, y - r);
      path.lineTo(x + w2, y - r);
      path.close();

      canvas.drawPath(path, selectPointPaint);
      canvas.drawPath(path, selectorBorderPaint);

      tp.paint(canvas, Offset(x + w1 + w2, y - textHeight / 2));
    }

    TextPainter dateTp = getTextPainter(getDate(point.time!), Colors.white);
    textWidth = dateTp.width;
    r = textHeight / 2;
    x = translateXtoX(getX(index));
    y = size.height - mBottomPadding;

    if (x < textWidth + 2 * w1) {
      x = 1 + textWidth / 2 + w1;
    } else if (mWidth - x < textWidth + 2 * w1) {
      x = mWidth - 1 - textWidth / 2 - w1;
    }
    double baseLine = textHeight / 2;
    canvas.drawRect(
        Rect.fromLTRB(x - textWidth / 2 - w1, y, x + textWidth / 2 + w1,
            y + baseLine + r),
        selectPointPaint);
    canvas.drawRect(
        Rect.fromLTRB(x - textWidth / 2 - w1, y, x + textWidth / 2 + w1,
            y + baseLine + r),
        selectorBorderPaint);

    dateTp.paint(canvas, Offset(x - textWidth / 2, y));
    //长按显示这条数据详情
    sink?.add(InfoWindowEntity(point, isLeft));
  }

  @override
  void drawText(Canvas canvas, KLineEntity data, double x) {
    //长按显示按中的数据
    if (isLongPress) {
      var index = calculateSelectedX(selectX);
      data = getItem(index) as KLineEntity;
    }
    //松开显示最后一条数据
    mMainRenderer?.drawText(canvas, data, x);
  }

  @override
  void drawMaxAndMin(Canvas canvas) {
    if (isLine == true) return;
    //绘制最大值和最小值
    double x = translateXtoX(getX(mMainMinIndex));
    double y = getMainY(mMainLowMinValue);
    if (x < mWidth / 2) {
      //画右边
      final tp = getTextPainter(
        "── " + priceFormatter(mMainLowMinValue),
        chartColors.downCandleColor,
      );
      tp.paint(canvas, Offset(x, y - tp.height / 2));
    } else {
      final tp = getTextPainter(
        priceFormatter(mMainLowMinValue) + " ──",
        chartColors.downCandleColor,
      );
      tp.paint(canvas, Offset(x - tp.width, y - tp.height / 2));
    }
    x = translateXtoX(getX(mMainMaxIndex));
    y = getMainY(mMainHighMaxValue);
    if (x < mWidth / 2) {
      //画右边
      final tp = getTextPainter(
        "── " + priceFormatter(mMainHighMaxValue),
        chartColors.upCandleColor,
      );

      tp.paint(canvas, Offset(x, y - tp.height / 2));
    } else {
      final tp = getTextPainter(
        priceFormatter(mMainHighMaxValue) + " ──",
        chartColors.upCandleColor,
      );

      tp.paint(canvas, Offset(x - tp.width, y - tp.height / 2));
    }
  }

  @override
  void drawNowPrice(Canvas canvas) {
    if (isLine == true) return;
    double x = translateXtoX(getX(datas.length - 1));
    double value = datas[datas.length - 1].close;
    double y = getMainY(value);

    final getNowPriceTextSpan = (text) {
      final color = chartColors.nowPriceColor;
      final span = TextSpan(
        text: "$text",
        style: getTextStyle(color),
      );
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();
      return tp;
    };

    final tp = getNowPriceTextSpan("─ " + priceFormatter(value));
    tp.paint(canvas, Offset(x, y - tp.height / 2));
  }

  ///画交叉线
  void drawCrossLine(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    KLineEntity point = getItem(index) as KLineEntity;
    final selectionColor = chartColors.selectBorderColor.withAlpha(100);
    Paint paintY = Paint()
      ..color = selectionColor
      ..strokeWidth = this.chartStyle.vCrossWidth
      ..isAntiAlias = true;
    double x = getX(index);
    double y = getMainY(point.close);
    // k线图竖线
    canvas.drawLine(Offset(x, mTopPadding),
        Offset(x, size.height - mBottomPadding), paintY);

    Paint paintX = Paint()
      ..color = selectionColor
      ..strokeWidth = this.chartStyle.hCrossWidth
      ..isAntiAlias = true;
    // k线图横线
    canvas.drawLine(Offset(-mTranslateX, y),
        Offset(-mTranslateX + mWidth / scaleX, y), paintX);
    canvas.drawCircle(Offset(x, y), 2.0, paintX);
  }

  TextPainter getTextPainter(text, color) {
    if (color == null) {
      color = this.chartColors.defaultTextColor;
    }
    TextSpan span = TextSpan(text: "$text", style: getTextStyle(color));
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    return tp;
  }

  String getDate(int date) => dateFormat(
        DateTime.fromMillisecondsSinceEpoch(date),
        datetimeFormat,
        language,
      );

  double getMainY(double y) => mMainRenderer?.getY(y) ?? 0.0;
}
