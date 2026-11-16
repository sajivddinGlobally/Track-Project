import 'dart:convert';

DeleteNotificationResModel deleteNotificationResModelFromJson(String str) =>
    DeleteNotificationResModel.fromJson(json.decode(str));

String deleteNotificationResModelToJson(DeleteNotificationResModel data) =>
    json.encode(data.toJson());

class DeleteNotificationResModel {
  bool? success;
  String? message;
  int? deletedCount;

  DeleteNotificationResModel({
    this.success,
    this.message,
    this.deletedCount,
  });

  factory DeleteNotificationResModel.fromJson(Map<String, dynamic> json) =>
      DeleteNotificationResModel(
        success: json["success"] is bool
            ? json["success"]
            : (json["success"] == "true"),
        message: json["message"]?.toString(),
        deletedCount: json["deletedCount"] is int
            ? json["deletedCount"]
            : int.tryParse(json["deletedCount"]?.toString() ?? ''),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        if (deletedCount != null) "deletedCount": deletedCount,
      };
}

