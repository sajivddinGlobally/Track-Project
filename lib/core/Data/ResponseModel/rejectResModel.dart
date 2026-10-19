// To parse this JSON data, do
//
//     final rejectResModel = rejectResModelFromJson(jsonString);

import 'dart:convert';

RejectResModel rejectResModelFromJson(String str) => RejectResModel.fromJson(json.decode(str));

String rejectResModelToJson(RejectResModel data) => json.encode(data.toJson());

class RejectResModel {
    bool? success;
    String? message;
    Data? data;

    RejectResModel({
        this.success,
        this.message,
        this.data,
    });

    factory RejectResModel.fromJson(Map<String, dynamic> json) => RejectResModel(
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
    String? senderId;
    String? receiverId;
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
        senderId: json["senderId"],
        receiverId: json["receiverId"],
        status: json["status"],
        pairKey: json["pairKey"],
        respondedAt: json["respondedAt"] == null ? null : DateTime.parse(json["respondedAt"]),
        blockedBy: json["blockedBy"],
        createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
    );

    Map<String, dynamic> toJson() => {
        "_id": id,
        "senderId": senderId,
        "receiverId": receiverId,
        "status": status,
        "pairKey": pairKey,
        "respondedAt": respondedAt?.toIso8601String(),
        "blockedBy": blockedBy,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
    };
}
