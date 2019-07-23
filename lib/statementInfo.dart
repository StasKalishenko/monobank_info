class StatementInfo {
  final String description;
  final int amount;
  final int operationAmount;
  final int currencyCode;
  final int time;
  final int mcc;
  StatementInfo({this.description, this.amount, this.operationAmount,
  	this.currencyCode, this.time, this.mcc});
  factory StatementInfo.fromJson(Map<String, dynamic> json) {
    return StatementInfo(
		description: json["description"],
		amount: json["amount"], 
		operationAmount: json["operationAmount"], 
		currencyCode: json["currencyCode"],
		time: json["time"],
		mcc: json["mcc"]
	);
  }
}