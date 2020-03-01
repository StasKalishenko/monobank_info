import 'package:flutter/material.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:intl/intl.dart';
import 'package:side_header_list_view/side_header_list_view.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:carousel_widget/carousel_widget.dart';
import 'package:flutter_cupertino_date_picker/flutter_cupertino_date_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/hryvnia_balance/hryvnia_balance_bloc.dart';
import 'bloc/hryvnia_balance/hryvnia_balance_events.dart';
import 'bloc/hryvnia_balance/hryvnia_balance_widget.dart';
import 'bloc/total_balance/total_balance_bloc.dart';
import 'bloc/total_balance/total_balance_events.dart';
import 'bloc/total_balance/total_balance_widget.dart';
import 'bloc/chart/chart.dart';
import 'dart:async';
import 'utils.dart';
import 'statementInfo.dart';
import 'list.dart';
import 'monobank_api.dart';
import 'db.dart';

class HomePageState extends State<HomePage> {
  final String _progressText = "Loading...";
  final int _truncLimit = 30;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  final TextEditingController _controller = new TextEditingController();
  final String _defaultTitle = "Analytics";

  var _balanceDetails = {};

  DatumLegendWithMeasures _chartData;
  List<StatementInfo> _allStatements = [];
  List<StatementInfo> _filteredStatements = [];
  List<StatementInfo> _chartStatements = [];

  TotalBalanceBloc _totalBloc;

  String _filter = "";
  String _title = "";
  DateTime _statementsMonth = new DateTime.now();
  bool _dataLoaded = false;

  Widget _buildList() {
    ListBuilder builder = new ListBuilder();
    builder.data = _filteredStatements;
    return SideHeaderListView(
        itemCount: _filteredStatements.length,
        itemExtend: 56.0,
        headerBuilder: builder.buildListHeader,
        hasSameHeader: builder.hasListItemSameHeader,
        itemBuilder: builder.buildListItem);
  }

  Widget _buildSearchField() {
    return TextField(
        controller: _controller,
        style: new TextStyle(
            color: Colors.black, backgroundColor: Colors.transparent),
        decoration: new InputDecoration(
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400, width: 0.5),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400, width: 0.5),
            ),
            prefixIcon: new Icon(Icons.search, color: Colors.black),
            contentPadding: const EdgeInsets.all(14.0),
            hintText: "Search",
            hintStyle: new TextStyle(color: Colors.grey.shade400)));
  }

  Widget _buildChartPage() {
    return Fragment(
        color: Colors.grey[50],
        child: Column(children: <Widget>[
          BlocProvider(
            create: (context) {
              _totalBloc = TotalBalanceBloc();
              return _totalBloc;
            },
            child: TotalBalanceWidget(),
          ),
          Expanded(
              child: Container(
                  decoration: new BoxDecoration(color: Colors.white),
                  child: _chartData)),
        ]));
  }

  Widget _buildStatementsPage() {
    return Fragment(
      color: Colors.white,
      child: Column(children: <Widget>[
        Container(
            decoration: new BoxDecoration(color: Colors.grey[50]),
            child: _buildSearchField()),
        Expanded(
          child: RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _refresh,
              child: _buildList()),
        )
      ]),
    );
  }

  Widget _getBody() {
    return Container(
        color: Colors.white,
        child: !_dataLoaded
            ? Center(child: ScalingText(_progressText))
            : Carousel(
                listViews: [_buildChartPage(), _buildStatementsPage()],
              ));
  }

  _filterStatements() {
    Set<StatementInfo> set = Set.from(_allStatements);
    var toRemove = [];
    set.forEach((StatementInfo statement) {
      String description = statement.description.toLowerCase();
      String mcc = new Utils().getMCC(statement.mcc.toString());
      if (mcc == null) {
        mcc = "";
      } else {
        mcc = mcc.toLowerCase();
      }
      String filterValue = _filter.toLowerCase();
      if (!description.contains(filterValue) && !mcc.contains(filterValue)) {
        toRemove.add(statement);
      }
    });
    _filteredStatements.removeWhere((e) => toRemove.contains(e));
  }

  _copyAllStatements(target) {
    Set<StatementInfo> set = Set.from(_allStatements);
    target.clear();
    set.forEach((StatementInfo statement) {
      target.add(statement);
    });
  }

  _loadFilteredData() {
    setState(() {
      _copyAllStatements(_filteredStatements);
      if (_filter != "") {
        _filterStatements();
      }
    });
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

  List<charts.Series<Expenses, String>> _calculateChartData() {
    _copyAllStatements(_chartStatements);
    var groupedStatements = {};
    Set<StatementInfo> set = Set.from(_allStatements);
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
      new charts.Series<Expenses, String>(
        id: 'Expenses',
        domainFn: (Expenses expenses, _) => expenses.mcc,
        measureFn: (Expenses expenses, _) => expenses.value,
        data: data,
      )
    ];
  }

  _loadChartData() {
    setState(() {
      _chartData =
          new DatumLegendWithMeasures(_calculateChartData(), animate: true);
    });
  }

  _loadLocalData() async {
    List<StatementInfo> localStatements = await DBProvider.db.getStatements();
    setState(() {
      _allStatements = localStatements;
      _loadFilteredData();
      _loadChartData();
      _dataLoaded = true;
    });
  }

  Future<Null> _loadData() async {
    MonobankAPI api = new MonobankAPI();
    await api.loadBalances(_balanceDetails);
    _totalBloc.add(TotalBalanceLoadEvent(_balanceDetails));
    List<StatementInfo> statements = await api.getStatements(_statementsMonth);
    setState(() {
      _allStatements = statements;
      _loadFilteredData();
      _loadChartData();
      _saveStatements();
      _dataLoaded = true;
    });
  }

  _onFilterChanged() {
    _filter = _controller.text;
    _loadFilteredData();
  }

  Future<Null> _refresh() {
    return _loadData();
  }

  _saveStatements() async {
    Set<StatementInfo> set = Set.from(_allStatements);
    set.forEach((StatementInfo statement) {
      DBProvider.db.addStatement(statement);
    });
  }

  @override
  initState() {
    _title = _defaultTitle;
    super.initState();
    _loadLocalData();
    _loadData();
    _controller.addListener(_onFilterChanged);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$_title'),
        actions: <Widget>[
          BlocProvider(
            create: (context) {
              var bloc = HryvniaBalanceBloc();
              bloc.add(HryvniaBalanceRefreshEvent());
              return bloc;
            },
            child: HryvniaBalanceWidget(),
          )
        ],
        leading: IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Month',
            onPressed: () {
              DatePicker.showDatePicker(context,
                  minDateTime: DateTime(2019, 1, 1),
                  maxDateTime: DateTime(2099, 12, 31),
                  initialDateTime: DateTime.now(),
                  dateFormat: 'yyyy-MM',
                  locale: DateTimePickerLocale.en_us,
                  pickerMode: DateTimePickerMode.date,
                  pickerTheme: DateTimePickerTheme.Default,
                  onConfirm: (date, List<int> selectedIndex) {
                setState(() {
                  _statementsMonth = date;
                  var formatter = new DateFormat('MMM');
                  String formattedTime = formatter.format(date);
                  _title = _defaultTitle + " (" + formattedTime + ")";
                  _refresh();
                });
              });
            }),
      ),
      body: _getBody(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => HomePageState();
}
