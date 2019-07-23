import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'utils.dart';
import 'statementInfo.dart';

class ListBuilder {
  static final ListBuilder _instance = ListBuilder._getInstance();
  factory ListBuilder() => _instance;

  List<StatementInfo> data = [];

  ListBuilder._getInstance();

  Widget buildListHeader(BuildContext context, int index) {
    if (data.length == 0) {
      return null;
    }
    StatementInfo statement = data[index];
    var formatter = new DateFormat('MMM d');
    String formattedTime = formatter
        .format(DateTime.fromMillisecondsSinceEpoch(statement.time * 1000));
    return new SizedBox(
        width: 60.0,
        child: Padding(
            padding: EdgeInsets.fromLTRB(7, 7, 0, 0),
            child: Text(formattedTime,
                style: TextStyle(color: Colors.grey, fontSize: 16.0))));
  }

  bool hasListItemSameHeader(int a, int b) {
    if (data.length == 0) {
      return false;
    }
    StatementInfo aStatement = data[a];
    StatementInfo bStatement = data[b];
    var formatter = new DateFormat('dd.MM.yyy');
    String aFormattedTime = formatter
        .format(DateTime.fromMillisecondsSinceEpoch(aStatement.time * 1000));
    String bFormattedTime = formatter
        .format(DateTime.fromMillisecondsSinceEpoch(bStatement.time * 1000));
    return aFormattedTime == bFormattedTime;
  }

  Widget buildListItem(context, index) {
    if (data.length == 0) {
      return null;
    }
    StatementInfo statement = data[index];
    String title = statement.description;
    String amount = (statement.amount / 100).toStringAsFixed(0);
    String subTitle = new Utils().getMCC(statement.mcc.toString());
    if (statement.currencyCode != 980) {
      String currencySymbol =
          new Utils().getCurrencySymbolByISO(statement.currencyCode);
      String operationAmount =
          (statement.operationAmount / 100).toStringAsFixed(0);
      title += " ($operationAmount$currencySymbol)";
    }
    var formatter = new DateFormat('dd.MM.yyyy HH:mm');
    String formattedTime = formatter
        .format(DateTime.fromMillisecondsSinceEpoch(statement.time * 1000));
    String detailsAmount = (statement.amount / 100).toStringAsFixed(2);
    return Padding(
        padding: EdgeInsets.fromLTRB(0, 5, 0, 0),
        child: ListTile(
            title: Text(title,
                style: TextStyle(color: Colors.black, fontSize: 16.0)),
            subtitle: Text(subTitle,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey, fontSize: 12.0)),
            trailing: Text(amount,
                style: TextStyle(color: Colors.black, fontSize: 20.0)),
            onTap: () {
              Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (BuildContext context) {
                return Scaffold(
                    appBar: AppBar(
                      title: Text(title),
                    ),
                    body: Column(children: <Widget>[
                      Padding(
                          padding: EdgeInsets.fromLTRB(0, 14, 0, 0),
                          child: Center(
                              child: Text(detailsAmount + " ₴",
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 34.0)))),
                      Center(
                          child: Text(formattedTime,
                              style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14.0))),
                      Padding(
                          padding: EdgeInsets.fromLTRB(14, 14, 14, 14),
                          child: Center(
                              child: Text(subTitle,
                                  style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 12.0)))),
                    ]));
              }));
            }));
  }
}
