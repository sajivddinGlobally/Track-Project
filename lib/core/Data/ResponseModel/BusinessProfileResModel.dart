// To parse this JSON data, do
//
//     final businessProfileResModel = businessProfileResModelFromJson(jsonString);

import 'dart:convert';

BusinessProfileResModel businessProfileResModelFromJson(String str) => BusinessProfileResModel.fromJson(json.decode(str));

String businessProfileResModelToJson(BusinessProfileResModel data) => json.encode(data.toJson());

class BusinessProfileResModel {
    bool? success;
    String? message;
    Data? data;

    BusinessProfileResModel({
        this.success,
        this.message,
        this.data,
    });

    factory BusinessProfileResModel.fromJson(Map<String, dynamic> json) => BusinessProfileResModel(
        success: json["success"],
        message: json["message"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data?.toJson(),
    };
}

class Data {
    String? id;
    String? ownerId;
    int? v;
    String? companyPanNumber;
    String? companyType;
    DateTime? createdAt;
    String? gstNumber;
    String? officialWebsite;
    String? registeredCompanyName;
    String? registeredCorporateAddress;
    String? status;
    DateTime? updatedAt;

    Data({
        this.id,
        this.ownerId,
        this.v,
        this.companyPanNumber,
        this.companyType,
        this.createdAt,
        this.gstNumber,
        this.officialWebsite,
        this.registeredCompanyName,
        this.registeredCorporateAddress,
        this.status,
        this.updatedAt,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: json["_id"],
        ownerId: json["ownerId"],
        v: json["__v"],
        companyPanNumber: json["companyPanNumber"],
        companyType: json["companyType"],
        createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
        gstNumber: json["gstNumber"],
        officialWebsite: json["officialWebsite"],
        registeredCompanyName: json["registeredCompanyName"],
        registeredCorporateAddress: json["registeredCorporateAddress"],
        status: json["status"],
        updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
    );

    Map<String, dynamic> toJson() => {
        "_id": id,
        "ownerId": ownerId,
        "__v": v,
        "companyPanNumber": companyPanNumber,
        "companyType": companyType,
        "createdAt": createdAt?.toIso8601String(),
        "gstNumber": gstNumber,
        "officialWebsite": officialWebsite,
        "registeredCompanyName": registeredCompanyName,
        "registeredCorporateAddress": registeredCorporateAddress,
        "status": status,
        "updatedAt": updatedAt?.toIso8601String(),
    };
}
