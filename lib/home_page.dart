import 'package:flutter/material.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:intl/intl.dart';
import 'package:side_header_list_view/side_header_list_view.dart';
import 'dart:async';
import 'utils.dart';
import 'statementInfo.dart';
import 'list.dart';
import 'monobank_api.dart';

class HomePageState extends State<HomePage> {
  final String progressText = "Loading...";
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  final TextEditingController _controller = new TextEditingController();

  var _balanceDetails = {};

  List<StatementInfo> _allStatements = [];
  List<StatementInfo> _filteredStatements = [];
  String _totalBalance = "";
  String _filter = "";
  bool _dataLoaded = false;

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

  Widget _buildTotalBalanceLabel() {
    return FlatButton(
        onPressed: _showBalanceDetails,
        child: Text('Balance: $_totalBalance',
            style: TextStyle(
                color: Colors.white,
                fontSize: 24.0,
                fontWeight: FontWeight.bold)));
  }

  Widget _getBody() {
    return Container(
        decoration: BoxDecoration(
            color: Colors.deepPurple,
            gradient: LinearGradient(
                begin: FractionalOffset.topCenter,
                end: FractionalOffset.bottomCenter,
                colors: [
                  Colors.deepPurple.withOpacity(0.5),
                  Colors.deepPurple,
                ],
                stops: [
                  0.1,
                  1.0
                ])),
        child: !_dataLoaded
            ? Center(child: ScalingText(progressText))
            : Column(children: <Widget>[
                Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      _buildTotalBalanceLabel(),
                      IconButton(
                          icon: Icon(Icons.arrow_forward),
                          iconSize: 26,
                          color: Colors.white,
                          onPressed: _showBalanceDetails)
                    ]),
                Container(
                    decoration: new BoxDecoration(color: Colors.grey.shade900),
                    height: 44,
                    child: TextField(
                        controller: _controller,
                        style: new TextStyle(
                            color: Colors.white,
                            backgroundColor: Colors.grey.shade900),
                        decoration: new InputDecoration(
                            prefixIcon:
                                new Icon(Icons.search, color: Colors.white),
                            hintText: "Search",
                            hintStyle: new TextStyle(color: Colors.white)))),
                Expanded(
                    child: Container(
                        decoration: new BoxDecoration(color: Colors.white),
                        child: RefreshIndicator(
                            key: _refreshIndicatorKey,
                            onRefresh: _refresh,
                            child: _buildList())))
              ]));
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
      }
    });
    _filteredStatements.removeWhere((e) => toRemove.contains(e));
  }

  _copyAllStatements() {
    Set<StatementInfo> set = Set.from(_allStatements);
    _filteredStatements.clear();
    set.forEach((StatementInfo statement) {
      _filteredStatements.add(statement);
    });
  }

  _loadFilteredData() {
    setState(() {
      _copyAllStatements();
      if (_filter != "") {
        _filterStatements();
      }
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
      appBar: AppBar(title: Text('Monobank Analytics'), actions: <Widget>[
        new IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              _refreshIndicatorKey.currentState.show();
            }),
      ]),
      body: _getBody(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => HomePageState();
}
