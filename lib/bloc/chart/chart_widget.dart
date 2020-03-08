import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'chart_bloc.dart';
import 'chart_state.dart';

class ChartWidget extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChartBloc, ChartState>(
        builder: (context, ChartState state) {
      return new charts.PieChart(
        state.series,
        animate: state.animate,
        layoutConfig: charts.LayoutConfig(
            topMarginSpec: charts.MarginSpec.fixedPixel(150),
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
    });
  }
}