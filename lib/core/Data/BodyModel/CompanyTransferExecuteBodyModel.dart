import 'dart:convert';

CompanyTransferExecuteBodyModel companyTransferExecuteBodyModelFromJson(
  String str,
) => CompanyTransferExecuteBodyModel.fromJson(json.decode(str));

String companyTransferExecuteBodyModelToJson(
  CompanyTransferExecuteBodyModel data,
) => json.encode(data.toJson());

class CompanyTransferExecuteBodyModel {
  String? companyId;
  String? senderPhone;
  String? senderOtp;
  String? receiverPhone;
  String? receiverName;

  CompanyTransferExecuteBodyModel({
    this.companyId,
    this.senderPhone,
    this.senderOtp,
    this.receiverPhone,
    this.receiverName,
  });

  factory CompanyTransferExecuteBodyModel.fromJson(
    Map<String, dynamic> json,
  ) => CompanyTransferExecuteBodyModel(
    companyId: json["companyId"]?.toString(),
    senderPhone: json["senderPhone"]?.toString(),
    senderOtp: json["senderOtp"]?.toString(),
    receiverPhone: json["receiverPhone"]?.toString(),
    receiverName: json["receiverName"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    if (companyId != null) "companyId": companyId,
    if (senderPhone != null) "senderPhone": senderPhone,
    if (senderOtp != null) "senderOtp": senderOtp,
    if (receiverPhone != null) "receiverPhone": receiverPhone,
    if (receiverName != null) "receiverName": receiverName,
  };
}

