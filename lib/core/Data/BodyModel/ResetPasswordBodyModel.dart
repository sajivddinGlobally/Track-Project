// To parse this JSON data, do
//
//     final resetPasswordBodyModel = resetPasswordBodyModelFromJson(jsonString);

import 'dart:convert';

ResetPasswordBodyModel resetPasswordBodyModelFromJson(String str) => ResetPasswordBodyModel.fromJson(json.decode(str));

String resetPasswordBodyModelToJson(ResetPasswordBodyModel data) => json.encode(data.toJson());

class ResetPasswordBodyModel {
    String? newPassword;
    String? confirmPassword;

    ResetPasswordBodyModel({
        this.newPassword,
        this.confirmPassword,
    });

    factory ResetPasswordBodyModel.fromJson(Map<String, dynamic> json) => ResetPasswordBodyModel(
        newPassword: json["newPassword"],
        confirmPassword: json["confirmPassword"],
    );

    Map<String, dynamic> toJson() => {
        "newPassword": newPassword,
        "confirmPassword": confirmPassword,
    };
}
