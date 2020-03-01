class TotalBalanceState {
  final String balance;

  const TotalBalanceState({this.balance});

  factory TotalBalanceState.initial() => TotalBalanceState(balance: "");
}