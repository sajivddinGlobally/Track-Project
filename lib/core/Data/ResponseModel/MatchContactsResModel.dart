// To parse this JSON data, do
//
//     final matchContactsResModel = matchContactsResModelFromJson(jsonString);

import 'dart:convert';

MatchContactsResModel matchContactsResModelFromJson(String str) => MatchContactsResModel.fromJson(json.decode(str));

String matchContactsResModelToJson(MatchContactsResModel data) => json.encode(data.toJson());

class MatchContactsResModel {
    bool? success;
    String? message;
    Data? data;

    MatchContactsResModel({
        this.success,
        this.message,
        this.data,
    });

    factory MatchContactsResModel.fromJson(Map<String, dynamic> json) => MatchContactsResModel(
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
    List<Contact>? contacts;
    List<InviteItem>? inviteList;
    int? count;

    Data({
        this.contacts,
        this.inviteList,
        this.count,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        contacts: json["contacts"] == null ? [] : List<Contact>.from(json["contacts"]!.map((x) => Contact.fromJson(x))),
        inviteList: json["inviteList"] == null ? [] : List<InviteItem>.from(json["inviteList"]!.map((x) => InviteItem.fromJson(x))),
        count: json["count"],
    );

    Map<String, dynamic> toJson() => {
        "contacts": contacts == null ? [] : List<dynamic>.from(contacts!.map((x) => x.toJson())),
        "inviteList": inviteList == null ? [] : List<dynamic>.from(inviteList!.map((x) => x.toJson())),
        "count": count,
    };
}

class InviteItem {
    String? contactName;
    String? phone;

    InviteItem({
        this.contactName,
        this.phone,
    });

    factory InviteItem.fromJson(Map<String, dynamic> json) => InviteItem(
        contactName: json["contactName"]?.toString(),
        phone: json["phone"]?.toString(),
    );

    Map<String, dynamic> toJson() => {
        "contactName": contactName,
        "phone": phone,
    };
}

class Contact {
    String? contactName;
    String? matchedPhone;
    User? user;
    String? connectionStatus;
    String? action;

    Contact({
        this.contactName,
        this.matchedPhone,
        this.user,
        this.connectionStatus,
        this.action,
    });

    factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        contactName: json["contactName"],
        matchedPhone: json["matchedPhone"],
        user: json["user"] == null ? null : User.fromJson(json["user"]),
        connectionStatus: json["connectionStatus"],
        action: json["action"],
    );

    Map<String, dynamic> toJson() => {
        "contactName": contactName,
        "matchedPhone": matchedPhone,
        "user": user?.toJson(),
        "connectionStatus": connectionStatus,
        "action": action,
    };
}

class User {
    String? userId;
    String? name;
    dynamic profileImage;

    User({
        this.userId,
        this.name,
        this.profileImage,
    });

    factory User.fromJson(Map<String, dynamic> json) => User(
        userId: json["userId"],
        name: json["name"],
        profileImage: json["profileImage"],
    );

    Map<String, dynamic> toJson() => {
        "userId": userId,
        "name": name,
        "profileImage": profileImage,
    };
}
