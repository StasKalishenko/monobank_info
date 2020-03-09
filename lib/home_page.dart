import 'package:flutter/material.dart';
import 'package:monobank_info/bloc/chart/chart_bloc.dart';
import 'package:monobank_info/bloc/chart/chart_events.dart';
import 'package:monobank_info/bloc/statements_filter/statements_filter_bloc.dart';
import 'package:monobank_info/bloc/statements_filter/statements_filter_events.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:intl/intl.dart';
import 'package:side_header_list_view/side_header_list_view.dart';
import 'package:carousel_widget/carousel_widget.dart';
import 'package:flutter_cupertino_date_picker/flutter_cupertino_date_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/chart/chart_widget.dart';
import 'bloc/hryvnia_balance/hryvnia_balance_bloc.dart';
import 'bloc/hryvnia_balance/hryvnia_balance_events.dart';
import 'bloc/hryvnia_balance/hryvnia_balance_widget.dart';
import 'bloc/statements_filter/statements_filter_widget.dart';
import 'bloc/total_balance/total_balance_bloc.dart';
import 'bloc/total_balance/total_balance_events.dart';
import 'bloc/total_balance/total_balance_widget.dart';
import 'dart:async';
import 'statementInfo.dart';
import 'list.dart';
import 'monobank_api.dart';
import 'db.dart';

class HomePageState extends State<HomePage> {
  final String _progressText = "Loading...";
  final String _defaultTitle = "Analytics";
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  final TextEditingController _filterController = new TextEditingController();

  List<StatementInfo> _allStatements = [];
  List<StatementInfo> _filteredStatements = [];
  TotalBalanceBloc _totalBloc;
  ChartBloc _chartBloc = new ChartBloc();
  StatementsFilterBloc _statementsFilterBloc = StatementsFilterBloc();
  String _title = "";
  DateTime _statementsMonth = new DateTime.now();
  bool _dataLoaded = false;

  @override
  initState() {
    _title = _defaultTitle;
    super.initState();
    _loadLocalData();
    _loadData();
    _filterController.addListener(_loadFilteredData);
    _statementsFilterBloc.add(StatementsFilterInitEvent(_filterController));
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
              _chooseMonth();
            }),
      ),
      body: _getBody(),
    );
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
    var _balanceDetails = {};
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

  _loadFilteredData() {
    setState(() {
      _filteredStatements = _statementsFilterBloc.getFilteredStatements(_allStatements, _filterController.text);
    });
  }

  _loadChartData() {
    _chartBloc.add(ChartLoadEvent(_allStatements));
  }

  _saveStatements() async {
    Set<StatementInfo> set = Set.from(_allStatements);
    set.forEach((StatementInfo statement) {
      DBProvider.db.addStatement(statement);
    });
  }

  _chooseMonth() {
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
  }

  Widget _getBody() {
    return Container(
        color: Colors.white,
        child: !_dataLoaded
            ? Center(child: ScalingText(_progressText))
            : Carousel(
                listViews: [_buildChartView(), _buildStatementsView()],
              ));
  }

  Widget _buildChartView() {
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
                  child: BlocProvider(
                    create: (context) {
                      return _chartBloc;
                    },
                    child: ChartWidget(),
                  ))),
        ]));
  }

  Widget _buildStatementsView() {
    return Fragment(
      color: Colors.white,
      child: Column(children: <Widget>[
        Container(
            decoration: new BoxDecoration(color: Colors.grey[50]),
            child: BlocProvider(
              create: (context) {
                return _statementsFilterBloc;
              },
              child: StatementsFilterWidget(),
            )),
        Expanded(
          child: RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _refresh,
              child: _buildList()),
        )
      ]),
    );
  }

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

  Future<Null> _refresh() {
    return _loadData();
  }
}

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => HomePageState();
}
