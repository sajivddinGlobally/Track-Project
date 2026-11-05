// To parse this JSON data, do
//
//     final otpVerifyResModel = otpVerifyResModelFromJson(jsonString);

import 'dart:convert';

OtpVerifyResModel otpVerifyResModelFromJson(String str) => OtpVerifyResModel.fromJson(json.decode(str));

String otpVerifyResModelToJson(OtpVerifyResModel data) => json.encode(data.toJson());

class OtpVerifyResModel {
    bool? success;
    String? message;
    bool? requiresPayment;
    Data? data;

    OtpVerifyResModel({
        this.success,
        this.message,
        this.requiresPayment,
        this.data,
    });

    factory OtpVerifyResModel.fromJson(Map<String, dynamic> json) => OtpVerifyResModel(
        success: json["success"],
        message: json["message"],
        requiresPayment: json["requiresPayment"] ?? json["data"]?["requiresPayment"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        if (requiresPayment != null) "requiresPayment": requiresPayment,
        "data": data?.toJson(),
    };
}

class Data {
    String? token;
    User? user;
    bool? requiresPayment;

    Data({
        this.token,
        this.user,
        this.requiresPayment,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        token: json["token"],
        user: json["user"] == null ? null : User.fromJson(json["user"]),
        requiresPayment: json["requiresPayment"],
    );

    Map<String, dynamic> toJson() => {
        "token": token,
        "user": user?.toJson(),
        if (requiresPayment != null) "requiresPayment": requiresPayment,
    };
}

class User {
    String? id;
    String? name;
    String? email;
    String? phone;
    String? role;
    String? profileImage;
    bool? isVerified;
    bool? isProfileComplete;

    User({
        this.id,
        this.name,
        this.email,
        this.phone,
        this.role,
        this.profileImage,
        this.isVerified,
        this.isProfileComplete,
    });

    factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["id"],
        name: json["name"],
        email: json["email"],
        phone: json["phone"],
        role: json["role"],
        profileImage: json["profileImage"],
        isVerified: json["isVerified"],
        isProfileComplete: json["isProfileComplete"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "email": email,
        "phone": phone,
        "role": role,
        "profileImage": profileImage,
        "isVerified": isVerified,
        "isProfileComplete": isProfileComplete,
    };
}
