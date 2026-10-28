import 'dart:convert';

UpdateConsentsResModel updateConsentsResModelFromJson(String str) =>
    UpdateConsentsResModel.fromJson(json.decode(str));

String updateConsentsResModelToJson(UpdateConsentsResModel data) =>
    json.encode(data.toJson());

class UpdateConsentsResModel {
  final bool? success;
  final int? statusCode;
  final String? message;
  final UpdateConsentsData? data;

  UpdateConsentsResModel({
    this.success,
    this.statusCode,
    this.message,
    this.data,
  });

  factory UpdateConsentsResModel.fromJson(Map<String, dynamic> json) =>
      UpdateConsentsResModel(
        success: json["success"],
        statusCode: json["statusCode"],
        message: json["message"],
        data: json["data"] == null
            ? null
            : UpdateConsentsData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "statusCode": statusCode,
        "message": message,
        "data": data?.toJson(),
      };
}

class UpdateConsentsData {
  final UserConsents? consents;

  UpdateConsentsData({this.consents});

  factory UpdateConsentsData.fromJson(Map<String, dynamic> json) =>
      UpdateConsentsData(
        consents: json["consents"] == null
            ? null
            : UserConsents.fromJson(json["consents"]),
      );

  Map<String, dynamic> toJson() => {
        "consents": consents?.toJson(),
      };
}

class UserConsents {
  final bool? realTimeLocation;
  final bool? jobMarketplace;
  final bool? analytics;

  UserConsents({
    this.realTimeLocation,
    this.jobMarketplace,
    this.analytics,
  });

  factory UserConsents.fromJson(Map<String, dynamic> json) => UserConsents(
        realTimeLocation: json["realTimeLocation"],
        jobMarketplace: json["jobMarketplace"],
        analytics: json["analytics"],
      );

  Map<String, dynamic> toJson() => {
        "realTimeLocation": realTimeLocation,
        "jobMarketplace": jobMarketplace,
        "analytics": analytics,
      };
}
