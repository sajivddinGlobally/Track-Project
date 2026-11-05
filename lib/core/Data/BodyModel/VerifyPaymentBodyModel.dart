class VerifyPaymentBodyModel {
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? razorpaySignature;

  VerifyPaymentBodyModel({
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.razorpaySignature,
  });

  factory VerifyPaymentBodyModel.fromJson(Map<String, dynamic> json) =>
      VerifyPaymentBodyModel(
        razorpayOrderId: json["razorpay_order_id"],
        razorpayPaymentId: json["razorpay_payment_id"],
        razorpaySignature: json["razorpay_signature"],
      );

  Map<String, dynamic> toJson() => {
        "razorpay_order_id": razorpayOrderId,
        "razorpay_payment_id": razorpayPaymentId,
        "razorpay_signature": razorpaySignature,
      };
}

