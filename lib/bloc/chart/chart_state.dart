import 'package:charts_flutter/flutter.dart';

import '../../expences.dart';

class ChartState {
  final List<Series<Expenses, String>> series;
  final bool animate;

  const ChartState({this.series, this.animate});

  factory ChartState.initial() => ChartState(series: null, animate: false);
}