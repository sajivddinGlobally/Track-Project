import 'dart:convert';

CompanyTransferLookupResModel companyTransferLookupResModelFromJson(
  String str,
) => CompanyTransferLookupResModel.fromJson(json.decode(str));

String companyTransferLookupResModelToJson(
  CompanyTransferLookupResModel data,
) => json.encode(data.toJson());

class CompanyTransferLookupResModel {
  bool? success;
  bool? exists;
  String? message;
  LookupReceiverData? data;

  CompanyTransferLookupResModel({
    this.success,
    this.exists,
    this.message,
    this.data,
  });

  factory CompanyTransferLookupResModel.fromJson(
    Map<String, dynamic> json,
  ) => CompanyTransferLookupResModel(
    success: json["success"] as bool?,
    exists: json["exists"] as bool?,
    message: json["message"]?.toString(),
    data: json["data"] == null
        ? null
        : LookupReceiverData.fromJson(json["data"] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "exists": exists,
    "message": message,
    "data": data?.toJson(),
  };
}

class LookupReceiverData {
  String? name;
  String? email;
  String? phone;
  String? userId;

  LookupReceiverData({
    this.name,
    this.email,
    this.phone,
    this.userId,
  });

  factory LookupReceiverData.fromJson(Map<String, dynamic> json) =>
      LookupReceiverData(
        name: json["name"]?.toString(),
        email: json["email"]?.toString(),
        phone: json["phone"]?.toString(),
        userId: json["userId"]?.toString() ?? json["_id"]?.toString(),
      );

  Map<String, dynamic> toJson() => {
    if (name != null) "name": name,
    if (email != null) "email": email,
    if (phone != null) "phone": phone,
    if (userId != null) "userId": userId,
  };
}

