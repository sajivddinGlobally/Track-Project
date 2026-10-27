// To parse this JSON data, do
//
//     final businessProfileBodyModel = businessProfileBodyModelFromJson(jsonString);

import 'dart:convert';

BusinessProfileBodyModel businessProfileBodyModelFromJson(String str) => BusinessProfileBodyModel.fromJson(json.decode(str));

String businessProfileBodyModelToJson(BusinessProfileBodyModel data) => json.encode(data.toJson());

class BusinessProfileBodyModel {
    String? registeredCompanyName;
    String? companyType;
    String? gstNumber;
    String? companyPanNumber;
    String? registeredCorporateAddress;
    String? officialWebsite;
    String? companyEmail;
    String? companyPhoneNumber;
    String? city;
    String? state;
    String? pincode;
    Map<String, dynamic>? complianceLedger;

    BusinessProfileBodyModel({
        this.registeredCompanyName,
        this.companyType,
        this.gstNumber,
        this.companyPanNumber,
        this.registeredCorporateAddress,
        this.officialWebsite,
        this.companyEmail,
        this.companyPhoneNumber,
        this.city,
        this.state,
        this.pincode,
        this.complianceLedger,
    });

    factory BusinessProfileBodyModel.fromJson(Map<String, dynamic> json) => BusinessProfileBodyModel(
        registeredCompanyName: json["registeredCompanyName"],
        companyType: json["companyType"],
        gstNumber: json["gstNumber"],
        companyPanNumber: json["companyPanNumber"],
        registeredCorporateAddress: json["registeredCorporateAddress"],
        officialWebsite: json["officialWebsite"],
        companyEmail: json["companyEmail"],
        companyPhoneNumber: json["companyPhoneNumber"],
        city: json["city"],
        state: json["state"],
        pincode: json["pincode"],
        complianceLedger: json["compliance_ledger"] != null
            ? Map<String, dynamic>.from(json["compliance_ledger"])
            : null,
    );

    Map<String, dynamic> toJson() => {
        "registeredCompanyName": registeredCompanyName,
        "companyType": companyType,
        "gstNumber": gstNumber,
        "companyPanNumber": companyPanNumber,
        "registeredCorporateAddress": registeredCorporateAddress,
        "officialWebsite": officialWebsite,
        "companyEmail": companyEmail,
        "companyPhoneNumber": companyPhoneNumber,
        "city": city,
        "state": state,
        "pincode": pincode,
        if (complianceLedger != null) "compliance_ledger": complianceLedger,
    };
}
