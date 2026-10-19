// To parse this JSON data, do
//
//     final trackFriendModel = trackFriendModelFromJson(jsonString);

import 'dart:convert';

TrackFriendModel trackFriendModelFromJson(String str) =>
    TrackFriendModel.fromJson(json.decode(str));

String trackFriendModelToJson(TrackFriendModel data) =>
    json.encode(data.toJson());

class TrackFriendModel {
  bool? success;
  String? message;
  Data? data;

  TrackFriendModel({this.success, this.message, this.data});

  factory TrackFriendModel.fromJson(Map<String, dynamic> json) =>
      TrackFriendModel(
        success: json["success"],
        message: json["message"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "data": data?.toJson(),
  };
}

class Data {
  List<FriendElement>? friends;
  Pagination? pagination;

  Data({this.friends, this.pagination});

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    friends: json["friends"] == null
        ? []
        : List<FriendElement>.from(
            json["friends"]!.map((x) => FriendElement.fromJson(x)),
          ),
    pagination: json["pagination"] == null
        ? null
        : Pagination.fromJson(json["pagination"]),
  );

  Map<String, dynamic> toJson() => {
    "friends": friends == null
        ? []
        : List<dynamic>.from(friends!.map((x) => x.toJson())),
    "pagination": pagination?.toJson(),
  };
}

class FriendElement {
  String? friendshipId;
  FriendFriend? friend;
  DateTime? friendsSince;
  bool? sharingMyLocation;
  bool? friendSharesLocationWithMe;

  FriendElement({
    this.friendshipId,
    this.friend,
    this.friendsSince,
    this.sharingMyLocation,
    this.friendSharesLocationWithMe,
  });

  factory FriendElement.fromJson(Map<String, dynamic> json) => FriendElement(
    friendshipId: json["friendshipId"],
    friend: json["friend"] == null
        ? null
        : FriendFriend.fromJson(json["friend"]),
    friendsSince: json["friendsSince"] == null
        ? null
        : DateTime.parse(json["friendsSince"]),
    sharingMyLocation: json["sharingMyLocation"],
    friendSharesLocationWithMe: json["friendSharesLocationWithMe"],
  );

  Map<String, dynamic> toJson() => {
    "friendshipId": friendshipId,
    "friend": friend?.toJson(),
    "friendsSince": friendsSince?.toIso8601String(),
    "sharingMyLocation": sharingMyLocation,
    "friendSharesLocationWithMe": friendSharesLocationWithMe,
  };
}

class FriendFriend {
  String? id;
  String? name;
  String? profileImage;
  String? currentAddress;
  String? permanentAddress;
  String? campusLocation;
  String? graduationYear;
  String? bio;
  String? profession;
  String? education;
  String? city;
  String? state;
  String? country;
  String? school;
  String? college;
  String? villageTown;
  String? pincode;

  FriendFriend({
    this.id,
    this.name,
    this.profileImage,
    this.currentAddress,
    this.permanentAddress,
    this.campusLocation,
    this.graduationYear,
    this.bio,
    this.profession,
    this.education,
    this.city,
    this.state,
    this.country,
    this.school,
    this.college,
    this.villageTown,
    this.pincode,
  });

  factory FriendFriend.fromJson(Map<String, dynamic> json) => FriendFriend(
    id: json["_id"],
    name: json["name"],
    profileImage: json["profileImage"],
    currentAddress: json["currentAddress"],
    permanentAddress: json["permanentAddress"],
    campusLocation: json["campusLocation"],
    graduationYear: json["graduationYear"],
    bio: json["bio"],
    profession: json["profession"],
    education: json["education"],
    city: json["city"],
    state: json["state"],
    country: json["country"],
    school: json["school"],
    college: json["college"],
    villageTown: json["villageTown"],
    pincode: json["pincode"],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "name": name,
    "profileImage": profileImage,
    "currentAddress": currentAddress,
    "permanentAddress": permanentAddress,
    "campusLocation": campusLocation,
    "graduationYear": graduationYear,
    "bio": bio,
    "profession": profession,
    "education": education,
    "city": city,
    "state": state,
    "country": country,
    "school": school,
    "college": college,
    "villageTown": villageTown,
    "pincode": pincode,
  };
}

class Pagination {
  String? page;
  String? limit;
  int? total;
  int? totalPages;

  Pagination({this.page, this.limit, this.total, this.totalPages});

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
    page: json["page"],
    limit: json["limit"],
    total: json["total"],
    totalPages: json["totalPages"],
  );

  Map<String, dynamic> toJson() => {
    "page": page,
    "limit": limit,
    "total": total,
    "totalPages": totalPages,
  };
}
