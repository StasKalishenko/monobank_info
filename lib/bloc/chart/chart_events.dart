import '../../statementInfo.dart';

abstract class ChartEvent {}

class ChartLoadEvent extends ChartEvent {
  final List<StatementInfo> statements;

  ChartLoadEvent(this.statements);

}