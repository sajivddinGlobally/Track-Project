// To parse this JSON data, do
//
//     final forgetPasswordOtpResModel = forgetPasswordOtpResModelFromJson(jsonString);

import 'dart:convert';

ForgetPasswordOtpResModel forgetPasswordOtpResModelFromJson(String str) => ForgetPasswordOtpResModel.fromJson(json.decode(str));

String forgetPasswordOtpResModelToJson(ForgetPasswordOtpResModel data) => json.encode(data.toJson());

class ForgetPasswordOtpResModel {
    bool? success;
    String? message;

    ForgetPasswordOtpResModel({
        this.success,
        this.message,
    });

    factory ForgetPasswordOtpResModel.fromJson(Map<String, dynamic> json) => ForgetPasswordOtpResModel(
        success: json["success"],
        message: json["message"],
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
    };
}
