import 'package:bloc/bloc.dart';
import 'package:monobank_info/bloc/hryvnia_balance/hryvnia_balance_events.dart';
import 'package:monobank_info/bloc/hryvnia_balance/hryvnia_balance_state.dart';

import '../../monobank_api.dart';

class HryvniaBalanceBloc extends Bloc<HryvniaBalanceEvent, HryvniaBalanceState> {
 
  Future<String> _getBalance() async {
    List<String> result = new List<String>();
    var balances = {};
    MonobankAPI api = new MonobankAPI();
    await api.loadBalances(balances);
    balances.forEach((key, item) {
      var owner = key;
      var ownerFullNameArr = owner.split(" ");
      var ownerName = ownerFullNameArr.length > 1
          ? ownerFullNameArr[1]
          : ownerFullNameArr[0];
      for (var i = 0; i < item.length; i++) {
        var account = item[i];
        if (account["currencyCode"] == 980) {
          result.add(ownerName[0] + ": " +
              account["balance"].toStringAsFixed(2) + " ₴");
        }
      }
    });
    return result.join('\n');
  }

  @override
  HryvniaBalanceState get initialState => HryvniaBalanceState.initial();

  @override
  Stream<HryvniaBalanceState> mapEventToState(HryvniaBalanceEvent event) async* {
    if (event is HryvniaBalanceRefreshEvent) {
      String newValue = await _getBalance();
      yield HryvniaBalanceState(balance: newValue);
    }
  }

}
