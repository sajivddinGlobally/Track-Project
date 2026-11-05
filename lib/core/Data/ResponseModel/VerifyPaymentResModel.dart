class VerifyPaymentResModel {
  final bool? success;
  final String? message;
  final bool? isCompanyPaymentCompleted;
  final dynamic data;

  VerifyPaymentResModel({
    this.success,
    this.message,
    this.isCompanyPaymentCompleted,
    this.data,
  });

  factory VerifyPaymentResModel.fromJson(Map<String, dynamic> json) =>
      VerifyPaymentResModel(
        success: json["success"],
        message: json["message"],
        isCompanyPaymentCompleted:
            json["isCompanyPaymentCompleted"] == true ||
            json["data"]?["isCompanyPaymentCompleted"] == true ||
            json["success"] == true,
        data: json["data"],
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "isCompanyPaymentCompleted": isCompanyPaymentCompleted,
        "data": data,
      };
}

