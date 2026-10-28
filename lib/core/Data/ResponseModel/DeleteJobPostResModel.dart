import 'dart:convert';

DeleteJobPostResModel deleteJobPostResModelFromJson(String str) =>
    DeleteJobPostResModel.fromJson(json.decode(str));

String deleteJobPostResModelToJson(DeleteJobPostResModel data) =>
    json.encode(data.toJson());

class DeleteJobPostResModel {
  bool? success;
  String? message;

  DeleteJobPostResModel({
    this.success,
    this.message,
  });

  factory DeleteJobPostResModel.fromJson(Map<String, dynamic> json) =>
      DeleteJobPostResModel(
        success: json["success"] as bool?,
        message: json["message"] as String?,
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
      };
}
