// To parse this JSON data, do
//
//     final uploadImageResModel = uploadImageResModelFromJson(jsonString);

import 'dart:convert';

UploadImageResModel uploadImageResModelFromJson(String str) => UploadImageResModel.fromJson(json.decode(str));

String uploadImageResModelToJson(UploadImageResModel data) => json.encode(data.toJson());

class UploadImageResModel {
    bool? success;
    int? statusCode;
    String? message;
    Data? data;

    UploadImageResModel({
        this.success,
        this.statusCode,
        this.message,
        this.data,
    });

    factory UploadImageResModel.fromJson(Map<String, dynamic> json) => UploadImageResModel(
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
    String? imageName;
    String? imageUrl;
    User? user;

    Data({
        this.imageName,
        this.imageUrl,
        this.user,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        imageName: json["imageName"],
        imageUrl: json["imageUrl"],
        user: json["user"] == null ? null : User.fromJson(json["user"]),
    );

    Map<String, dynamic> toJson() => {
        "imageName": imageName,
        "imageUrl": imageUrl,
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
