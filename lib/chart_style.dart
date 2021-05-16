import 'package:flutter/material.dart' show Color;

class ChartColors {
  Color kLineColor = Color(0xff4C86CD);
  Color lineFillColor = Color(0x554C86CD);

  Color upCandleColor = Color(0xff4DAA90);
  Color downCandleColor = Color(0xffC15466);

  Color defaultTextColor = Color(0xff60738E);
  Color nowPriceColor = Color(0xffC9B885);

  Color selectBorderColor = Color(0xff6C7A86);
  Color selectFillColor = Color(0xff0D1722);
}

class ChartStyle {
  double pointWidth = 11.0;
  double candleWidth = 8.5;
  double candleLineWidth = 1.5;
  double vCrossWidth = 8.5;
  double hCrossWidth = 0.5;
}
