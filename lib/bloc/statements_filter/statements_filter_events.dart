import 'package:flutter/material.dart';

abstract class StatementsFilterEvent {}

class StatementsFilterInitEvent extends StatementsFilterEvent {
  final TextEditingController controller;

  StatementsFilterInitEvent(this.controller);
}