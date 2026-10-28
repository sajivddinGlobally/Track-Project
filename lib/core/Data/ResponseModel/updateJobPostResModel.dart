import 'dart:convert';

UpdateJobPostingResModel updateJobPostingResModelFromJson(String str) =>
    UpdateJobPostingResModel.fromJson(json.decode(str));

String updateJobPostingResModelToJson(UpdateJobPostingResModel data) =>
    json.encode(data.toJson());

class UpdateJobPostingResModel {
  bool? success;
  String? message;
  List<JobPostChange>? changes;
  UpdatedJobPostData? data;

  UpdateJobPostingResModel({
    this.success,
    this.message,
    this.changes,
    this.data,
  });

  factory UpdateJobPostingResModel.fromJson(Map<String, dynamic> json) =>
      UpdateJobPostingResModel(
        success: json["success"] as bool?,
        message: json["message"] as String?,
        changes: json["changes"] == null
            ? null
            : List<JobPostChange>.from(
                (json["changes"] as List).map((x) => JobPostChange.fromJson(x)),
              ),
        data: json["data"] == null
            ? null
            : UpdatedJobPostData.fromJson(
                Map<String, dynamic>.from(json["data"] as Map),
              ),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "changes": changes == null
            ? null
            : List<dynamic>.from(changes!.map((x) => x.toJson())),
        "data": data?.toJson(),
      };
}

class JobPostChange {
  String? field;
  dynamic from;
  dynamic to;

  JobPostChange({this.field, this.from, this.to});

  factory JobPostChange.fromJson(Map<String, dynamic> json) => JobPostChange(
        field: json["field"]?.toString(),
        from: json["from"],
        to: json["to"],
      );

  Map<String, dynamic> toJson() => {
        "field": field,
        "from": from,
        "to": to,
      };
}

class UpdatedJobPostData {
  String? id;
  String? companyId;
  String? jobTitle;
  num? annualCtcPackage;
  String? status;

  UpdatedJobPostData({
    this.id,
    this.companyId,
    this.jobTitle,
    this.annualCtcPackage,
    this.status,
  });

  factory UpdatedJobPostData.fromJson(Map<String, dynamic> json) =>
      UpdatedJobPostData(
        id: json["_id"] ?? json["id"],
        companyId: json["companyId"]?.toString(),
        jobTitle: json["jobTitle"]?.toString(),
        annualCtcPackage: json["annualCtcPackage"] != null
            ? num.tryParse(json["annualCtcPackage"].toString())
            : (json["salary"] != null
                ? num.tryParse(json["salary"].toString())
                : null),
        status: json["status"]?.toString(),
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "companyId": companyId,
        "jobTitle": jobTitle,
        "annualCtcPackage": annualCtcPackage,
        "status": status,
      };
}
