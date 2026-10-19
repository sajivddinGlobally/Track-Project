// To parse this JSON data, do
//
//     final otpVerifyBodyModel = otpVerifyBodyModelFromJson(jsonString);

import 'dart:convert';

OtpVerifyBodyModel otpVerifyBodyModelFromJson(String str) => OtpVerifyBodyModel.fromJson(json.decode(str));

String otpVerifyBodyModelToJson(OtpVerifyBodyModel data) => json.encode(data.toJson());

class OtpVerifyBodyModel {
    String? email;
    String? otp;

    OtpVerifyBodyModel({
        this.email,
        this.otp,
    });

    factory OtpVerifyBodyModel.fromJson(Map<String, dynamic> json) => OtpVerifyBodyModel(
        email: json["email"],
        otp: json["otp"],
    );

    Map<String, dynamic> toJson() => {
        "email": email,
        "otp": otp,
    };
}
