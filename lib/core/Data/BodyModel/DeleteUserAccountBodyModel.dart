class DeleteUserAccountBodyModel {
  final String confirmationWord;
  final String otp;
  final String? reason;

  DeleteUserAccountBodyModel({
    required this.confirmationWord,
    required this.otp,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'confirmationWord': confirmationWord,
      'otp': otp,
      if (reason != null && reason!.isNotEmpty) 'reason': reason,
    };
  }

  factory DeleteUserAccountBodyModel.fromJson(Map<String, dynamic> json) {
    return DeleteUserAccountBodyModel(
      confirmationWord: json['confirmationWord'] as String? ?? 'DELETE',
      otp: json['otp'] as String? ?? '',
      reason: json['reason'] as String?,
    );
  }
}
