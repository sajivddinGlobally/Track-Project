import 'dart:convert';

SubmitGrievanceResModel submitGrievanceResModelFromJson(String str) =>
    SubmitGrievanceResModel.fromJson(json.decode(str));

String submitGrievanceResModelToJson(SubmitGrievanceResModel data) =>
    json.encode(data.toJson());

class SubmitGrievanceResModel {
  final dynamic status;
  final String? message;
  final String? receiptCode;
  final String? slaDeadline;
  final String? assignedOfficer;

  SubmitGrievanceResModel({
    this.status,
    this.message,
    this.receiptCode,
    this.slaDeadline,
    this.assignedOfficer,
  });

  bool get isSuccess {
    if (status is bool) return status as bool;
    if (status is String) {
      return (status as String).toLowerCase() == 'success';
    }
    return false;
  }

  factory SubmitGrievanceResModel.fromJson(Map<String, dynamic> json) =>
      SubmitGrievanceResModel(
        status: json["status"] ?? json["success"],
        message: json["message"] as String?,
        receiptCode: (json["receipt_code"] ?? json["receiptCode"]) as String?,
        slaDeadline: (json["sla_deadline"] ?? json["slaDeadline"]) as String?,
        assignedOfficer: (json["assigned_officer"] ?? json["assignedOfficer"]) as String?,
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "receipt_code": receiptCode,
        "sla_deadline": slaDeadline,
        "assigned_officer": assignedOfficer,
      };
}
