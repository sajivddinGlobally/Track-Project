// To parse this JSON data, do
//
//     final sendRequest = sendRequestFromJson(jsonString);

import 'dart:convert';

SendRequest sendRequestFromJson(String str) => SendRequest.fromJson(json.decode(str));

String sendRequestToJson(SendRequest data) => json.encode(data.toJson());

class SendRequest {
    bool? success;
    String? message;
    Data? data;

    SendRequest({
        this.success,
        this.message,
        this.data,
    });

    factory SendRequest.fromJson(Map<String, dynamic> json) => SendRequest(
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
    String? senderId;
    String? receiverId;
    String? status;
    String? pairKey;
    dynamic respondedAt;
    dynamic blockedBy;
    String? id;
    DateTime? createdAt;
    DateTime? updatedAt;

    Data({
        this.senderId,
        this.receiverId,
        this.status,
        this.pairKey,
        this.respondedAt,
        this.blockedBy,
        this.id,
        this.createdAt,
        this.updatedAt,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        senderId: json["senderId"],
        receiverId: json["receiverId"],
        status: json["status"],
        pairKey: json["pairKey"],
        respondedAt: json["respondedAt"],
        blockedBy: json["blockedBy"],
        id: json["_id"],
        createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
    );

    Map<String, dynamic> toJson() => {
        "senderId": senderId,
        "receiverId": receiverId,
        "status": status,
        "pairKey": pairKey,
        "respondedAt": respondedAt,
        "blockedBy": blockedBy,
        "_id": id,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
    };
}
