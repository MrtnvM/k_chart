import 'dart:async';

import 'package:flutter/material.dart';
import 'package:k_chart/flutter_k_chart.dart';
import 'chart_style.dart';
import 'entity/info_window_entity.dart';
import 'entity/k_line_entity.dart';
import 'renderer/chart_painter.dart';
import 'utils/date_format_util.dart';

enum KChartLanguage { russian, english }

class TimeFormat {
  static const YEAR_MONTH_DAY = [yyyy, '-', mm, '-', dd];
  static const YEAR_MONTH_DAY_WITH_HOUR = [
    yyyy,
    '-',
    mm,
    '-',
    dd,
    ' ',
    HH,
    ':',
    nn
  ];
}

enum InfoWindowElement {
  date,
  open,
  high,
  low,
  close,
  change,
  changePercent,
  amount
}

const defaultInfoWindowElements = [
  InfoWindowElement.date,
  InfoWindowElement.open,
  InfoWindowElement.high,
  InfoWindowElement.low,
  InfoWindowElement.close,
  InfoWindowElement.changePercent,
];

typedef PriceFormatter = String Function(double);

class KChartWidget extends StatefulWidget {
  final List<KLineEntity> datas;
  final bool isLine;
  final List<String> timeFormat;
  final Function(bool)? onLoadMore;
  final List<Color>? bgColor;
  final List<int> maDayList;
  final int flingTime;
  final double flingRatio;
  final Curve flingCurve;
  final Function(bool)? isOnDrag;
  final ChartColors chartColors;
  final ChartStyle chartStyle;

  final KChartLanguage language;
  final List<String> dateFormat;
  final List<String> infoWindowDateFormat;
  final List<InfoWindowElement> infoWindowElements;
  final PriceFormatter priceFormatter;

  KChartWidget(
    this.datas,
    this.chartStyle,
    this.chartColors, {
    required this.isLine,
    required this.priceFormatter,
    this.timeFormat = TimeFormat.YEAR_MONTH_DAY,
    this.onLoadMore,
    this.bgColor,
    this.maDayList = const [5, 10, 20],
    this.flingTime = 600,
    this.flingRatio = 0.5,
    this.flingCurve = Curves.decelerate,
    this.isOnDrag,
    this.dateFormat = TimeFormat.YEAR_MONTH_DAY,
    this.infoWindowDateFormat = TimeFormat.YEAR_MONTH_DAY,
    this.infoWindowElements = defaultInfoWindowElements,
    this.language = KChartLanguage.english,
  });

  @override
  _KChartWidgetState createState() => _KChartWidgetState();
}

class _KChartWidgetState extends State<KChartWidget>
    with TickerProviderStateMixin {
  double _scaleX = 1.0, _scrollX = 0.0, _selectX = 0.0;
  StreamController<InfoWindowEntity?>? _infoWindowStream;

  AnimationController? _controller;
  Animation<double>? aniX;

  PriceFormatter get priceFormatter => widget.priceFormatter;

  double getMinScrollX() {
    return _scaleX;
  }

  double _lastScale = 1.0;
  bool _isScale = false, _isDrag = false, _isLongPress = false;

  @override
  void initState() {
    super.initState();
    _infoWindowStream = StreamController<InfoWindowEntity?>();
  }

  @override
  void dispose() {
    _infoWindowStream?.close();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.datas.isEmpty) {
      _scrollX = _selectX = 0.0;
      _scaleX = 1.0;
    }

    final _painter = ChartPainter(
      widget.chartStyle,
      widget.chartColors,
      datas: widget.datas,
      scaleX: _scaleX,
      scrollX: _scrollX,
      selectX: _selectX,
      isLongPass: _isLongPress,
      isLine: widget.isLine,
      sink: _infoWindowStream?.sink,
      bgColor: widget.bgColor,
      datetimeFormat: widget.dateFormat,
      language: widget.language,
      priceFormatter: widget.priceFormatter,
    );

    return ClipRRect(
      child: Padding(
        padding: const EdgeInsets.only(left: 0.5, right: 0.5),
        child: GestureDetector(
          onHorizontalDragDown: (details) {
            _stopAnimation();
            _onDragChanged(true);
          },
          onHorizontalDragUpdate: (details) {
            final primaryDelta = details.primaryDelta;
            if (_isScale || _isLongPress || primaryDelta == null) return;

            _scrollX = (primaryDelta / _scaleX + _scrollX)
                .clamp(0.0, ChartPainter.maxScrollX) as double;
            notifyChanged();
          },
          onHorizontalDragEnd: (DragEndDetails details) {
            var velocity = details.velocity.pixelsPerSecond.dx;
            _onFling(velocity);
          },
          onHorizontalDragCancel: () => _onDragChanged(false),
          onScaleStart: (_) {
            _isScale = true;
          },
          onScaleUpdate: (details) {
            if (_isDrag || _isLongPress) return;
            _scaleX = (_lastScale * details.scale).clamp(0.5, 2.2);
            notifyChanged();
          },
          onScaleEnd: (_) {
            _isScale = false;
            _lastScale = _scaleX;
          },
          onLongPressStart: (details) {
            _isLongPress = true;
            if (_selectX != details.globalPosition.dx) {
              _selectX = details.globalPosition.dx;
              notifyChanged();
            }
          },
          onLongPressMoveUpdate: (details) {
            if (_selectX != details.globalPosition.dx) {
              _selectX = details.globalPosition.dx;
              notifyChanged();
            }
          },
          onLongPressEnd: (details) {
            _isLongPress = false;
            _infoWindowStream?.sink.add(null);
            notifyChanged();
          },
          child: Stack(
            children: <Widget>[
              CustomPaint(
                size: Size(double.infinity, double.infinity),
                painter: _painter,
              ),
              _buildInfoDialog()
            ],
          ),
        ),
      ),
    );
  }

  void _stopAnimation({bool needNotify = true}) {
    final controller = _controller;

    if (controller != null && controller.isAnimating) {
      controller.stop();
      _onDragChanged(false);
      if (needNotify) {
        notifyChanged();
      }
    }
  }

  void _onDragChanged(bool isOnDrag) {
    _isDrag = isOnDrag;
    if (widget.isOnDrag != null) {
      widget.isOnDrag?.call(_isDrag);
    }
  }

  void _onFling(double x) {
    final controller = AnimationController(
      duration: Duration(milliseconds: widget.flingTime),
      vsync: this,
    );

    _controller = controller;

    aniX = null;
    aniX = Tween<double>(
      begin: _scrollX,
      end: x * widget.flingRatio + _scrollX,
    ).animate(
      CurvedAnimation(parent: controller, curve: widget.flingCurve),
    );

    aniX!.addListener(() {
      _scrollX = aniX!.value;
      if (_scrollX <= 0) {
        _scrollX = 0;
        if (widget.onLoadMore != null) {
          widget.onLoadMore!(true);
        }
        _stopAnimation();
      } else if (_scrollX >= ChartPainter.maxScrollX) {
        _scrollX = ChartPainter.maxScrollX;
        if (widget.onLoadMore != null) {
          widget.onLoadMore!(false);
        }
        _stopAnimation();
      }
      notifyChanged();
    });

    aniX!.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _onDragChanged(false);
        notifyChanged();
      }
    });

    _controller!.forward();
  }

  void notifyChanged() => setState(() {});

  final infoNamesEN = {
    InfoWindowElement.date: "Date",
    InfoWindowElement.open: "Open",
    InfoWindowElement.high: "High",
    InfoWindowElement.low: "Low",
    InfoWindowElement.close: "Close",
    InfoWindowElement.change: "Change",
    InfoWindowElement.changePercent: "Change %",
    InfoWindowElement.amount: "Amount"
  };

  final infoNamesRU = {
    InfoWindowElement.date: "Дата",
    InfoWindowElement.open: "Откр.",
    InfoWindowElement.high: "Макс.",
    InfoWindowElement.low: "Мин.",
    InfoWindowElement.close: "Закр.",
    InfoWindowElement.change: "Изм.",
    InfoWindowElement.changePercent: "Изм. %",
    InfoWindowElement.amount: "Колич."
  };

  late List<String> infos;

  Widget _buildInfoDialog() {
    return StreamBuilder<InfoWindowEntity?>(
      stream: _infoWindowStream?.stream,
      builder: _buildInfoWindowContent,
    );
  }

  Widget _buildInfoWindowContent(context, snapshot) {
    if (!_isLongPress ||
        widget.isLine == true ||
        !snapshot.hasData ||
        snapshot.data.kLineEntity == null) return Container();

    KLineEntity e = snapshot.data.kLineEntity;
    double upDown = e.change ?? e.close - e.open;
    double upDownPercent = e.ratio ?? (upDown / e.open) * 100;

    final infoGrabbers = {
      InfoWindowElement.date: () => _getInfoWindowDate(e.time),
      InfoWindowElement.open: () => priceFormatter(e.open),
      InfoWindowElement.high: () => priceFormatter(e.high),
      InfoWindowElement.low: () => priceFormatter(e.low),
      InfoWindowElement.close: () => priceFormatter(e.close),
      InfoWindowElement.change: () =>
          "${upDown > 0 ? "+" : ""}${priceFormatter(upDown)}",
      InfoWindowElement.changePercent: () =>
          "${upDownPercent > 0 ? "+" : ''}${upDownPercent.toStringAsFixed(2)}%",
      InfoWindowElement.amount: () => e.amount?.toInt().toString(),
    };

    final infoNames = {
      KChartLanguage.english: infoNamesEN,
      KChartLanguage.russian: infoNamesRU,
    }[widget.language]!;

    final infos = widget.infoWindowElements //
        .map((e) => [infoGrabbers[e]?.call(), infoNames[e]])
        .toList();

    const infoWindowWidth = 148.0;

    final infoWindow = Container(
      width: infoWindowWidth,
      decoration: BoxDecoration(
        color: widget.chartColors.selectFillColor,
        border: Border.all(
          color: widget.chartColors.selectBorderColor,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: infos.length,
        shrinkWrap: true,
        itemBuilder: (_, i) => _buildItem(infos[i][0]!, infos[i][1]!),
      ),
    );

    return Stack(
      children: [
        Positioned(
          top: 4,
          left: snapshot.data.isLeft ? 4 : null,
          right: !snapshot.data.isLeft ? 4 : null,
          child: infoWindow,
        )
      ],
    );
  }

  Widget _buildItem(String info, String infoName) {
    Color color = Colors.white;
    if (info.startsWith("+"))
      color = Colors.green;
    else if (info.startsWith("-"))
      color = Colors.red;
    else
      color = Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Text(
              "$infoName",
              style: const TextStyle(
                color: Color(0xFF9499A2),
                fontSize: 12.0,
              ),
            ),
          ),
          Text(
            info,
            style: TextStyle(
              color: color,
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String getDate(int date) {
    return dateFormat(
      DateTime.fromMillisecondsSinceEpoch(date),
      widget.dateFormat,
      widget.language,
    );
  }

  String _getInfoWindowDate(int? date) {
    if (date == null) {
      return '-';
    }

    final format = widget.infoWindowDateFormat;
    return dateFormat(
      DateTime.fromMillisecondsSinceEpoch(date),
      format,
      widget.language,
    );
  }
}
