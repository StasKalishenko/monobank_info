import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class DatumLegendWithMeasures extends StatelessWidget {
  final List<charts.Series> seriesList;
  final bool animate;

  DatumLegendWithMeasures(this.seriesList, {this.animate});

  @override
  Widget build(BuildContext context) {
    return new charts.PieChart(
      seriesList,
      animate: animate,
      layoutConfig: charts.LayoutConfig(topMarginSpec: charts.MarginSpec.fixedPixel(150),
        leftMarginSpec: charts.MarginSpec.fixedPixel(14),
        rightMarginSpec: charts.MarginSpec.fixedPixel(14),
        bottomMarginSpec: charts.MarginSpec.fixedPixel(0)),
      behaviors: [
        new charts.DatumLegend(
          position: charts.BehaviorPosition.inside,
          horizontalFirst: false,
          cellPadding: new EdgeInsets.only(top: 5, left: 5.0),
          showMeasures: true,
          legendDefaultMeasure: charts.LegendDefaultMeasure.firstValue,
          measureFormatter: (num value) {
            return value == null ? '-' : '($value%)';
          },
        ),
      ],
    );
  }
}

class Expenses {
  final String mcc;
  final int value;

  Expenses(this.mcc, this.value);
}