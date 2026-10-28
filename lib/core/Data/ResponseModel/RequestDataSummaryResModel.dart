import 'dart:convert';

RequestDataSummaryResModel requestDataSummaryResModelFromJson(String str) =>
    RequestDataSummaryResModel.fromJson(json.decode(str));

String requestDataSummaryResModelToJson(RequestDataSummaryResModel data) =>
    json.encode(data.toJson());

class RequestDataSummaryResModel {
  final bool? success;
  final String? message;

  RequestDataSummaryResModel({
    this.success,
    this.message,
  });

  factory RequestDataSummaryResModel.fromJson(Map<String, dynamic> json) =>
      RequestDataSummaryResModel(
        success: json["success"] as bool?,
        message: json["message"] as String?,
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
      };
}
