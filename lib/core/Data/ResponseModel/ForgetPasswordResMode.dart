// To parse this JSON data, do
//
//     final forgetPasswordResModel = forgetPasswordResModelFromJson(jsonString);

import 'dart:convert';

ForgetPasswordResModel forgetPasswordResModelFromJson(String str) => ForgetPasswordResModel.fromJson(json.decode(str));

String forgetPasswordResModelToJson(ForgetPasswordResModel data) => json.encode(data.toJson());

class ForgetPasswordResModel {
    bool? success;
    String? message;

    ForgetPasswordResModel({
        this.success,
        this.message,
    });

    factory ForgetPasswordResModel.fromJson(Map<String, dynamic> json) => ForgetPasswordResModel(
        success: json["success"],
        message: json["message"],
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
    };
}
