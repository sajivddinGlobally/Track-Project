import 'dart:convert';

CompanyTransferExecuteResModel companyTransferExecuteResModelFromJson(
  String str,
) => CompanyTransferExecuteResModel.fromJson(json.decode(str));

String companyTransferExecuteResModelToJson(
  CompanyTransferExecuteResModel data,
) => json.encode(data.toJson());

class CompanyTransferExecuteResModel {
  bool? success;
  String? message;
  dynamic data;

  CompanyTransferExecuteResModel({
    this.success,
    this.message,
    this.data,
  });

  factory CompanyTransferExecuteResModel.fromJson(
    Map<String, dynamic> json,
  ) => CompanyTransferExecuteResModel(
    success: json["success"] as bool?,
    message: json["message"]?.toString(),
    data: json["data"],
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    if (data != null) "data": data,
  };
}

