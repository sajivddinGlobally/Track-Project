import 'dart:convert';

BusinessProfileBodyModel businessProfileBodyModelFromJson(String str) =>
    BusinessProfileBodyModel.fromJson(json.decode(str));

String businessProfileBodyModelToJson(BusinessProfileBodyModel data) =>
    json.encode(data.toJson());

class BusinessProfileBodyModel {
  String? registeredCompanyName;
  String? companyType;
  String? gstNumber;
  String? companyPanNumber;
  String? registeredCorporateAddress;
  String? officialWebsite;

  BusinessProfileBodyModel({
    this.registeredCompanyName,
    this.companyType,
    this.gstNumber,
    this.companyPanNumber,
    this.registeredCorporateAddress,
    this.officialWebsite,
  });

  factory BusinessProfileBodyModel.fromJson(Map<String, dynamic> json) =>
      BusinessProfileBodyModel(
        registeredCompanyName: json["registeredCompanyName"],
        companyType: json["companyType"],
        gstNumber: json["gstNumber"],
        companyPanNumber: json["companyPanNumber"],
        registeredCorporateAddress: json["registeredCorporateAddress"],
        officialWebsite: json["officialWebsite"],
      );

  Map<String, dynamic> toJson() => {
        if (registeredCompanyName != null)
          "registeredCompanyName": registeredCompanyName,
        if (companyType != null) "companyType": companyType,
        if (gstNumber != null) "gstNumber": gstNumber,
        if (companyPanNumber != null) "companyPanNumber": companyPanNumber,
        if (registeredCorporateAddress != null)
          "registeredCorporateAddress": registeredCorporateAddress,
        if (officialWebsite != null && officialWebsite!.isNotEmpty)
          "officialWebsite": officialWebsite,
      };
}
