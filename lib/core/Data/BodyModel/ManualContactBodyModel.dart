import 'dart:convert';

ManualContactBodyModel manualContactBodyModelFromJson(String str) =>
    ManualContactBodyModel.fromJson(json.decode(str));

String manualContactBodyModelToJson(ManualContactBodyModel data) =>
    json.encode(data.toJson());

class ManualContactBodyModel {
  final String? name;
  final String? phone;

  ManualContactBodyModel({
    this.name,
    this.phone,
  });

  factory ManualContactBodyModel.fromJson(Map<String, dynamic> json) =>
      ManualContactBodyModel(
        name: json["name"],
        phone: json["phone"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "phone": phone,
      };
}

