class CreateOrderBodyModel {
  final num? amount;
  final String? planName;

  CreateOrderBodyModel({
    this.amount = 1,
    this.planName = "Company Subscription",
  });

  factory CreateOrderBodyModel.fromJson(Map<String, dynamic> json) =>
      CreateOrderBodyModel(
        amount: json["amount"],
        planName: json["planName"],
      );

  Map<String, dynamic> toJson() => {
        "amount": amount ?? 1,
        "planName": planName ?? "Company Subscription",
      };
}

