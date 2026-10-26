// To parse this JSON data, do
//
//     final getBussinessProfileModel = getBussinessProfileModelFromJson(jsonString);

import 'dart:convert';

GetBussinessProfileModel getBussinessProfileModelFromJson(String str) =>
    GetBussinessProfileModel.fromJson(json.decode(str));

String getBussinessProfileModelToJson(GetBussinessProfileModel data) =>
    json.encode(data.toJson());

class GetBussinessProfileModel {
  bool? success;
  String? message;
  List<Datum>? data;
  int? count;
  List<dynamic>? ownershipTransferHistory;
  String? status;
  String? rejectionReason;
  String? adminMessage;

  GetBussinessProfileModel({
    this.success,
    this.message,
    this.data,
    this.count,
    this.ownershipTransferHistory,
    this.status,
    this.rejectionReason,
    this.adminMessage,
  });

  factory GetBussinessProfileModel.fromJson(Map<String, dynamic> json) =>
      GetBussinessProfileModel(
        success: json["success"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))),
        count: json["count"],
        ownershipTransferHistory: json["ownershipTransferHistory"] == null
            ? []
            : List<dynamic>.from(
                json["ownershipTransferHistory"]!.map((x) => x),
              ),
        status: json["status"],
        rejectionReason: json["rejectionReason"],
        adminMessage: json["adminMessage"],
      );

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "data": data == null
        ? []
        : List<dynamic>.from(data!.map((x) => x.toJson())),
    "count": count,
    "ownershipTransferHistory": ownershipTransferHistory == null
        ? []
        : List<dynamic>.from(ownershipTransferHistory!.map((x) => x)),
    "status": status,
    "rejectionReason": rejectionReason,
    "adminMessage": adminMessage,
  };
}

class Datum {
  String? id;
  String? ownerId;
  String? currentOwnerId;
  dynamic previousOwnerId;
  int? v;
  String? companyPanNumber;
  String? companyType;
  String? companyEmail;
  String? companyPhoneNumber;
  bool? companyEmailVerified;
  DateTime? createdAt;
  String? gstNumber;
  String? officialWebsite;
  String? registeredCompanyName;
  String? registeredCorporateAddress;
  String? city;
  String? state;
  String? pincode;
  String? status;
  DateTime? updatedAt;
  String? adminMessage;
  String? rejectionReason;
  String? companyId;
  OwnerContact? ownerContact;

  Datum({
    this.id,
    this.ownerId,
    this.currentOwnerId,
    this.previousOwnerId,
    this.v,
    this.companyPanNumber,
    this.companyType,
    this.companyEmail,
    this.companyPhoneNumber,
    this.companyEmailVerified,
    this.createdAt,
    this.gstNumber,
    this.officialWebsite,
    this.registeredCompanyName,
    this.registeredCorporateAddress,
    this.city,
    this.state,
    this.pincode,
    this.status,
    this.updatedAt,
    this.adminMessage,
    this.rejectionReason,
    this.companyId,
    this.ownerContact,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    id: json["_id"],
    ownerId: json["ownerId"],
    currentOwnerId: json["currentOwnerId"],
    previousOwnerId: json["previousOwnerId"],
    v: json["__v"],
    companyPanNumber: json["companyPanNumber"],
    companyType: json["companyType"],
    companyEmail: json["companyEmail"],
    companyPhoneNumber: json["companyPhoneNumber"],
    companyEmailVerified: json["companyEmailVerified"],
    createdAt: json["createdAt"] == null
        ? null
        : DateTime.parse(json["createdAt"]),
    gstNumber: json["gstNumber"],
    officialWebsite: json["officialWebsite"],
    registeredCompanyName: json["registeredCompanyName"],
    registeredCorporateAddress: json["registeredCorporateAddress"],
    city: json["city"],
    state: json["state"],
    pincode: json["pincode"],
    status: json["status"],
    updatedAt: json["updatedAt"] == null
        ? null
        : DateTime.parse(json["updatedAt"]),
    adminMessage: json["adminMessage"],
    rejectionReason: json["rejectionReason"],
    companyId: json["companyId"],
    ownerContact: json["ownerContact"] == null
        ? null
        : OwnerContact.fromJson(json["ownerContact"]),
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "ownerId": ownerId,
    "currentOwnerId": currentOwnerId,
    "previousOwnerId": previousOwnerId,
    "__v": v,
    "companyPanNumber": companyPanNumber,
    "companyType": companyType,
    "companyEmail": companyEmail,
    "companyPhoneNumber": companyPhoneNumber,
    "companyEmailVerified": companyEmailVerified,
    "createdAt": createdAt?.toIso8601String(),
    "gstNumber": gstNumber,
    "officialWebsite": officialWebsite,
    "registeredCompanyName": registeredCompanyName,
    "registeredCorporateAddress": registeredCorporateAddress,
    "city": city,
    "state": state,
    "pincode": pincode,
    "status": status,
    "updatedAt": updatedAt?.toIso8601String(),
    "adminMessage": adminMessage,
    "rejectionReason": rejectionReason,
    "companyId": companyId,
    "ownerContact": ownerContact?.toJson(),
  };
}

class OwnerContact {
  String? name;
  String? email;
  String? phone;

  OwnerContact({this.name, this.email, this.phone});

  factory OwnerContact.fromJson(Map<String, dynamic> json) => OwnerContact(
    name: json["name"],
    email: json["email"],
    phone: json["phone"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "email": email,
    "phone": phone,
  };
}
