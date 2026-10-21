// To parse this JSON data, do
//
//     final chatHistoryResModel = chatHistoryResModelFromJson(jsonString);

import 'dart:convert';

ChatHistoryResModel chatHistoryResModelFromJson(String str) =>
    ChatHistoryResModel.fromJson(json.decode(str));

String chatHistoryResModelToJson(ChatHistoryResModel data) =>
    json.encode(data.toJson());

class ChatHistoryResModel {
  bool? success;
  String? message;
  ChatData? data;

  ChatHistoryResModel({
    this.success,
    this.message,
    this.data,
  });

  factory ChatHistoryResModel.fromJson(Map<String, dynamic> json) =>
      ChatHistoryResModel(
        success: json["success"],
        message: json["message"]?.toString(),
        data: json["data"] == null ? null : ChatData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data?.toJson(),
      };
}

class ChatData {
  String? pairKey;
  bool? isAccepted;
  bool? isBlocked;
  bool? canSend;
  bool? isLocked;
  String? lockReason;
  int? messagesCount;
  List<SocketChatMessage>? messages;

  ChatData({
    this.pairKey,
    this.isAccepted,
    this.isBlocked,
    this.canSend,
    this.isLocked,
    this.lockReason,
    this.messagesCount,
    this.messages,
  });

  factory ChatData.fromJson(Map<String, dynamic> json) => ChatData(
        pairKey: json["pairKey"]?.toString(),
        isAccepted: json["isAccepted"] == true,
        isBlocked: json["isBlocked"] == true,
        canSend: json["canSend"] ?? true,
        isLocked: json["isLocked"] == true,
        lockReason: json["lockReason"]?.toString(),
        messagesCount: json["messagesCount"],
        messages: json["messages"] == null
            ? []
            : List<SocketChatMessage>.from(
                json["messages"]!.map((x) => SocketChatMessage.fromJson(x)),
              ),
      );

  Map<String, dynamic> toJson() => {
        "pairKey": pairKey,
        "isAccepted": isAccepted,
        "isBlocked": isBlocked,
        "canSend": canSend,
        "isLocked": isLocked,
        "lockReason": lockReason,
        "messagesCount": messagesCount,
        "messages": messages == null
            ? []
            : List<dynamic>.from(messages!.map((x) => x.toJson())),
      };
}

class SocketChatMessage {
  String? id;
  String? senderId;
  String? receiverId;
  String? text;
  bool? isRead;
  DateTime? createdAt;

  SocketChatMessage({
    this.id,
    this.senderId,
    this.receiverId,
    this.text,
    this.isRead,
    this.createdAt,
  });

  factory SocketChatMessage.fromJson(Map<String, dynamic> json) =>
      SocketChatMessage(
        id: json["_id"]?.toString() ?? json["id"]?.toString(),
        senderId: json["senderId"]?.toString(),
        receiverId: json["receiverId"]?.toString(),
        text: json["text"]?.toString() ?? '',
        isRead: json["isRead"] == true,
        createdAt: json["createdAt"] == null
            ? DateTime.now()
            : DateTime.tryParse(json["createdAt"].toString()) ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "senderId": senderId,
        "receiverId": receiverId,
        "text": text,
        "isRead": isRead,
        "createdAt": createdAt?.toIso8601String(),
      };
}
