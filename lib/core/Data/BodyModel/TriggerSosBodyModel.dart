import 'dart:convert';

TriggerSosBodyModel triggerSosBodyModelFromJson(String str) =>
    TriggerSosBodyModel.fromJson(json.decode(str));

String triggerSosBodyModelToJson(TriggerSosBodyModel data) =>
    json.encode(data.toJson());

class TriggerSosBodyModel {
  double? latitude;
  double? longitude;
  String? triggerType;
  num? batteryPercentage;

  TriggerSosBodyModel({
    this.latitude,
    this.longitude,
    this.triggerType = "APP_BUTTON",
    this.batteryPercentage = 70,
  });

  factory TriggerSosBodyModel.fromJson(Map<String, dynamic> json) =>
      TriggerSosBodyModel(
        latitude: (json["latitude"] as num?)?.toDouble(),
        longitude: (json["longitude"] as num?)?.toDouble(),
        triggerType: json["triggerType"]?.toString() ?? "APP_BUTTON",
        batteryPercentage: json["batteryPercentage"] as num?,
      );

  Map<String, dynamic> toJson() => {
    if (latitude != null) "latitude": latitude,
    if (longitude != null) "longitude": longitude,
    if (triggerType != null) "triggerType": triggerType,
    if (batteryPercentage != null) "batteryPercentage": batteryPercentage,
  };
}
