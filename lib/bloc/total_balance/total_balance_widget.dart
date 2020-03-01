import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monobank_info/bloc/total_balance/total_balance_events.dart';

import 'total_balance_bloc.dart';
import 'total_balance_state.dart';

class TotalBalanceWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: _getDefaultBoxDecoration(),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              _buildSavingsLabel(),
              IconButton(
                  icon: Icon(Icons.arrow_forward),
                  iconSize: 26,
                  color: Colors.grey.shade800,
                  onPressed: () => _showSavings(context))
            ]));
  }

  BoxDecoration _getDefaultBoxDecoration() {
    return new BoxDecoration(
        border: Border(
          bottom: BorderSide(width: 0.5, color: Colors.grey.shade400),
        ),
        color: Colors.grey[50]);
  }

  Widget _buildSavingsLabel() {
    return BlocBuilder<TotalBalanceBloc, TotalBalanceState>(
        builder: (context, TotalBalanceState state) {
      return FlatButton(
          onPressed: () => _showSavings(context),
          child: Text('Savings: ${state.balance}',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold)));
    });
  }

  _showSavings(BuildContext context) {
    BlocProvider.of<TotalBalanceBloc>(context)
        .add(TotalBalanceShowDetailsEvent(context));
  }
}
