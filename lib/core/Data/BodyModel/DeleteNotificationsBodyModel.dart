import 'dart:convert';

DeleteNotificationsBodyModel deleteNotificationsBodyModelFromJson(String str) =>
    DeleteNotificationsBodyModel.fromJson(json.decode(str));

String deleteNotificationsBodyModelToJson(DeleteNotificationsBodyModel data) =>
    json.encode(data.toJson());

class DeleteNotificationsBodyModel {
  List<String>? notificationIds;
  bool? deleteAll;

  DeleteNotificationsBodyModel({
    this.notificationIds,
    this.deleteAll,
  });

  factory DeleteNotificationsBodyModel.fromJson(Map<String, dynamic> json) =>
      DeleteNotificationsBodyModel(
        notificationIds: json["notificationIds"] == null
            ? null
            : List<String>.from(
                json["notificationIds"]!.map((x) => x.toString()),
              ),
        deleteAll: json["deleteAll"] is bool
            ? json["deleteAll"]
            : (json["deleteAll"] == "true"),
      );

  Map<String, dynamic> toJson() => {
        if (notificationIds != null) "notificationIds": notificationIds,
        if (deleteAll != null) "deleteAll": deleteAll,
      };
}

