import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bloc/bloc.dart';

import 'package:monobank_info/bloc/total_balance/total_balance_events.dart';
import 'package:monobank_info/bloc/total_balance/total_balance_state.dart';
import '../../utils.dart';
import '../../monobank_api.dart';

class TotalBalanceBloc extends Bloc<TotalBalanceEvent, TotalBalanceState> {
  var _currencies = {};
  var _balanceDetails = {};
  final int _usdCode = 840;

  @override
  TotalBalanceState get initialState => TotalBalanceState.initial();

  @override
  Stream<TotalBalanceState> mapEventToState(TotalBalanceEvent event) async* {
    if (event is TotalBalanceLoadEvent) {
      String balance = await _getFormattedValue(event.balance);
      yield TotalBalanceState(balance: balance);
    } else if (event is TotalBalanceShowDetailsEvent) {
      String details = _getFormattedBalanceDetails();
      Navigator.of(event.context)
          .push(MaterialPageRoute<void>(builder: (BuildContext context) {
        return Scaffold(
            appBar: AppBar(
              title: Text("Savings"),
            ),
            body: Padding(
                padding: EdgeInsets.all(14),
                child: Text('$details',
                    style: TextStyle(color: Colors.black, fontSize: 14.0))));
      }));
    }
  }

  Future<String> _getFormattedValue(var balance) async {
    _balanceDetails = balance;
    num currencyBalance = await _getSavings(balance);
    final formatter = NumberFormat("#,###.##", "uk_UA");
    return formatter.format(currencyBalance) + " \$";
  }

  Future<num> _getSavings(var _balanceDetails) async {
    num result = 0;
    MonobankAPI api = new MonobankAPI();
    _currencies = await api.getCurrencies();
    num usdRate = _currencies[_usdCode];
    _balanceDetails.forEach((key, item) {
      for (var i = 0; i < item.length; i++) {
        var account = item[i];
        int code = account["currencyCode"];
        if (code == 980) {
          continue;
        }
        num rate = _currencies[code] != null ? _currencies[code] : 1;
        num balance = account["balance"];
        if (code != _usdCode) {
          balance = balance * rate / usdRate;
        }
        result += balance;
      }
    });
    return result;
  }

  String _getFormattedBalanceDetails() {
    List<String> balanceDetails = new List<String>();
    _balanceDetails.forEach((key, item) {
      balanceDetails.add(key);
      for (var i = 0; i < item.length; i++) {
        var account = item[i];
        if (account["currencyCode"] == 980) {
          continue;
        }
        balanceDetails.add(account["balance"].toStringAsFixed(2) +
            " " +
            new Utils().getCurrencyByISO(account["currencyCode"]));
      }
      balanceDetails.add('\n');
    });
    return balanceDetails.join('\n');
  }
}
