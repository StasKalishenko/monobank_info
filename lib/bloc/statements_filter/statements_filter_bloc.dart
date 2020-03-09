import 'package:bloc/bloc.dart';
import 'package:monobank_info/statementInfo.dart';
import 'package:monobank_info/utils.dart';

import 'statements_filter_events.dart';
import 'statements_filter_state.dart';

class StatementsFilterBloc
    extends Bloc<StatementsFilterEvent, StatementsFilterState> {
  List<StatementInfo> _filteredStatements = [];

  @override
  StatementsFilterState get initialState => StatementsFilterState.initial();

  @override
  Stream<StatementsFilterState> mapEventToState(
      StatementsFilterEvent event) async* {
    if (event is StatementsFilterInitEvent) {
      yield StatementsFilterState(controller: event.controller);
    }
  }

  List<StatementInfo> getFilteredStatements(List<StatementInfo> statements, String filter) {
    _filteredStatements = _getCopy(statements);
      if (filter != "") {
        _filteredStatements = _filterStatements(_filteredStatements, filter);
      }
    return _filteredStatements;
  }

  List<StatementInfo> _getCopy(source) {
    List<StatementInfo> target = [];
    Set<StatementInfo> set = Set.from(source);
    target.clear();
    set.forEach((StatementInfo statement) {
      target.add(statement);
    });
    return target;
  }

  List<StatementInfo> _filterStatements(
      List<StatementInfo> statements, String filter) {
    Set<StatementInfo> set = Set.from(statements);
    var toRemove = [];
    set.forEach((StatementInfo statement) {
      String description = statement.description.toLowerCase();
      String mcc = new Utils().getMCC(statement.mcc.toString());
      if (mcc == null) {
        mcc = "";
      } else {
        mcc = mcc.toLowerCase();
      }
      String filterValue = filter.toLowerCase();
      if (!description.contains(filterValue) && !mcc.contains(filterValue)) {
        toRemove.add(statement);
      }
    });
    statements.removeWhere((e) => toRemove.contains(e));
    return statements;
  }

}
