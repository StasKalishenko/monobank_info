import 'package:flutter/material.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:intl/intl.dart';
import 'package:side_header_list_view/side_header_list_view.dart';
import 'dart:async';
import 'utils.dart';
import 'statementInfo.dart';
import 'list.dart';
import 'monobank_api.dart';
import 'chart.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:carousel_widget/carousel_widget.dart';

class HomePageState extends State<HomePage> {
  final String _progressText = "Loading...";
  final int _truncLimit = 30;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  final TextEditingController _controller = new TextEditingController();

  var _balanceDetails = {};

  DatumLegendWithMeasures _chartData;
  List<StatementInfo> _allStatements = [];
  List<StatementInfo> _filteredStatements = [];
  List<StatementInfo> _chartStatements = [];
  String _totalBalance = "";
  String _filter = "";
  bool _dataLoaded = false;
  int _monthBalance = 0;

  String _getFormattedBalanceDetails() {
    List<String> balanceDetails = new List<String>();
    _balanceDetails.forEach((key, item) {
      balanceDetails.add(key);
      for (var i = 0; i < item.length; i++) {
        var account = item[i];
        balanceDetails.add(account["balance"].toStringAsFixed(2) +
            " " +
            new Utils().getCurrencyByISO(account["currencyCode"]));
      }
      balanceDetails.add('\n');
    });
    return balanceDetails.join('\n');
  }

  _showBalanceDetails() {
    String result = _getFormattedBalanceDetails();
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (BuildContext context) {
      return Scaffold(
          appBar: AppBar(
            title: Text("Balance details"),
          ),
          body: Padding(
              padding: EdgeInsets.all(14),
              child: Text('$result',
                  style: TextStyle(color: Colors.black, fontSize: 14.0))));
    }));
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

  BoxDecoration _getDefaultBoxDecoration() {
    return new BoxDecoration(
        border: Border(
          bottom: BorderSide(width: 0.5, color: Colors.grey.shade400),
        ),
        color: Colors.grey[50]);
  }

  Widget _buildTotalBalanceLabel() {
    return FlatButton(
        onPressed: _showBalanceDetails,
        child: Text('Balance: $_totalBalance',
            style: TextStyle(
                color: Colors.black,
                fontSize: 24.0,
                fontWeight: FontWeight.bold)));
  }

  Widget _buildTotalBalanceContainer() {
    return Container(
        decoration: _getDefaultBoxDecoration(),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              _buildTotalBalanceLabel(),
              IconButton(
                  icon: Icon(Icons.arrow_forward),
                  iconSize: 26,
                  color: Colors.grey.shade800,
                  onPressed: _showBalanceDetails)
            ]));
  }

  Widget _buildChartPage() {
    return Fragment(
        color: Colors.grey[50],
        child: Column(children: <Widget>[
          _buildTotalBalanceContainer(),
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
      String mcc = new Utils().getMCC(statement.mcc.toString()).toLowerCase();
      String filterValue = _filter.toLowerCase();
      if (!description.contains(filterValue) && !mcc.contains(filterValue)) {
        toRemove.add(statement);
      } else {
        _monthBalance += (statement.amount / 100).round();
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

  _calcMonthBalance() {
    Set<StatementInfo> set = Set.from(_allStatements);
    set.forEach((StatementInfo statement) {
      _monthBalance += (statement.amount / 100).round();
    });
  }

  _loadFilteredData() {
    _monthBalance = 0;
    setState(() {
      _copyAllStatements(_filteredStatements);
      if (_filter != "") {
        _filterStatements();
      } else {
        _calcMonthBalance();
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
      String mcc = new Utils().getMCC(statement.mcc.toString()).toLowerCase();
      double amount = statement.amount / 100;
      if (amount < 0) {
        amount = -1 * amount;
        groupedStatements[mcc] = groupedStatements[mcc] != null
            ? groupedStatements[mcc] + amount
            : amount;
        total += amount;
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

  _updateChartData() {
    setState(() {
      _chartData =
          new DatumLegendWithMeasures(_calculateChartData(), animate: true);
    });
  }

  Future<Null> _loadData() async {
    MonobankAPI api = new MonobankAPI();
    await api.getCurrencies();
    num balance = await api.getTotalBalance(_balanceDetails);
    List<StatementInfo> statements = await api.getStatements();
    setState(() {
      if (statements.length > 0) {
        _allStatements = statements;
        final formatter = NumberFormat("#,###.##", "uk_UA");
        String formattedBalance = formatter.format(balance);
        _totalBalance = formattedBalance + " ₴";
      }
      _loadFilteredData();
      _updateChartData();
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

  @override
  initState() {
    super.initState();
    _loadData();
    _controller.addListener(_onFilterChanged);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Monobank Analytics'),
        actions: <Widget>[
          Padding(
              padding: EdgeInsets.only(top: 18, right: 5),
              child: Text('$_monthBalance ₴',
                  style: TextStyle(color: Colors.white, fontSize: 20.0)))
        ],
        leading: new IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              _refreshIndicatorKey.currentState.show();
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
