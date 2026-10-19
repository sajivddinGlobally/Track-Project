// To parse this JSON data, do
//
//     final otpVerifyResModel = otpVerifyResModelFromJson(jsonString);

import 'dart:convert';

OtpVerifyResModel otpVerifyResModelFromJson(String str) => OtpVerifyResModel.fromJson(json.decode(str));

String otpVerifyResModelToJson(OtpVerifyResModel data) => json.encode(data.toJson());

class OtpVerifyResModel {
    bool? success;
    String? message;
    Data? data;

    OtpVerifyResModel({
        this.success,
        this.message,
        this.data,
    });

    factory OtpVerifyResModel.fromJson(Map<String, dynamic> json) => OtpVerifyResModel(
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
    String? token;
    User? user;

    Data({
        this.token,
        this.user,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        token: json["token"],
        user: json["user"] == null ? null : User.fromJson(json["user"]),
    );

    Map<String, dynamic> toJson() => {
        "token": token,
        "user": user?.toJson(),
    };
}

class User {
    String? id;
    String? name;
    String? email;
    String? phone;
    String? role;
    bool? isVerified;
    bool? isProfileComplete;

    User({
        this.id,
        this.name,
        this.email,
        this.phone,
        this.role,
        this.isVerified,
        this.isProfileComplete,
    });

    factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["id"],
        name: json["name"],
        email: json["email"],
        phone: json["phone"],
        role: json["role"],
        isVerified: json["isVerified"],
        isProfileComplete: json["isProfileComplete"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "email": email,
        "phone": phone,
        "role": role,
        "isVerified": isVerified,
        "isProfileComplete": isProfileComplete,
    };
}
