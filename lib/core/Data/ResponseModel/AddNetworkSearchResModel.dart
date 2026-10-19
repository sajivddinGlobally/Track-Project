// To parse this JSON data, do
//
//     final addNetworkSearchResModel = addNetworkSearchResModelFromJson(jsonString);

import 'dart:convert';

AddNetworkSearchResModel addNetworkSearchResModelFromJson(String str) => AddNetworkSearchResModel.fromJson(json.decode(str));

String addNetworkSearchResModelToJson(AddNetworkSearchResModel data) => json.encode(data.toJson());

class AddNetworkSearchResModel {
    bool? success;
    String? message;
    Data? data;

    AddNetworkSearchResModel({
        this.success,
        this.message,
        this.data,
    });

    factory AddNetworkSearchResModel.fromJson(Map<String, dynamic> json) => AddNetworkSearchResModel(
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
    List<User>? users;
    Pagination? pagination;

    Data({
        this.users,
        this.pagination,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        users: json["users"] == null ? [] : List<User>.from(json["users"]!.map((x) => User.fromJson(x))),
        pagination: json["pagination"] == null ? null : Pagination.fromJson(json["pagination"]),
    );

    Map<String, dynamic> toJson() => {
        "users": users == null ? [] : List<dynamic>.from(users!.map((x) => x.toJson())),
        "pagination": pagination?.toJson(),
    };
}

class Pagination {
    int? total;
    int? page;
    int? limit;
    int? totalPages;
    bool? hasNextPage;
    bool? hasPreviousPage;

    Pagination({
        this.total,
        this.page,
        this.limit,
        this.totalPages,
        this.hasNextPage,
        this.hasPreviousPage,
    });

    factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
        total: json["total"],
        page: json["page"],
        limit: json["limit"],
        totalPages: json["totalPages"],
        hasNextPage: json["hasNextPage"],
        hasPreviousPage: json["hasPreviousPage"],
    );

    Map<String, dynamic> toJson() => {
        "total": total,
        "page": page,
        "limit": limit,
        "totalPages": totalPages,
        "hasNextPage": hasNextPage,
        "hasPreviousPage": hasPreviousPage,
    };
}

class User {
    String? id;
    String? name;
    bool? isVerified;
    String? profileImage;
    String? bio;
    String? profession;
    String? education;
    String? city;
    String? state;
    String? country;
    String? school;
    String? college;
    String? villageTown;
    Location? location;
    String? relationshipStatus;
    String? pincode;
    String? requestStatus;
    String? campusLocation;
    String? currentAddress;
    String? permanentAddress;
    String? graduationYear;

    User({
        this.id,
        this.name,
        this.isVerified,
        this.profileImage,
        this.bio,
        this.profession,
        this.education,
        this.city,
        this.state,
        this.country,
        this.school,
        this.college,
        this.villageTown,
        this.location,
        this.relationshipStatus,
        this.pincode,
        this.requestStatus,
        this.campusLocation,
        this.currentAddress,
        this.permanentAddress,
        this.graduationYear,
    });

    factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["_id"],
        name: json["name"],
        isVerified: json["isVerified"],
        profileImage: json["profileImage"],
        bio: json["bio"],
        profession: json["profession"],
        education: json["education"],
        city: json["city"],
        state: json["state"],
        country: json["country"],
        school: json["school"],
        college: json["college"],
        villageTown: json["villageTown"],
        location: json["location"] == null ? null : Location.fromJson(json["location"]),
        relationshipStatus: json["relationshipStatus"],
        pincode: json["pincode"],
        requestStatus: json["requestStatus"],
        campusLocation: json["campusLocation"],
        currentAddress: json["currentAddress"],
        permanentAddress: json["permanentAddress"],
        graduationYear: json["graduationYear"],
    );

    Map<String, dynamic> toJson() => {
        "_id": id,
        "name": name,
        "isVerified": isVerified,
        "profileImage": profileImage,
        "bio": bio,
        "profession": profession,
        "education": education,
        "city": city,
        "state": state,
        "country": country,
        "school": school,
        "college": college,
        "villageTown": villageTown,
        "location": location?.toJson(),
        "relationshipStatus": relationshipStatus,
        "pincode": pincode,
        "requestStatus": requestStatus,
        "campusLocation": campusLocation,
        "currentAddress": currentAddress,
        "permanentAddress": permanentAddress,
        "graduationYear": graduationYear,
    };
}

class Location {
    String? type;
    List<int>? coordinates;

    Location({
        this.type,
        this.coordinates,
    });

    factory Location.fromJson(Map<String, dynamic> json) => Location(
        type: json["type"],
        coordinates: json["coordinates"] == null ? [] : List<int>.from(json["coordinates"]!.map((x) => x)),
    );

    Map<String, dynamic> toJson() => {
        "type": type,
        "coordinates": coordinates == null ? [] : List<dynamic>.from(coordinates!.map((x) => x)),
    };
}
