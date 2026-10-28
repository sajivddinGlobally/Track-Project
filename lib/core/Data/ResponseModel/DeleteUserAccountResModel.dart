class DeleteUserAccountResModel {
  final bool? success;
  final String? message;

  DeleteUserAccountResModel({
    this.success,
    this.message,
  });

  factory DeleteUserAccountResModel.fromJson(Map<String, dynamic> json) {
    return DeleteUserAccountResModel(
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
