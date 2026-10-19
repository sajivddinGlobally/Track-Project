// To parse this JSON data, do
//
//     final forgetPasswordBodyModel = forgetPasswordBodyModelFromJson(jsonString);

import 'dart:convert';

ForgetPasswordBodyModel forgetPasswordBodyModelFromJson(String str) => ForgetPasswordBodyModel.fromJson(json.decode(str));

String forgetPasswordBodyModelToJson(ForgetPasswordBodyModel data) => json.encode(data.toJson());

class ForgetPasswordBodyModel {
    String? email;

    ForgetPasswordBodyModel({
        this.email,
    });

    factory ForgetPasswordBodyModel.fromJson(Map<String, dynamic> json) => ForgetPasswordBodyModel(
        email: json["email"],
    );

    Map<String, dynamic> toJson() => {
        "email": email,
    };
}
