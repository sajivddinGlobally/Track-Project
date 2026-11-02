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
  String? ownerId;
  String? companyType;
  String? opportunityType;
  String? opportunityHeadline;
  String? address;
  String? pincode;
  String? city;
  String? state;
  dynamic requiredInvest;
  String? area;
  dynamic expectedReturn;
  String? opportunityDescription;
  String? contactPersonName;
  String? mobileNumber;
  String? businessEmail;
  String? status;
  String? closingComment;

  BusinessOpportunityData({
    this.id,
    this.companyId,
    this.ownerId,
    this.companyType,
    this.opportunityType,
    this.opportunityHeadline,
    this.address,
    this.pincode,
    this.city,
    this.state,
    this.requiredInvest,
    this.area,
    this.expectedReturn,
    this.opportunityDescription,
    this.contactPersonName,
    this.mobileNumber,
    this.businessEmail,
    this.status,
    this.closingComment,
  });

  factory BusinessOpportunityData.fromJson(Map<String, dynamic> json) =>
      BusinessOpportunityData(
        id: json["_id"] ?? json["id"],
        companyId: json["companyId"],
        ownerId: json["ownerId"] is Map
            ? json["ownerId"]["_id"]?.toString()
            : json["ownerId"]?.toString(),
        companyType: json["companyType"],
        opportunityType: json["opportunityType"],
        opportunityHeadline: json["opportunityHeadline"],
        address: json["address"],
        pincode: json["pincode"],
        city: json["city"],
        state: json["state"],
        requiredInvest: json["requiredInvest"],
        area: json["area"],
        expectedReturn: json["expectedReturn"],
        opportunityDescription: json["opportunityDescription"],
        contactPersonName: json["contactPersonName"],
        mobileNumber: json["mobileNumber"],
        businessEmail: json["businessEmail"],
        status: json["status"],
        closingComment: json["closingComment"],
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "companyId": companyId,
        "ownerId": ownerId,
        "companyType": companyType,
        "opportunityType": opportunityType,
        "opportunityHeadline": opportunityHeadline,
        "address": address,
        "pincode": pincode,
        "city": city,
        "state": state,
        "requiredInvest": requiredInvest,
        "area": area,
        "expectedReturn": expectedReturn,
        "opportunityDescription": opportunityDescription,
        "contactPersonName": contactPersonName,
        "mobileNumber": mobileNumber,
        "businessEmail": businessEmail,
        "status": status,
        "closingComment": closingComment,
      };
}
