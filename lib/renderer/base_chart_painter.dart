import 'dart:math';
export 'package:flutter/material.dart'
    show Color, TextStyle, Rect, Canvas, Size, CustomPainter;
import 'package:flutter/material.dart'
    show Color, TextStyle, Rect, Canvas, Size, CustomPainter;
import '../entity/k_line_entity.dart';
import '../chart_style.dart' show ChartStyle;

abstract class BaseChartPainter extends CustomPainter {
  static double maxScrollX = 0.0;

  final List<KLineEntity> datas;
  final double scaleX, scrollX, selectX;
  final bool isLongPress;
  final bool isLine;

  late Rect mMainRect;
  late double mDisplayHeight, mWidth;

  final double mTopPadding = 1.0, mBottomPadding = 20.0, mChildPadding = 0.0;
  int mStartIndex = 0, mStopIndex = 0;
  double mMainMaxValue = double.minPositive, mMainMinValue = double.maxFinite;
  double mTranslateX = double.minPositive;
  int mMainMaxIndex = 0, mMainMinIndex = 0;
  double mMainHighMaxValue = double.minPositive,
      mMainLowMinValue = double.maxFinite;
  int mItemCount = 0;
  double mDataLen = 0.0; // Data occupies the total length of the screen
  final ChartStyle chartStyle;
  late double mPointWidth;

  BaseChartPainter(
    this.chartStyle, {
    required this.datas,
    required this.selectX,
    this.isLongPress = false,
    this.isLine = false,
    this.scaleX = 1.0,
    this.scrollX = 0.0,
  }) {
    mItemCount = datas.length;
    mPointWidth = this.chartStyle.pointWidth;
    mDataLen = mItemCount * mPointWidth + (isLine ? 0.0 : 64.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    mDisplayHeight = size.height - mTopPadding - mBottomPadding;
    mWidth = size.width;
    initRect(size);
    calculateValue();
    initChartRenderer();

    canvas.save();
    canvas.scale(1, 1);
    drawBg(canvas, size);
    drawGrid(canvas);

    if (datas.isNotEmpty) {
      drawChart(canvas, size);
      drawNowPrice(canvas);
      drawRightText(canvas);
      drawDate(canvas, size);
      if (isLongPress == true) drawCrossLineText(canvas, size);
      drawText(canvas, datas.last, 5);
      drawMaxAndMin(canvas);
    }

    canvas.restore();
  }

  void initChartRenderer();

  //画背景
  void drawBg(Canvas canvas, Size size);

  //画网格
  void drawGrid(canvas);

  //画图表
  void drawChart(Canvas canvas, Size size);

  //画右边值
  void drawRightText(canvas);

  //画时间
  void drawDate(Canvas canvas, Size size);

  //画值
  void drawText(Canvas canvas, KLineEntity data, double x);

  //画最大最小值
  void drawMaxAndMin(Canvas canvas);

  //画当前价格
  void drawNowPrice(Canvas canvas);

  //交叉线值
  void drawCrossLineText(Canvas canvas, Size size);

  void initRect(Size size) {
    final mainHeight = mDisplayHeight;

    mMainRect = Rect.fromLTRB(
      0,
      mTopPadding,
      mWidth,
      mTopPadding + mainHeight,
    );
  }

  calculateValue() {
    if (datas.isEmpty) return;

    maxScrollX = getMinTranslateX().abs();
    setTranslateXFromScrollX(scrollX);
    mStartIndex = indexOfTranslateX(xToTranslateX(0));
    mStopIndex = indexOfTranslateX(xToTranslateX(mWidth));

    for (int i = mStartIndex; i <= mStopIndex; i++) {
      final item = datas[i];
      getMainMaxMinValue(item, i);
    }
  }

  void getMainMaxMinValue(KLineEntity item, int i) {
    if (isLine == true) {
      mMainMaxValue = max(mMainMaxValue, item.close);
      mMainMinValue = min(mMainMinValue, item.close);
    } else {
      double maxPrice = item.high, minPrice = item.low;
      mMainMaxValue = max(mMainMaxValue, maxPrice);
      mMainMinValue = min(mMainMinValue, minPrice);

      if (mMainHighMaxValue < item.high) {
        mMainHighMaxValue = item.high;
        mMainMaxIndex = i;
      }
      if (mMainLowMinValue > item.low) {
        mMainLowMinValue = item.low;
        mMainMinIndex = i;
      }
    }
  }

  double xToTranslateX(double x) => -mTranslateX + x / scaleX;

  int indexOfTranslateX(double translateX) =>
      _indexOfTranslateX(translateX, 0, mItemCount - 1);

  ///二分查找当前值的index (Find the index of the current value binary)
  int _indexOfTranslateX(double translateX, int start, int end) {
    if (end == start || end == -1) {
      return start;
    }
    if (end - start == 1) {
      double startValue = getX(start);
      double endValue = getX(end);
      return (translateX - startValue).abs() < (translateX - endValue).abs()
          ? start
          : end;
    }
    int mid = start + (end - start) ~/ 2;
    double midValue = getX(mid);
    if (translateX < midValue) {
      return _indexOfTranslateX(translateX, start, mid);
    } else if (translateX > midValue) {
      return _indexOfTranslateX(translateX, mid, end);
    } else {
      return mid;
    }
  }

  ///根据索引索取x坐标
  ///+ mPointWidth / 2防止第一根和最后一根k线显示不���
  ///@param position 索引值
  ///
  /// Acquire the x coordinate according to the index
  /// + mPointWidth / 2 Prevent the first and last bar from being displayed incorrectly
  /// @param position index value
  double getX(int position) => position * mPointWidth + mPointWidth / 2;

  Object getItem(int position) {
    return datas[position];
  }

  ///scrollX 转换为 TranslateX
  void setTranslateXFromScrollX(double scrollX) =>
      mTranslateX = scrollX + getMinTranslateX();

  ///获取平移的最小值
  double getMinTranslateX() {
    var x = -mDataLen + mWidth / scaleX - mPointWidth / 2;
    return x >= 0 ? 0.0 : x;
  }

  ///计算长按后x的值，转换为index
  int calculateSelectedX(double selectX) {
    int mSelectedIndex = indexOfTranslateX(xToTranslateX(selectX));
    if (mSelectedIndex < mStartIndex) {
      mSelectedIndex = mStartIndex;
    }
    if (mSelectedIndex > mStopIndex) {
      mSelectedIndex = mStopIndex;
    }
    return mSelectedIndex;
  }

  ///translateX转化为view中的x
  double translateXtoX(double translateX) =>
      (translateX + mTranslateX) * scaleX;

  TextStyle getTextStyle(Color color) {
    return TextStyle(fontSize: 10.0, color: color);
  }

  @override
  bool shouldRepaint(BaseChartPainter oldDelegate) {
    return true;
//    return oldDelegate.datas != datas ||
//        oldDelegate.datas?.length != datas?.length ||
//        oldDelegate.scaleX != scaleX ||
//        oldDelegate.scrollX != scrollX ||
//        oldDelegate.isLongPress != isLongPress ||
//        oldDelegate.selectX != selectX ||
//        oldDelegate.isLine != isLine ||
//        oldDelegate.mainState != mainState ||
//        oldDelegate.secondaryState != secondaryState;
  }
}
