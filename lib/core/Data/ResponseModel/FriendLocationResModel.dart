import 'package:track_loved/core/Data/BodyModel/UpdateUserLocationBodyModel.dart';

class FriendLocationResModel {
  final bool? success;
  final String? message;
  final FriendLocationData? data;

  FriendLocationResModel({
    this.success,
    this.message,
    this.data,
  });

  factory FriendLocationResModel.fromJson(Map<String, dynamic> json) =>
      FriendLocationResModel(
        success: json["success"] as bool?,
        message: json["message"]?.toString(),
        data: json["data"] == null
            ? null
            : FriendLocationData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        if (message != null) "message": message,
        "data": data?.toJson(),
      };
}

class FriendLocationData {
  final String? userId;
  final LocationPoint? location;
  final DateTime? updatedAt;

  FriendLocationData({
    this.userId,
    this.location,
    this.updatedAt,
  });

  factory FriendLocationData.fromJson(Map<String, dynamic> json) =>
      FriendLocationData(
        userId: json["userId"]?.toString(),
        location: json["location"] == null
            ? null
            : LocationPoint.fromJson(json["location"]),
        updatedAt: json["updatedAt"] == null
            ? null
            : DateTime.tryParse(json["updatedAt"].toString()),
      );

  Map<String, dynamic> toJson() => {
        "userId": userId,
        "location": location?.toJson(),
        "updatedAt": updatedAt?.toIso8601String(),
      };
}

