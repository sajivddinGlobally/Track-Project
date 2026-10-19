// To parse this JSON data, do
//
//     final acceptResModel = acceptResModelFromJson(jsonString);

import 'dart:convert';

AcceptResModel acceptResModelFromJson(String str) => AcceptResModel.fromJson(json.decode(str));

String acceptResModelToJson(AcceptResModel data) => json.encode(data.toJson());

class AcceptResModel {
    bool? success;
    String? message;
    Data? data;

    AcceptResModel({
        this.success,
        this.message,
        this.data,
    });

    factory AcceptResModel.fromJson(Map<String, dynamic> json) => AcceptResModel(
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
    String? id;
    ErId? senderId;
    ErId? receiverId;
    String? status;
    String? pairKey;
    DateTime? respondedAt;
    dynamic blockedBy;
    DateTime? createdAt;
    DateTime? updatedAt;

    Data({
        this.id,
        this.senderId,
        this.receiverId,
        this.status,
        this.pairKey,
        this.respondedAt,
        this.blockedBy,
        this.createdAt,
        this.updatedAt,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: json["_id"],
        senderId: json["senderId"] == null ? null : ErId.fromJson(json["senderId"]),
        receiverId: json["receiverId"] == null ? null : ErId.fromJson(json["receiverId"]),
        status: json["status"],
        pairKey: json["pairKey"],
        respondedAt: json["respondedAt"] == null ? null : DateTime.parse(json["respondedAt"]),
        blockedBy: json["blockedBy"],
        createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
    );

    Map<String, dynamic> toJson() => {
        "_id": id,
        "senderId": senderId?.toJson(),
        "receiverId": receiverId?.toJson(),
        "status": status,
        "pairKey": pairKey,
        "respondedAt": respondedAt?.toIso8601String(),
        "blockedBy": blockedBy,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
    };
}

class ErId {
    String? id;
    String? name;
    String? email;
    String? phone;
    String? profileImage;
    String? bio;
    String? profession;
    String? education;
    String? city;
    String? state;
    String? country;
    String? school;
    String? villageTown;
    String? pincode;

    ErId({
        this.id,
        this.name,
        this.email,
        this.phone,
        this.profileImage,
        this.bio,
        this.profession,
        this.education,
        this.city,
        this.state,
        this.country,
        this.school,
        this.villageTown,
        this.pincode,
    });

    factory ErId.fromJson(Map<String, dynamic> json) => ErId(
        id: json["_id"],
        name: json["name"],
        email: json["email"],
        phone: json["phone"],
        profileImage: json["profileImage"],
        bio: json["bio"],
        profession: json["profession"],
        education: json["education"],
        city: json["city"],
        state: json["state"],
        country: json["country"],
        school: json["school"],
        villageTown: json["villageTown"],
        pincode: json["pincode"],
    );

    Map<String, dynamic> toJson() => {
        "_id": id,
        "name": name,
        "email": email,
        "phone": phone,
        "profileImage": profileImage,
        "bio": bio,
        "profession": profession,
        "education": education,
        "city": city,
        "state": state,
        "country": country,
        "school": school,
        "villageTown": villageTown,
        "pincode": pincode,
    };
}
