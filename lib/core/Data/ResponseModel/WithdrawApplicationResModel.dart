import 'dart:convert';

WithdrawApplicationResModel withdrawApplicationResModelFromJson(String str) =>
    WithdrawApplicationResModel.fromJson(json.decode(str));

String withdrawApplicationResModelToJson(WithdrawApplicationResModel data) =>
    json.encode(data.toJson());

class WithdrawApplicationResModel {
  final bool? success;
  final String? message;
  final WithdrawApplicationData? data;

  WithdrawApplicationResModel({
    this.success,
    this.message,
    this.data,
  });

  factory WithdrawApplicationResModel.fromJson(Map<String, dynamic> json) =>
      WithdrawApplicationResModel(
        success: json["success"] as bool?,
        message: json["message"] as String?,
        data: json["data"] != null && json["data"] is Map
            ? WithdrawApplicationData.fromJson(
                Map<String, dynamic>.from(json["data"] as Map),
              )
            : null,
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data?.toJson(),
      };
}

class WithdrawApplicationData {
  final int? deletedCount;

  WithdrawApplicationData({
    this.deletedCount,
  });

  factory WithdrawApplicationData.fromJson(Map<String, dynamic> json) {
    int? count;
    if (json["deletedCount"] is int) {
      count = json["deletedCount"] as int;
    } else if (json["deletedCount"] != null) {
      count = int.tryParse(json["deletedCount"].toString());
    }
    return WithdrawApplicationData(deletedCount: count);
  }

  Map<String, dynamic> toJson() => {
        "deletedCount": deletedCount,
      };
}

