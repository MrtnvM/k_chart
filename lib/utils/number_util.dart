import 'dart:math';

class NumberUtil {
  static String format(double n) {
    if (n >= 10000) {
      n /= 1000;
      return "${n.toStringAsFixed(2)}K";
    }

    return n.toStringAsFixed(4);
  }

  static int getDecimalLength(double b) {
    String s = b.toString();
    int dotIndex = s.indexOf(".");
    if (dotIndex < 0) {
      return 0;
    }

    return s.length - dotIndex - 1;
  }

  static int getMaxDecimalLength(double a, double b, double c, double d) {
    int result = max(getDecimalLength(a), getDecimalLength(b));
    result = max(result, getDecimalLength(c));
    result = max(result, getDecimalLength(d));
    return result;
  }

  static bool checkNotNullOrZero(double a) {
    if (a == 0) {
      return false;
    }

    if (a.abs().toStringAsFixed(4) == "0.0000") {
      return false;
    }

    return true;
  }
}
