// To parse this JSON data, do
//
//     final getNotificationListModel = getNotificationListModelFromJson(jsonString);

import 'dart:convert';

GetNotificationListModel getNotificationListModelFromJson(String str) => GetNotificationListModel.fromJson(json.decode(str));

String getNotificationListModelToJson(GetNotificationListModel data) => json.encode(data.toJson());

class GetNotificationListModel {
    bool? success;
    String? message;
    int? unreadCount;
    int? totalNotifications;
    int? currentPage;
    int? totalPages;
    List<Datum>? data;

    GetNotificationListModel({
        this.success,
        this.message,
        this.unreadCount,
        this.totalNotifications,
        this.currentPage,
        this.totalPages,
        this.data,
    });

    factory GetNotificationListModel.fromJson(Map<String, dynamic> json) => GetNotificationListModel(
        success: json["success"] is bool ? json["success"] : (json["success"] == "true"),
        message: json["message"]?.toString(),
        unreadCount: json["unreadCount"] is int ? json["unreadCount"] : int.tryParse(json["unreadCount"]?.toString() ?? ''),
        totalNotifications: json["totalNotifications"] is int ? json["totalNotifications"] : int.tryParse(json["totalNotifications"]?.toString() ?? ''),
        currentPage: json["currentPage"] is int ? json["currentPage"] : int.tryParse(json["currentPage"]?.toString() ?? ''),
        totalPages: json["totalPages"] is int ? json["totalPages"] : int.tryParse(json["totalPages"]?.toString() ?? ''),
        data: json["data"] == null ? [] : List<Datum>.from((json["data"] as List).map((x) => Datum.fromJson(x as Map<String, dynamic>))),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "unreadCount": unreadCount,
        "totalNotifications": totalNotifications,
        "currentPage": currentPage,
        "totalPages": totalPages,
        "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
    };
}

class Datum {
    String? id;
    String? title;
    String? message;
    String? type;
    bool? isRead;
    SenderId? senderId;
    DateTime? createdAt;

    Datum({
        this.id,
        this.title,
        this.message,
        this.type,
        this.isRead,
        this.senderId,
        this.createdAt,
    });

    factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        id: json["_id"]?.toString() ?? json["id"]?.toString(),
        title: json["title"]?.toString(),
        message: json["message"]?.toString(),
        type: json["type"]?.toString(),
        isRead: json["isRead"] is bool ? json["isRead"] : (json["isRead"] == "true" || json["isRead"] == 1),
        senderId: json["senderId"] is Map<String, dynamic>
            ? SenderId.fromJson(json["senderId"] as Map<String, dynamic>)
            : (json["senderId"] is String
                ? SenderId(id: json["senderId"] as String)
                : null),
        createdAt: json["createdAt"] == null
            ? null
            : DateTime.tryParse(json["createdAt"].toString()),
    );

    Map<String, dynamic> toJson() => {
        "_id": id,
        "title": title,
        "message": message,
        "type": type,
        "isRead": isRead,
        "senderId": senderId?.toJson(),
        "createdAt": createdAt?.toIso8601String(),
    };
}

class SenderId {
    String? id;
    String? name;
    String? profileImage;

    SenderId({
        this.id,
        this.name,
        this.profileImage,
    });

    factory SenderId.fromJson(Map<String, dynamic> json) => SenderId(
        id: json["_id"]?.toString() ?? json["id"]?.toString(),
        name: json["name"]?.toString(),
        profileImage: json["profileImage"]?.toString(),
    );

    Map<String, dynamic> toJson() => {
        "_id": id,
        "name": name,
        "profileImage": profileImage,
    };
}
