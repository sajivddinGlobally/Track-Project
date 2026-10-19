// To parse this JSON data, do
//
//     final updateProfileResModel = updateProfileResModelFromJson(jsonString);

import 'dart:convert';

UpdateProfileResModel updateProfileResModelFromJson(String str) => UpdateProfileResModel.fromJson(json.decode(str));

String updateProfileResModelToJson(UpdateProfileResModel data) => json.encode(data.toJson());

class UpdateProfileResModel {
    bool? success;
    int? statusCode;
    String? message;
    Data? data;

    UpdateProfileResModel({
        this.success,
        this.statusCode,
        this.message,
        this.data,
    });

    factory UpdateProfileResModel.fromJson(Map<String, dynamic> json) => UpdateProfileResModel(
        success: json["success"],
        statusCode: json["statusCode"],
        message: json["message"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "statusCode": statusCode,
        "message": message,
        "data": data?.toJson(),
    };
}

class Data {
    User? user;

    Data({
        this.user,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        user: json["user"] == null ? null : User.fromJson(json["user"]),
    );

    Map<String, dynamic> toJson() => {
        "user": user?.toJson(),
    };
}

class User {
    Location? location;
    String? id;
    String? name;
    String? email;
    String? phone;
    bool? isVerified;
    bool? isBlocked;
    String? role;
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
    DateTime? createdAt;
    DateTime? updatedAt;
    String? campusLocation;
    String? currentAddress;
    String? graduationYear;
    String? permanentAddress;

    User({
        this.location,
        this.id,
        this.name,
        this.email,
        this.phone,
        this.isVerified,
        this.isBlocked,
        this.role,
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
        this.createdAt,
        this.updatedAt,
        this.campusLocation,
        this.currentAddress,
        this.graduationYear,
        this.permanentAddress,
    });

    factory User.fromJson(Map<String, dynamic> json) => User(
        location: json["location"] == null ? null : Location.fromJson(json["location"]),
        id: json["_id"],
        name: json["name"],
        email: json["email"],
        phone: json["phone"],
        isVerified: json["isVerified"],
        isBlocked: json["isBlocked"],
        role: json["role"],
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
        createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
        campusLocation: json["campusLocation"],
        currentAddress: json["currentAddress"],
        graduationYear: json["graduationYear"],
        permanentAddress: json["permanentAddress"],
    );

    Map<String, dynamic> toJson() => {
        "location": location?.toJson(),
        "_id": id,
        "name": name,
        "email": email,
        "phone": phone,
        "isVerified": isVerified,
        "isBlocked": isBlocked,
        "role": role,
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
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
        "campusLocation": campusLocation,
        "currentAddress": currentAddress,
        "graduationYear": graduationYear,
        "permanentAddress": permanentAddress,
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
