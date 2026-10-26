import 'dart:convert';

TriggerSosResModel triggerSosResModelFromJson(String str) =>
    TriggerSosResModel.fromJson(json.decode(str));

String triggerSosResModelToJson(TriggerSosResModel data) =>
    json.encode(data.toJson());

class TriggerSosResModel {
  bool? success;
  String? message;
  SosData? data;

  TriggerSosResModel({
    this.success,
    this.message,
    this.data,
  });

  factory TriggerSosResModel.fromJson(Map<String, dynamic> json) =>
      TriggerSosResModel(
        success: json["success"],
        message: json["message"]?.toString(),
        data: json["data"] == null ? null : SosData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "data": data?.toJson(),
  };
}

class SosData {
  String? sosId;
  SosLocation? location;

  SosData({
    this.sosId,
    this.location,
  });

  factory SosData.fromJson(Map<String, dynamic> json) => SosData(
    sosId: json["sosId"]?.toString(),
    location: json["location"] == null
        ? null
        : SosLocation.fromJson(json["location"]),
  );

  Map<String, dynamic> toJson() => {
    "sosId": sosId,
    "location": location?.toJson(),
  };
}

class SosLocation {
  double? latitude;
  double? longitude;
  String? googleMapsUrl;

  SosLocation({
    this.latitude,
    this.longitude,
    this.googleMapsUrl,
  });

  factory SosLocation.fromJson(Map<String, dynamic> json) => SosLocation(
    latitude: (json["latitude"] as num?)?.toDouble(),
    longitude: (json["longitude"] as num?)?.toDouble(),
    googleMapsUrl: json["googleMapsUrl"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "latitude": latitude,
    "longitude": longitude,
    "googleMapsUrl": googleMapsUrl,
  };
}
