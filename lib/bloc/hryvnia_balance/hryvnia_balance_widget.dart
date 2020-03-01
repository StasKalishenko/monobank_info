import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monobank_info/bloc/hryvnia_balance/hryvnia_balance_events.dart';

import 'hryvnia_balance_bloc.dart';
import 'hryvnia_balance_state.dart';

class HryvniaBalanceWidget extends StatelessWidget {

  _getBalance(BuildContext context) {
    BlocProvider.of<HryvniaBalanceBloc>(context).add(HryvniaBalanceRefreshEvent());
  }  

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(top: 0, right: 0),
        child: BlocBuilder<HryvniaBalanceBloc, HryvniaBalanceState>(
            builder: (context, HryvniaBalanceState state) {
          return FlatButton(
            onPressed: () => _getBalance(context),
            child: Text('${state.balance}',
              style: TextStyle(color: Colors.white, fontSize: 14.0)),
          );
        }));
  }
}
