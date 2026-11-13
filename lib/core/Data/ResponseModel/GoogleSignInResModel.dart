import 'dart:convert';

GoogleSignInResModel googleSignInResModelFromJson(String str) =>
    GoogleSignInResModel.fromJson(json.decode(str));

String googleSignInResModelToJson(GoogleSignInResModel data) =>
    json.encode(data.toJson());

class GoogleSignInResModel {
  bool? success;
  String? message;
  GoogleSignInData? data;

  GoogleSignInResModel({
    this.success,
    this.message,
    this.data,
  });

  factory GoogleSignInResModel.fromJson(Map<String, dynamic> json) =>
      GoogleSignInResModel(
        success: json["success"],
        message: json["message"]?.toString(),
        data:
            json["data"] == null
                ? null
                : GoogleSignInData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "data": data?.toJson(),
  };
}

class GoogleSignInData {
  String? token;
  GoogleUser? user;

  GoogleSignInData({this.token, this.user});

  factory GoogleSignInData.fromJson(Map<String, dynamic> json) =>
      GoogleSignInData(
        token: json["token"]?.toString(),
        user: json["user"] == null ? null : GoogleUser.fromJson(json["user"]),
      );

  Map<String, dynamic> toJson() => {
    "token": token,
    "user": user?.toJson(),
  };
}

class GoogleUser {
  String? id;
  String? name;
  String? email;
  String? phone;
  String? currentAddress;
  String? profileImage;
  String? role;
  bool? isVerified;
  bool? isProfileComplete;
  bool? requiresAdultReconsent;

  GoogleUser({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.currentAddress,
    this.profileImage,
    this.role,
    this.isVerified,
    this.isProfileComplete,
    this.requiresAdultReconsent,
  });

  factory GoogleUser.fromJson(Map<String, dynamic> json) => GoogleUser(
    id: json["id"]?.toString() ?? json["_id"]?.toString(),
    name: json["name"]?.toString(),
    email: json["email"]?.toString(),
    phone: json["phone"]?.toString(),
    currentAddress: json["currentAddress"]?.toString(),
    profileImage: json["profileImage"]?.toString(),
    role: json["role"]?.toString(),
    isVerified: json["isVerified"] == true,
    isProfileComplete: json["isProfileComplete"] == true,
    requiresAdultReconsent: json["requiresAdultReconsent"] == true,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "email": email,
    "phone": phone,
    "currentAddress": currentAddress,
    "profileImage": profileImage,
    "role": role,
    "isVerified": isVerified,
    "isProfileComplete": isProfileComplete,
    "requiresAdultReconsent": requiresAdultReconsent,
  };
}

