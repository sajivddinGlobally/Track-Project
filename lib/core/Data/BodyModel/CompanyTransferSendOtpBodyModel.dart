import 'dart:convert';

CompanyTransferSendOtpBodyModel companyTransferSendOtpBodyModelFromJson(
  String str,
) => CompanyTransferSendOtpBodyModel.fromJson(json.decode(str));

String companyTransferSendOtpBodyModelToJson(
  CompanyTransferSendOtpBodyModel data,
) => json.encode(data.toJson());

class CompanyTransferSendOtpBodyModel {
  String? companyId;
  String? senderPhone;

  CompanyTransferSendOtpBodyModel({
    this.companyId,
    this.senderPhone,
  });

  factory CompanyTransferSendOtpBodyModel.fromJson(
    Map<String, dynamic> json,
  ) => CompanyTransferSendOtpBodyModel(
    companyId: json["companyId"]?.toString(),
    senderPhone: json["senderPhone"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    if (companyId != null) "companyId": companyId,
    if (senderPhone != null) "senderPhone": senderPhone,
  };
}

