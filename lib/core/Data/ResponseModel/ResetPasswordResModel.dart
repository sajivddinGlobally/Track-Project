// To parse this JSON data, do
//
//     final resetPasswordResModel = resetPasswordResModelFromJson(jsonString);

import 'dart:convert';

ResetPasswordResModel resetPasswordResModelFromJson(String str) => ResetPasswordResModel.fromJson(json.decode(str));

String resetPasswordResModelToJson(ResetPasswordResModel data) => json.encode(data.toJson());

class ResetPasswordResModel {
    bool? success;
    String? message;

    ResetPasswordResModel({
        this.success,
        this.message,
    });

    factory ResetPasswordResModel.fromJson(Map<String, dynamic> json) => ResetPasswordResModel(
        success: json["success"],
        message: json["message"],
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
    };
}
