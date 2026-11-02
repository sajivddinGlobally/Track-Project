import 'dart:convert';

CompanyTransferSendOtpResModel companyTransferSendOtpResModelFromJson(
  String str,
) => CompanyTransferSendOtpResModel.fromJson(json.decode(str));

String companyTransferSendOtpResModelToJson(
  CompanyTransferSendOtpResModel data,
) => json.encode(data.toJson());

class CompanyTransferSendOtpResModel {
  bool? success;
  String? message;

  CompanyTransferSendOtpResModel({
    this.success,
    this.message,
  });

  factory CompanyTransferSendOtpResModel.fromJson(
    Map<String, dynamic> json,
  ) => CompanyTransferSendOtpResModel(
    success: json["success"] as bool?,
    message: json["message"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
  };
}

