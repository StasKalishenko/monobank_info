class StatementInfo {
  final String id;
  final String description;
  final int amount;
  final int operationAmount;
  final int currencyCode;
  final int time;
  final int mcc;
  StatementInfo({
      this.id,
      this.description,
      this.amount,
      this.operationAmount,
      this.currencyCode,
      this.time,
      this.mcc});
  factory StatementInfo.fromJson(Map<String, dynamic> json) {
    return StatementInfo(
        id: json["id"],
        description: json["description"],
        amount: json["amount"],
        operationAmount: json["operationAmount"],
        currencyCode: json["currencyCode"],
        time: json["time"],
        mcc: json["mcc"]);
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "description": description,
      "amount": amount,
      "operationAmount": operationAmount,
      "currencyCode": currencyCode,
      "time": time,
      "mcc": mcc
    };
  }
}
