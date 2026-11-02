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
    bool? purposeLimitation;
    bool? locationTrackingBlindness;
    bool? applicantErasureMandate;
    bool? noEmploymentRelationship;

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
        this.purposeLimitation,
        this.locationTrackingBlindness,
        this.applicantErasureMandate,
        this.noEmploymentRelationship,
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
        purposeLimitation: json["purpose_limitation"],
        locationTrackingBlindness: json["location_tracking_blindness"],
        applicantErasureMandate: json["applicant_erasure_mandate"],
        noEmploymentRelationship: json["no_employment_relationship"],
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
        "purpose_limitation": purposeLimitation ?? true,
        "location_tracking_blindness": locationTrackingBlindness ?? true,
        "applicant_erasure_mandate": applicantErasureMandate ?? true,
        "no_employment_relationship": noEmploymentRelationship ?? true,
    };
}
