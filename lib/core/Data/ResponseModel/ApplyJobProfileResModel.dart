class ApplyJobProfileResModel {
  final bool? success;
  final String? message;
  final dynamic data;

  ApplyJobProfileResModel({
    this.success,
    this.message,
    this.data,
  });

  factory ApplyJobProfileResModel.fromJson(Map<String, dynamic> json) {
    return ApplyJobProfileResModel(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
    };
  }
}
