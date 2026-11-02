import 'dart:convert';

SubmitFeedbackResModel submitFeedbackResModelFromJson(String str) =>
    SubmitFeedbackResModel.fromJson(json.decode(str));

String submitFeedbackResModelToJson(SubmitFeedbackResModel data) =>
    json.encode(data.toJson());

class SubmitFeedbackResModel {
  final dynamic success;
  final String? message;
  final dynamic data;

  SubmitFeedbackResModel({
    this.success,
    this.message,
    this.data,
  });

  bool get isSuccess {
    if (success is bool) return success as bool;
    if (success is String) {
      return (success as String).toLowerCase() == 'true' ||
          (success as String).toLowerCase() == 'success';
    }
    return false;
  }

  factory SubmitFeedbackResModel.fromJson(Map<String, dynamic> json) =>
      SubmitFeedbackResModel(
        success: json["success"] ?? json["status"],
        message: json["message"] as String?,
        data: json["data"],
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data,
      };
}

