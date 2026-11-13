// To parse this JSON data, do
//
//     final sendNotificatonResModel = sendNotificatonResModelFromJson(jsonString);

import 'dart:convert';

SendNotificatonResModel sendNotificatonResModelFromJson(String str) => SendNotificatonResModel.fromJson(json.decode(str));

String sendNotificatonResModelToJson(SendNotificatonResModel data) => json.encode(data.toJson());

class SendNotificatonResModel {
    bool? success;
    String? message;
    Data? data;

    SendNotificatonResModel({
        this.success,
        this.message,
        this.data,
    });

    factory SendNotificatonResModel.fromJson(Map<String, dynamic> json) => SendNotificatonResModel(
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
    String? notificationId;
    String? userId;
    String? senderId;
    String? type;
    bool? pushSent;

    Data({
        this.notificationId,
        this.userId,
        this.senderId,
        this.type,
        this.pushSent,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        notificationId: json["notificationId"],
        userId: json["userId"],
        senderId: json["senderId"],
        type: json["type"],
        pushSent: json["pushSent"],
    );

    Map<String, dynamic> toJson() => {
        "notificationId": notificationId,
        "userId": userId,
        "senderId": senderId,
        "type": type,
        "pushSent": pushSent,
    };
}
