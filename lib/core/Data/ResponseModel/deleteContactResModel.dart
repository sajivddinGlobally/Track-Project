// To parse this JSON data, do
//
//     final deleteContactResModel = deleteContactResModelFromJson(jsonString);

import 'dart:convert';

DeleteContactResModel deleteContactResModelFromJson(String str) => DeleteContactResModel.fromJson(json.decode(str));

String deleteContactResModelToJson(DeleteContactResModel data) => json.encode(data.toJson());

class DeleteContactResModel {
    bool? success;
    String? message;
    int? deletedCount;

    DeleteContactResModel({
        this.success,
        this.message,
        this.deletedCount,
    });

    factory DeleteContactResModel.fromJson(Map<String, dynamic> json) => DeleteContactResModel(
        success: json["success"],
        message: json["message"],
        deletedCount: json["deletedCount"],
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "deletedCount": deletedCount,
    };
}
