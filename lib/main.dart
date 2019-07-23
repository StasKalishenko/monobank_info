import 'package:flutter/material.dart';
import 'home_page.dart';

void main() => runApp(MonobankAnalytics());

class MonobankAnalytics extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monobank Analytics',
      home: HomePage(),
      theme: ThemeData(
        primaryColor: Colors.grey.shade900,
      ),
    );
  }
}