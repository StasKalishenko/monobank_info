import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'currency_info.dart';
import 'statementInfo.dart';

class MonobankAPI {
  static final MonobankAPI _instance = MonobankAPI._getInstance();
  factory MonobankAPI() => _instance;

  MonobankAPI._getInstance();

  final String myToken = "";
  final String wifeToken = "";
  
  final String baseUrl = "https://api.monobank.ua/";
  final String clientInfoPath = "personal/client-info";
  final String currencyPath = "bank/currency";
  final String statementInfoPath = "personal/statement/";

  var _currencies = {};

  Future<num> getMonobankAccountBalance(String token, var balanceDetails) async {
    final response =
        await http.get(baseUrl + clientInfoPath, headers: {"X-Token": token});
    num result = 0;
    if (response.statusCode == 200) {
      Map<String, dynamic> postResult = json.decode(response.body);
      List<Object> resultAccounts = postResult["accounts"];
      var accounts = [];
      for (var i = 0; i < resultAccounts.length; i++) {
        Map<String, dynamic> item = resultAccounts[i];
        num balance = item['balance'] / 100;
        double creditLimit = (item['creditLimit'] ?? 0) / 100;
        num realBalance = balance - creditLimit;
        int currencyCode = item['currencyCode'];
        num rate = _currencies[currencyCode];
        result += realBalance * (rate != null ? rate : 1);
        accounts.add({"balance": realBalance, "currencyCode": currencyCode});
      }
      balanceDetails.addAll({postResult["name"]: accounts});
      return result;
    } else {
      if (response.statusCode == 429) {
        return result;
      } else {
        throw Exception('Failed to load client info');
      }
    }
  }

  Future<void> getCurrencies() async {
    final response = await http.get(baseUrl + currencyPath);
    if (response.statusCode == 200) {
      List<Object> currencies = json.decode(response.body);
      for (var i = 0; i < currencies.length; i++) {
        var currencyInfo = currencies[i];
        CurrencyInfo info = CurrencyInfo.fromJson(currencyInfo);
        if (info.currencyCodeB == 980) {
          _currencies.addAll({info.currencyCodeA: info.rateBuy});
        }
      }
    } else {
      if (response.statusCode != 429) {
        throw Exception('Failed to load currencies');
      }
    }
  }

  Future<List<StatementInfo>> getStatementInfo(String token, DateTime date) async {
    DateTime now = date;
    DateTime from = new DateTime(now.year, now.month, 1);
    DateTime to = new DateTime(now.year, now.month + 1, 1);
    to = new DateTime(to.year, to.month, to.day - 1);
    String url = baseUrl +
        statementInfoPath +
        "0/" +
        (from.millisecondsSinceEpoch / 1000).toStringAsFixed(0) +
        "/" +
        (to.millisecondsSinceEpoch / 1000).toStringAsFixed(0);
    final response = await http.get(url, headers: {"X-Token": token});
    List<StatementInfo> statements = [];
    if (response.statusCode == 200) {
      List<Object> getResult = json.decode(response.body);
      for (var i = 0; i < getResult.length; i++) {
        statements.add(StatementInfo.fromJson(getResult[i]));
      }
      return statements;
    } else {
      if (response.statusCode == 429) {
        return statements;
      } else {
        throw Exception("Failed to load client info");
      }
    }
  }

  Future<List<StatementInfo>> getStatements(DateTime date) async {
    var myStatements = await getStatementInfo(myToken, date);
    var wifeStatements = await getStatementInfo(wifeToken, date);
    List<StatementInfo> result = new List.from(myStatements)
      ..addAll(wifeStatements);
    result..sort((a, b) => b.time.compareTo(a.time));
    return result;
  }

  Future<num> getTotalBalance(var balanceDetails) async {
    MonobankAPI api = new MonobankAPI();
    num myBalance =
        await api.getMonobankAccountBalance(api.myToken, balanceDetails);
    num wifeBalance =
        await api.getMonobankAccountBalance(api.wifeToken, balanceDetails);
    return myBalance + wifeBalance;
  }

}
