import 'package:flutter/material.dart';

class StatementsFilterState {
  final TextEditingController controller;

  const StatementsFilterState({this.controller});

  factory StatementsFilterState.initial() => StatementsFilterState(controller: null);

}