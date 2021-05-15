import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:k_chart/chart_style.dart';
import 'package:k_chart/flutter_k_chart.dart';
import 'package:k_chart/k_chart_widget.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Candlestick Chart',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MyHomePage(title: 'Candlestick Chart'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<KLineEntity> datas;
  bool showLoading = true;
  bool isLine = true;
  bool isChinese = true;

  ChartStyle chartStyle = new ChartStyle();
  ChartColors chartColors = new ChartColors();

  @override
  void initState() {
    super.initState();
    getData('1day');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff17212F),
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        children: <Widget>[
          Stack(
            children: <Widget>[
              Container(
                height: 450,
                width: double.infinity,
                child: KChartWidget(
                  datas,
                  chartStyle,
                  chartColors,
                  isLine: isLine,
                  fixedLength: 2,
                  timeFormat: TimeFormat.YEAR_MONTH_DAY,
                  isChinese: isChinese,
                ),
              ),
              if (showLoading)
                Container(
                  width: double.infinity,
                  height: 450,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
          buildButtons(),
        ],
      ),
    );
  }

  Widget buildButtons() {
    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      children: <Widget>[
        button("Candlestick Chart", onPressed: () => isLine = true),
        button("Line Chart", onPressed: () => isLine = false),
        button("Change language", onPressed: () => isChinese = !isChinese),
        button("Customize UI", onPressed: () {
          setState(() {
            chartColors.selectBorderColor = Colors.red;
            chartColors.selectFillColor = Colors.red;
            chartColors.lineFillColor = Colors.red;
            chartColors.kLineColor = Colors.yellow;
          });
        }),
      ],
    );
  }

  Widget button(String text, {VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: () {
        if (onPressed != null) {
          onPressed();
          setState(() {});
        }
      },
      child: Text("$text"),
    );
  }

  void getData(String period) {
    Future<String> future = getIPAddress('$period');
    future.then((result) {
      Map parseJson = json.decode(result);
      List list = parseJson['data'];
      datas = list
          .map((item) => KLineEntity.fromJson(item))
          .toList()
          .reversed
          .toList()
          .cast<KLineEntity>();
      showLoading = false;
      setState(() {});
    }).catchError((error) {
      showLoading = false;
      setState(() {});
      print('Error: $error');
    });
  }

  //获取火币数据，需要翻墙
  Future<String> getIPAddress(String period) async {
    var url = 'https://api.huobi.br.com/market/history/kline'
        '?period=${period ?? '1day'}&size=300&symbol=btcusdt';

    String result;
    var response = await http.get(url);
    if (response.statusCode == 200) {
      result = response.body;
    } else {
      print('Failed getting IP address');
    }

    return result;
  }
}
