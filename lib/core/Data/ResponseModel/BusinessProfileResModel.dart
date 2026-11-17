// To parse this JSON data, do
//
//     final businessProfileResModel = businessProfileResModelFromJson(jsonString);

import 'dart:convert';

BusinessProfileResModel businessProfileResModelFromJson(String str) => BusinessProfileResModel.fromJson(json.decode(str));

String businessProfileResModelToJson(BusinessProfileResModel data) => json.encode(data.toJson());

class BusinessProfileResModel {
    bool? success;
    bool? isPaymentPending;
    bool? requiresPayment;
    bool? isCompanyPaymentCompleted;
    String? message;
    Data? data;

    BusinessProfileResModel({
        this.success,
        this.isPaymentPending,
        this.requiresPayment,
        this.isCompanyPaymentCompleted,
        this.message,
        this.data,
    });

    factory BusinessProfileResModel.fromJson(Map<String, dynamic> json) {
        String? msg = json["message"];
        if (json["errors"] != null &&
            json["errors"] is List &&
            (json["errors"] as List).isNotEmpty) {
            final first = (json["errors"] as List).first;
            if (first is Map && first["message"] != null) {
                msg = first["message"].toString();
            }
        }

        final bool requiresPay = json["requiresPayment"] == true ||
            json["isPaymentPending"] == true ||
            json["data"]?["requiresPayment"] == true ||
            json["data"]?["isPaymentPending"] == true ||
            (json["isCompanyPaymentCompleted"] == false &&
                (msg?.toLowerCase().contains("payment") == true));

        final bool paymentCompleted = json["isCompanyPaymentCompleted"] == true ||
            json["data"]?["isCompanyPaymentCompleted"] == true;

        return BusinessProfileResModel(
            success: json["success"],
            isPaymentPending: requiresPay,
            requiresPayment: requiresPay,
            isCompanyPaymentCompleted: paymentCompleted,
            message: msg,
            data: json["data"] == null ? null : Data.fromJson(json["data"]),
        );
    }

    Map<String, dynamic> toJson() => {
        "success": success,
        "isPaymentPending": isPaymentPending,
        "requiresPayment": requiresPayment,
        "isCompanyPaymentCompleted": isCompanyPaymentCompleted,
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
