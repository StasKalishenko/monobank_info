import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'statements_filter_bloc.dart';
import 'statements_filter_state.dart';

class StatementsFilterWidget extends StatelessWidget {
  final String _searchHint = "Search";

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StatementsFilterBloc, StatementsFilterState>(
        builder: (context, StatementsFilterState state) {
      return TextField(
          controller: state.controller,
          style: new TextStyle(
              color: Colors.black, backgroundColor: Colors.transparent),
          decoration: new InputDecoration(
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400, width: 0.5),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400, width: 0.5),
              ),
              prefixIcon: new Icon(Icons.search, color: Colors.black),
              contentPadding: const EdgeInsets.all(14.0),
              hintText: _searchHint,
              hintStyle: new TextStyle(color: Colors.grey.shade400)));
    });
  }
}
