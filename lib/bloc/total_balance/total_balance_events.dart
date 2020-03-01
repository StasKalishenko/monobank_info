import 'package:flutter/material.dart';

abstract class TotalBalanceEvent {}

class TotalBalanceLoadEvent extends TotalBalanceEvent {
  final Object balance;

  TotalBalanceLoadEvent(this.balance);
}

class TotalBalanceShowDetailsEvent extends TotalBalanceEvent {
  final BuildContext context;

  TotalBalanceShowDetailsEvent(this.context);
}
