import 'dart:convert';

CreateBusinessOpportunityBodyModel createBusinessOpportunityBodyModelFromJson(
        String str) =>
    CreateBusinessOpportunityBodyModel.fromJson(json.decode(str));

String createBusinessOpportunityBodyModelToJson(
        CreateBusinessOpportunityBodyModel data) =>
    json.encode(data.toJson());

class CreateBusinessOpportunityBodyModel {
  String? id;
  String? companyId;
  String? companyType;
  String? opportunityType;
  String? opportunityHeadline;
  String? address;
  String? city;
  String? state;
  String? pincode;
  String? area;
  dynamic requiredInvest;
  String? expectedReturn;
  String? opportunityDescription;
  String? contactPersonName;
  String? mobileNumber;
  String? businessEmail;
  String? status;

  CreateBusinessOpportunityBodyModel({
    this.id,
    this.companyId,
    this.companyType,
    this.opportunityType,
    this.opportunityHeadline,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.area,
    this.requiredInvest,
    this.expectedReturn,
    this.opportunityDescription,
    this.contactPersonName,
    this.mobileNumber,
    this.businessEmail,
    this.status,
  });

  factory CreateBusinessOpportunityBodyModel.fromJson(
          Map<String, dynamic> json) =>
      CreateBusinessOpportunityBodyModel(
        id: json["_id"] ?? json["id"],
        companyId: json["companyId"],
        companyType: json["companyType"],
        opportunityType: json["opportunityType"],
        opportunityHeadline:
            json["opportunityHeadline"] ?? json["jobTitle"],
        address: json["address"],
        city: json["city"],
        state: json["state"],
        pincode: json["pincode"],
        area: json["area"],
        requiredInvest: json["requiredInvest"] ?? json["investment"],
        expectedReturn: json["expectedReturn"] ?? json["returns"],
        opportunityDescription:
            json["opportunityDescription"] ?? json["jobDescription"],
        contactPersonName:
            json["contactPersonName"] ?? json["contactPerson"],
        mobileNumber: json["mobileNumber"] ?? json["contactPhone"],
        businessEmail:
            json["businessEmail"] ?? json["applicationContactEmail"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
        if (id != null && id!.isNotEmpty) "id": id,
        if (companyId != null) "companyId": companyId,
        if (companyType != null) "companyType": companyType,
        if (opportunityType != null) "opportunityType": opportunityType,
        if (opportunityHeadline != null)
          "opportunityHeadline": opportunityHeadline,
        if (address != null) "address": address,
        if (city != null) "city": city,
        if (state != null) "state": state,
        if (pincode != null) "pincode": pincode,
        if (area != null && area!.isNotEmpty) "area": area,
        if (requiredInvest != null)
          "requiredInvest": int.tryParse(requiredInvest.toString()) ?? requiredInvest,
        if (expectedReturn != null) "expectedReturn": expectedReturn,
        if (opportunityDescription != null)
          "opportunityDescription": opportunityDescription,
        if (contactPersonName != null) "contactPersonName": contactPersonName,
        if (mobileNumber != null) "mobileNumber": mobileNumber,
        if (businessEmail != null) "businessEmail": businessEmail,
        if (status != null && status!.isNotEmpty) "status": status,
      };
}
