// To parse this JSON data, do
//
//     final registerBodyModel = registerBodyModelFromJson(jsonString);

import 'dart:convert';

RegisterBodyModel registerBodyModelFromJson(String str) => RegisterBodyModel.fromJson(json.decode(str));

String registerBodyModelToJson(RegisterBodyModel data) => json.encode(data.toJson());

class RegisterBodyModel {
    String? email;
    String? password;
    String? name;
    String? phone;
    String? role;

    RegisterBodyModel({
        this.email,
        this.password,
        this.name,
        this.phone,
        this.role,
    });

    factory RegisterBodyModel.fromJson(Map<String, dynamic> json) => RegisterBodyModel(
        email: json["email"],
        password: json["password"],
        name: json["name"],
        phone: json["phone"],
        role: json["role"],
    );

    Map<String, dynamic> toJson() => {
        "email": email,
        "password": password,
        "name": name,
        "phone": phone,
        if (role != null) "role": role,
    };
}
