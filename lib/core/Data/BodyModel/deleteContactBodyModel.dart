// To parse this JSON data, do
//
//     final deleteContactBodyModel = deleteContactBodyModelFromJson(jsonString);

import 'dart:convert';

DeleteContactBodyModel deleteContactBodyModelFromJson(String str) => DeleteContactBodyModel.fromJson(json.decode(str));

String deleteContactBodyModelToJson(DeleteContactBodyModel data) => json.encode(data.toJson());

class DeleteContactBodyModel {
    List<String>? phones;

    DeleteContactBodyModel({
        this.phones,
    });

    factory DeleteContactBodyModel.fromJson(Map<String, dynamic> json) => DeleteContactBodyModel(
        phones: json["phones"] == null ? [] : List<String>.from(json["phones"]!.map((x) => x)),
    );

    Map<String, dynamic> toJson() => {
        "phones": phones == null ? [] : List<dynamic>.from(phones!.map((x) => x)),
    };
}
