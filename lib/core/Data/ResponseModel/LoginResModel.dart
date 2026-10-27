// To parse this JSON data, do
//
//     final loginResModel = loginResModelFromJson(jsonString);

import 'dart:convert';

LoginResModel loginResModelFromJson(String str) =>
    LoginResModel.fromJson(json.decode(str));

String loginResModelToJson(LoginResModel data) => json.encode(data.toJson());

class LoginResModel {
  bool? success;
  bool? isParentConsentPending;
  String? message;
  Data? data;

  LoginResModel({
    this.success,
    this.isParentConsentPending,
    this.message,
    this.data,
  });

  factory LoginResModel.fromJson(Map<String, dynamic> json) => LoginResModel(
    success: json["success"],
    isParentConsentPending: json["isParentConsentPending"],
    message: json["message"],
    data: json["data"] == null ? null : Data.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    if (isParentConsentPending != null)
      "isParentConsentPending": isParentConsentPending,
    "message": message,
    "data": data?.toJson(),
  };
}

class Data {
  User? user;
  String? token;

  Data({this.user, this.token});

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    user: json["user"] == null ? null : User.fromJson(json["user"]),
    token: json["token"],
  );

  Map<String, dynamic> toJson() => {"user": user?.toJson(), "token": token};
}

class User {
  String? id;
  String? name;
  String? email;
  String? phone;
  String? role;
  String? parentPhone;
  String? profileImage;
  bool? isVerified;
  bool? isProfileComplete;

  User({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.role,
    this.parentPhone,
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
    parentPhone: json["parentPhone"],
    profileImage: json["profileImage"],
    isVerified: json["isVerified"],
    isProfileComplete: json["isProfileComplete"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "email": email,
    "phone": phone,
    if (role != null) "role": role,
    if (parentPhone != null) "parentPhone": parentPhone,
    "profileImage": profileImage,
    "isVerified": isVerified,
    "isProfileComplete": isProfileComplete,
  };
}
