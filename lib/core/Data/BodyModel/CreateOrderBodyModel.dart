class CreateOrderBodyModel {
  final num? amount;
  final String? planName;

  CreateOrderBodyModel({
    this.amount = 49900,
    this.planName = "Company Profile",
  });

  factory CreateOrderBodyModel.fromJson(Map<String, dynamic> json) =>
      CreateOrderBodyModel(
        amount: json["amount"],
        planName: json["planName"],
      );

  Map<String, dynamic> toJson() => {
        "amount": amount ?? 49900,
        "planName": planName ?? "Company Profile",
      };
}

