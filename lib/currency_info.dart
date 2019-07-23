class CurrencyInfo {
  final num rateBuy;
  final num currencyCodeA;
  final num currencyCodeB;
  CurrencyInfo({this.currencyCodeA, this.currencyCodeB, this.rateBuy});
  factory CurrencyInfo.fromJson(Map<String, dynamic> json) {
    return CurrencyInfo(
        currencyCodeA: json['currencyCodeA'],
		currencyCodeB: json['currencyCodeB'],
		rateBuy: json['rateBuy']
	);
  }
}