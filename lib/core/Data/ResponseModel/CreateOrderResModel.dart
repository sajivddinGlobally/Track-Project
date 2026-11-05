class CreateOrderResModel {
  final bool? success;
  final String? message;
  final bool? isMock;
  final OrderData? order;
  final OrderData? data;

  CreateOrderResModel({
    this.success,
    this.message,
    this.isMock,
    this.order,
    this.data,
  });

  factory CreateOrderResModel.fromJson(Map<String, dynamic> json) {
    OrderData? orderObj;
    if (json["order"] != null && json["order"] is Map<String, dynamic>) {
      orderObj = OrderData.fromJson(json["order"]);
    } else if (json["data"] != null && json["data"] is Map<String, dynamic>) {
      if (json["data"]["order"] != null &&
          json["data"]["order"] is Map<String, dynamic>) {
        orderObj = OrderData.fromJson(json["data"]["order"]);
      } else {
        orderObj = OrderData.fromJson(json["data"]);
      }
    }

    final isMock = json["isMock"] == true ||
        json["data"]?["isMock"] == true ||
        orderObj?.id?.startsWith("order_mock_") == true ||
        orderObj?.key?.contains("mock") == true;

    return CreateOrderResModel(
      success: json["success"],
      message: json["message"],
      isMock: isMock,
      order: orderObj,
      data: orderObj,
    );
  }

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "isMock": isMock,
        "order": order?.toJson(),
        "data": data?.toJson(),
      };
}

class OrderData {
  final String? id;
  final num? amount;
  final String? key;
  final String? currency;

  OrderData({
    this.id,
    this.amount,
    this.key,
    this.currency,
  });

  factory OrderData.fromJson(Map<String, dynamic> json) => OrderData(
        id: json["id"]?.toString() ?? json["order_id"]?.toString(),
        amount: json["amount"],
        key: json["key"]?.toString() ??
            json["razorpay_key"]?.toString() ??
            json["key_id"]?.toString(),
        currency: json["currency"]?.toString() ?? "INR",
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "amount": amount,
        "key": key,
        "currency": currency,
      };
}

