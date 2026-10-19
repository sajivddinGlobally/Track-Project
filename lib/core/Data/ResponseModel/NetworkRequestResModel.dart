// To parse this JSON data, do
//
//     final networkRequestResModel = networkRequestResModelFromJson(jsonString);

import 'dart:convert';

NetworkRequestResModel networkRequestResModelFromJson(String str) => NetworkRequestResModel.fromJson(json.decode(str));

String networkRequestResModelToJson(NetworkRequestResModel data) => json.encode(data.toJson());

class NetworkRequestResModel {
    bool? success;
    String? message;
    Data? data;

    NetworkRequestResModel({
        this.success,
        this.message,
        this.data,
    });

    factory NetworkRequestResModel.fromJson(Map<String, dynamic> json) => NetworkRequestResModel(
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
    List<Request>? requests;
    Pagination? pagination;

    Data({
        this.requests,
        this.pagination,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        requests: json["requests"] == null ? [] : List<Request>.from(json["requests"]!.map((x) => Request.fromJson(x))),
        pagination: json["pagination"] == null ? null : Pagination.fromJson(json["pagination"]),
    );

    Map<String, dynamic> toJson() => {
        "requests": requests == null ? [] : List<dynamic>.from(requests!.map((x) => x.toJson())),
        "pagination": pagination?.toJson(),
    };
}

class Pagination {
    int? page;
    int? limit;
    int? total;
    int? totalPages;

    Pagination({
        this.page,
        this.limit,
        this.total,
        this.totalPages,
    });

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

class Request {
    String? id;
    SenderId? senderId;
    String? receiverId;
    String? status;
    String? pairKey;
    dynamic respondedAt;
    dynamic blockedBy;
    DateTime? createdAt;
    DateTime? updatedAt;

    Request({
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

    factory Request.fromJson(Map<String, dynamic> json) => Request(
        id: json["_id"],
        senderId: json["senderId"] == null ? null : SenderId.fromJson(json["senderId"]),
        receiverId: json["receiverId"],
        status: json["status"],
        pairKey: json["pairKey"],
        respondedAt: json["respondedAt"],
        blockedBy: json["blockedBy"],
        createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
    );

    Map<String, dynamic> toJson() => {
        "_id": id,
        "senderId": senderId?.toJson(),
        "receiverId": receiverId,
        "status": status,
        "pairKey": pairKey,
        "respondedAt": respondedAt,
        "blockedBy": blockedBy,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
    };
}

class SenderId {
    String? id;
    String? name;
    String? email;
    String? phone;
    bool? isVerified;
    bool? isProfileComplete;
    String? role;
    String? companyProfileStatus;
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
    String? villageTown;
    String? pincode;

    SenderId({
        this.id,
        this.name,
        this.email,
        this.phone,
        this.isVerified,
        this.isProfileComplete,
        this.role,
        this.companyProfileStatus,
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
        this.villageTown,
        this.pincode,
    });

    factory SenderId.fromJson(Map<String, dynamic> json) => SenderId(
        id: json["_id"],
        name: json["name"],
        email: json["email"],
        phone: json["phone"],
        isVerified: json["isVerified"],
        isProfileComplete: json["isProfileComplete"],
        role: json["role"],
        companyProfileStatus: json["companyProfileStatus"],
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
        villageTown: json["villageTown"],
        pincode: json["pincode"],
    );

    Map<String, dynamic> toJson() => {
        "_id": id,
        "name": name,
        "email": email,
        "phone": phone,
        "isVerified": isVerified,
        "isProfileComplete": isProfileComplete,
        "role": role,
        "companyProfileStatus": companyProfileStatus,
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
        "villageTown": villageTown,
        "pincode": pincode,
    };
}
