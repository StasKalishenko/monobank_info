class HryvniaBalanceState {
  final String balance;

  const HryvniaBalanceState({this.balance});

  factory HryvniaBalanceState.initial() => HryvniaBalanceState(balance: "");
}