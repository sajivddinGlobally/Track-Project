// To parse this JSON data, do
//     final locationSharingActionResModel = locationSharingActionResModelFromJson(jsonString);

import 'dart:convert';

LocationSharingActionResModel locationSharingActionResModelFromJson(String str) =>
    LocationSharingActionResModel.fromJson(json.decode(str));

String locationSharingActionResModelToJson(LocationSharingActionResModel data) =>
    json.encode(data.toJson());

class LocationSharingActionResModel {
  bool? success;
  String? message;
  LocationSharingActionData? data;

  LocationSharingActionResModel({
    this.success,
    this.message,
    this.data,
  });

  factory LocationSharingActionResModel.fromJson(Map<String, dynamic> json) =>
      LocationSharingActionResModel(
        success: json["success"],
        message: json["message"],
        data: json["data"] == null
            ? null
            : LocationSharingActionData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "data": data?.toJson(),
  };
}

class LocationSharingActionData {
  String? action;
  bool? locationAccess;
  int? disabledFriendsCount;
  int? renewedFriendsCount;
  List<String>? affectedFriendIds;
  DateTime? expiresAt;
  int? pushSentCount;
  int? pushFailedCount;
  OwnerNotification? ownerNotification;

  LocationSharingActionData({
    this.action,
    this.locationAccess,
    this.disabledFriendsCount,
    this.renewedFriendsCount,
    this.affectedFriendIds,
    this.expiresAt,
    this.pushSentCount,
    this.pushFailedCount,
    this.ownerNotification,
  });

  factory LocationSharingActionData.fromJson(Map<String, dynamic> json) =>
      LocationSharingActionData(
        action: json["action"],
        locationAccess: json["locationAccess"],
        disabledFriendsCount: json["disabledFriendsCount"] is int
            ? json["disabledFriendsCount"]
            : int.tryParse(json["disabledFriendsCount"]?.toString() ?? ''),
        renewedFriendsCount: json["renewedFriendsCount"] is int
            ? json["renewedFriendsCount"]
            : int.tryParse(json["renewedFriendsCount"]?.toString() ?? ''),
        affectedFriendIds: json["affectedFriendIds"] == null
            ? []
            : List<String>.from(json["affectedFriendIds"]!.map((x) => x.toString())),
        expiresAt: json["expiresAt"] == null
            ? null
            : DateTime.tryParse(json["expiresAt"].toString()),
        pushSentCount: json["pushSentCount"] is int
            ? json["pushSentCount"]
            : int.tryParse(json["pushSentCount"]?.toString() ?? ''),
        pushFailedCount: json["pushFailedCount"] is int
            ? json["pushFailedCount"]
            : int.tryParse(json["pushFailedCount"]?.toString() ?? ''),
        ownerNotification: json["ownerNotification"] == null
            ? null
            : OwnerNotification.fromJson(json["ownerNotification"]),
      );

  Map<String, dynamic> toJson() => {
    "action": action,
    "locationAccess": locationAccess,
    "disabledFriendsCount": disabledFriendsCount,
    "renewedFriendsCount": renewedFriendsCount,
    "affectedFriendIds": affectedFriendIds == null
        ? []
        : List<dynamic>.from(affectedFriendIds!.map((x) => x)),
    "expiresAt": expiresAt?.toIso8601String(),
    "pushSentCount": pushSentCount,
    "pushFailedCount": pushFailedCount,
    "ownerNotification": ownerNotification?.toJson(),
  };
}

class OwnerNotification {
  bool? inAppSaved;
  bool? pushSent;
  bool? pushFailed;

  OwnerNotification({
    this.inAppSaved,
    this.pushSent,
    this.pushFailed,
  });

  factory OwnerNotification.fromJson(Map<String, dynamic> json) =>
      OwnerNotification(
        inAppSaved: json["inAppSaved"],
        pushSent: json["pushSent"],
        pushFailed: json["pushFailed"],
      );

  Map<String, dynamic> toJson() => {
    "inAppSaved": inAppSaved,
    "pushSent": pushSent,
    "pushFailed": pushFailed,
  };
}

