// To parse this JSON data, do
//
//     final locationSharingReceivedResModel = locationSharingReceivedResModelFromJson(jsonString);

import 'dart:convert';

LocationSharingReceivedResModel locationSharingReceivedResModelFromJson(String str) =>
    LocationSharingReceivedResModel.fromJson(json.decode(str));

String locationSharingReceivedResModelToJson(LocationSharingReceivedResModel data) =>
    json.encode(data.toJson());

class LocationSharingReceivedResModel {
  bool? success;
  String? message;
  LocationSharingData? data;

  LocationSharingReceivedResModel({
    this.success,
    this.message,
    this.data,
  });

  factory LocationSharingReceivedResModel.fromJson(Map<String, dynamic> json) =>
      LocationSharingReceivedResModel(
        success: json["success"],
        message: json["message"],
        data: json["data"] == null ? null : LocationSharingData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data?.toJson(),
      };
}

class LocationSharingData {
  List<LocationSharingUser>? users;
  int? count;

  LocationSharingData({
    this.users,
    this.count,
  });

  factory LocationSharingData.fromJson(Map<String, dynamic> json) => LocationSharingData(
        users: json["users"] == null
            ? []
            : List<LocationSharingUser>.from(
                json["users"]!.map((x) => LocationSharingUser.fromJson(x)),
              ),
        count: json["count"],
      );

  Map<String, dynamic> toJson() => {
        "users": users == null ? [] : List<dynamic>.from(users!.map((x) => x.toJson())),
        "count": count,
      };
}

class LocationSharingUser {
  String? userId;
  String? name;
  String? profileImage;
  bool? access;
  UserLocation? location;
  DateTime? updatedAt;

  LocationSharingUser({
    this.userId,
    this.name,
    this.profileImage,
    this.access,
    this.location,
    this.updatedAt,
  });

  factory LocationSharingUser.fromJson(Map<String, dynamic> json) => LocationSharingUser(
        userId: json["userId"],
        name: json["name"],
        profileImage: json["profileImage"],
        access: json["access"],
        location: json["location"] == null ? null : UserLocation.fromJson(json["location"]),
        updatedAt: json["updatedAt"] == null
            ? null
            : DateTime.tryParse(json["updatedAt"].toString()),
      );

  Map<String, dynamic> toJson() => {
        "userId": userId,
        "name": name,
        "profileImage": profileImage,
        "access": access,
        "location": location?.toJson(),
        "updatedAt": updatedAt?.toIso8601String(),
      };

  double? get longitude {
    if (location?.coordinates != null && location!.coordinates!.isNotEmpty) {
      final val = location!.coordinates![0];
      return (val is num) ? val.toDouble() : double.tryParse(val.toString());
    }
    return null;
  }

  double? get latitude {
    if (location?.coordinates != null && location!.coordinates!.length > 1) {
      final val = location!.coordinates![1];
      return (val is num) ? val.toDouble() : double.tryParse(val.toString());
    }
    return null;
  }
}

class UserLocation {
  String? type;
  List<dynamic>? coordinates;

  UserLocation({
    this.type,
    this.coordinates,
  });

  factory UserLocation.fromJson(Map<String, dynamic> json) => UserLocation(
        type: json["type"],
        coordinates: json["coordinates"] == null
            ? []
            : List<dynamic>.from(json["coordinates"]!.map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "type": type,
        "coordinates":
            coordinates == null ? [] : List<dynamic>.from(coordinates!.map((x) => x)),
      };
}
