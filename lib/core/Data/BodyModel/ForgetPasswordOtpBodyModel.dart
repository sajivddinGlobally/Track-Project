// To parse this JSON data, do
//
//     final forgetPasswordOtpBodyModel = forgetPasswordOtpBodyModelFromJson(jsonString);

import 'dart:convert';

ForgetPasswordOtpBodyModel forgetPasswordOtpBodyModelFromJson(String str) => ForgetPasswordOtpBodyModel.fromJson(json.decode(str));

String forgetPasswordOtpBodyModelToJson(ForgetPasswordOtpBodyModel data) => json.encode(data.toJson());

class ForgetPasswordOtpBodyModel {
    String? email;
    String? otp;

    ForgetPasswordOtpBodyModel({
        this.email,
        this.otp,
    });

    factory ForgetPasswordOtpBodyModel.fromJson(Map<String, dynamic> json) => ForgetPasswordOtpBodyModel(
        email: json["email"],
        otp: json["otp"],
    );

    Map<String, dynamic> toJson() => {
        "email": email,
        "otp": otp,
    };
}
