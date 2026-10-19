// To parse this JSON data, do
//
//     final getMyProfileModel = getMyProfileModelFromJson(jsonString);

import 'dart:convert';

GetMyProfileModel getMyProfileModelFromJson(String str) => GetMyProfileModel.fromJson(json.decode(str));

String getMyProfileModelToJson(GetMyProfileModel data) => json.encode(data.toJson());

class GetMyProfileModel {
    bool? success;
    int? statusCode;
    String? message;
    Data? data;

    GetMyProfileModel({
        this.success,
        this.statusCode,
        this.message,
        this.data,
    });

    factory GetMyProfileModel.fromJson(Map<String, dynamic> json) => GetMyProfileModel(
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
    String? role;
    String? currentAddress;
    String? permanentAddress;
    String? campusLocation;
    String? graduationYear;
    String? id;
    String? name;
    String? email;
    String? phone;
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
    String? pincode;
    DateTime? createdAt;
    DateTime? updatedAt;
    bool? isBlocked;

    User({
        this.location,
        this.role,
        this.currentAddress,
        this.permanentAddress,
        this.campusLocation,
        this.graduationYear,
        this.id,
        this.name,
        this.email,
        this.phone,
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
        this.pincode,
        this.createdAt,
        this.updatedAt,
        this.isBlocked,
    });

    factory User.fromJson(Map<String, dynamic> json) => User(
        location: json["location"] == null ? null : Location.fromJson(json["location"]),
        role: json["role"],
        currentAddress: json["currentAddress"],
        permanentAddress: json["permanentAddress"],
        campusLocation: json["campusLocation"],
        graduationYear: json["graduationYear"],
        id: json["_id"],
        name: json["name"],
        email: json["email"],
        phone: json["phone"],
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
        pincode: json["pincode"],
        createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
        isBlocked: json["isBlocked"],
    );

    Map<String, dynamic> toJson() => {
        "location": location?.toJson(),
        "role": role,
        "currentAddress": currentAddress,
        "permanentAddress": permanentAddress,
        "campusLocation": campusLocation,
        "graduationYear": graduationYear,
        "_id": id,
        "name": name,
        "email": email,
        "phone": phone,
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
        "pincode": pincode,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
        "isBlocked": isBlocked,
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
