import 'dart:convert';

UpdateJobPostingBodyModel updateJobPostingBodyModelFromJson(String str) =>
    UpdateJobPostingBodyModel.fromJson(json.decode(str));

String updateJobPostingBodyModelToJson(UpdateJobPostingBodyModel data) =>
    json.encode(data.toJson());

class UpdateJobPostingBodyModel {
  String? id;
  String? companyId;
  num? annualCtcPackage;
  int? salary;
  String? status;
  String? jobTitle;
  String? jobDescription;
  String? applicationContactEmail;

  UpdateJobPostingBodyModel({
    this.id,
    this.companyId,
    this.annualCtcPackage,
    this.salary,
    this.status,
    this.jobTitle,
    this.jobDescription,
    this.applicationContactEmail,
  });

  factory UpdateJobPostingBodyModel.fromJson(Map<String, dynamic> json) =>
      UpdateJobPostingBodyModel(
        id: json["id"] ?? json["_id"],
        companyId: json["companyId"],
        annualCtcPackage: json["annualCtcPackage"] != null
            ? num.tryParse(json["annualCtcPackage"].toString())
            : null,
        salary: json["salary"] != null
            ? int.tryParse(json["salary"].toString())
            : null,
        status: json["status"],
        jobTitle: json["jobTitle"],
        jobDescription: json["jobDescription"],
        applicationContactEmail: json["applicationContactEmail"],
      );

  Map<String, dynamic> toJson() => {
        if (id != null) "id": id,
        if (companyId != null) "companyId": companyId,
        if (annualCtcPackage != null) "annualCtcPackage": annualCtcPackage,
        if (salary != null && annualCtcPackage == null) "salary": salary,
        if (status != null) "status": status,
        if (jobTitle != null) "jobTitle": jobTitle,
        if (jobDescription != null) "jobDescription": jobDescription,
        if (applicationContactEmail != null)
          "applicationContactEmail": applicationContactEmail,
      };
}
