// To parse this JSON data, do
//
//     final locationSharingBodyModel = locationSharingBodyModelFromJson(jsonString);

import 'dart:convert';

LocationSharingBodyModel locationSharingBodyModelFromJson(String str) => LocationSharingBodyModel.fromJson(json.decode(str));

String locationSharingBodyModelToJson(LocationSharingBodyModel data) => json.encode(data.toJson());

class LocationSharingBodyModel {
    bool? enabled;

    LocationSharingBodyModel({
        this.enabled,
    });

    factory LocationSharingBodyModel.fromJson(Map<String, dynamic> json) => LocationSharingBodyModel(
        enabled: json["enabled"],
    );

    Map<String, dynamic> toJson() => {
        "enabled": enabled,
    };
}
