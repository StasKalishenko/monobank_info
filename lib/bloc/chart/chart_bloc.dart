import 'package:bloc/bloc.dart';
import 'package:charts_flutter/flutter.dart';

import '../../expences.dart';
import '../../statementInfo.dart';
import '../../utils.dart';
import 'chart_events.dart';
import 'chart_state.dart';

class ChartBloc extends Bloc<ChartEvent, ChartState> {
  List<StatementInfo> _chartStatements = [];
  final int _truncLimit = 30;

  @override
  ChartState get initialState => ChartState.initial();

  @override
  Stream<ChartState> mapEventToState(ChartEvent event) async* {
    if (event is ChartLoadEvent) {
      List<Series<Expenses, String>> series =
          _calculateChartData(event.statements);
      yield ChartState(series: series);
    }
  }

  List<Series<Expenses, String>> _calculateChartData(
      List<StatementInfo> allStatements) {
    _copyStatements(allStatements, _chartStatements);
    var groupedStatements = {};
    Set<StatementInfo> set = Set.from(allStatements);
    double total = 0;
    set.forEach((StatementInfo statement) {
      String mcc = new Utils().getMCC(statement.mcc.toString());
      if (mcc != null) {
        mcc = mcc.toLowerCase();
        double amount = statement.amount / 100;
        if (amount < 0) {
          amount = -1 * amount;
          groupedStatements[mcc] = groupedStatements[mcc] != null
              ? groupedStatements[mcc] + amount
              : amount;
          total += amount;
        }
      }
    });
    List<Expenses> data = _getChartData(groupedStatements, total);
    return [
      new Series<Expenses, String>(
        id: 'Expenses',
        domainFn: (Expenses expenses, _) => expenses.mcc,
        measureFn: (Expenses expenses, _) => expenses.value,
        data: data,
      )
    ];
  }

  List<StatementInfo> _copyStatements(source, target) {
    Set<StatementInfo> set = Set.from(source);
    target.clear();
    set.forEach((StatementInfo statement) {
      target.add(statement);
    });
    return target;
  }

  List<Expenses> _getChartData(groupedData, total) {
    List<Expenses> data = [];
    int totalPercent = 0;
    groupedData.forEach((mcc, amount) {
      int percent = ((amount / total) * 100).round();
      if (mcc.length > _truncLimit) {
        mcc = mcc.substring(0, _truncLimit - 3) + "...";
      }
      if (percent > 0) {
        data.add(
            new Expenses(mcc + " " + amount.toStringAsFixed(2) + "₴", percent));
        totalPercent += percent;
      }
    });
    if (totalPercent < 100) {
      data.add(new Expenses("другое", 100 - totalPercent));
    }
    data..sort((a, b) => b.value.compareTo(a.value));
    return data;
  }
}
