class SendDeletionOtpResModel {
  final bool? success;
  final String? message;

  SendDeletionOtpResModel({
    this.success,
    this.message,
  });

  factory SendDeletionOtpResModel.fromJson(Map<String, dynamic> json) {
    return SendDeletionOtpResModel(
      success: json['success'] as bool?,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
    };
  }
}
