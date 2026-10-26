import 'dart:convert';

CreateBusinessOpportunityResModel createBusinessOpportunityResModelFromJson(
        String str) =>
    CreateBusinessOpportunityResModel.fromJson(json.decode(str));

String createBusinessOpportunityResModelToJson(
        CreateBusinessOpportunityResModel data) =>
    json.encode(data.toJson());

class CreateBusinessOpportunityResModel {
  bool? success;
  String? message;
  BusinessOpportunityData? data;

  CreateBusinessOpportunityResModel({
    this.success,
    this.message,
    this.data,
  });

  factory CreateBusinessOpportunityResModel.fromJson(
          Map<String, dynamic> json) =>
      CreateBusinessOpportunityResModel(
        success: json["success"],
        message: json["message"],
        data: json["data"] == null
            ? null
            : BusinessOpportunityData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data?.toJson(),
      };
}

class BusinessOpportunityData {
  String? id;
  String? companyId;
  String? status;

  BusinessOpportunityData({
    this.id,
    this.companyId,
    this.status,
  });

  factory BusinessOpportunityData.fromJson(Map<String, dynamic> json) =>
      BusinessOpportunityData(
        id: json["_id"] ?? json["id"],
        companyId: json["companyId"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "companyId": companyId,
        "status": status,
      };
}
