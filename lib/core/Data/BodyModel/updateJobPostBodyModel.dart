// To parse this JSON data, do
//
//     final updateJobPostingBodyModel = updateJobPostingBodyModelFromJson(jsonString);

import 'dart:convert';

UpdateJobPostingBodyModel updateJobPostingBodyModelFromJson(String str) => UpdateJobPostingBodyModel.fromJson(json.decode(str));

String updateJobPostingBodyModelToJson(UpdateJobPostingBodyModel data) => json.encode(data.toJson());

class UpdateJobPostingBodyModel {
    String? id;
    String? companyId;
    int? salary;
    String? status;
    String? jobTitle;
    String? jobDescription;
    String? applicationContactEmail;

    UpdateJobPostingBodyModel({
        this.id,
        this.companyId,
        this.salary,
        this.status,
        this.jobTitle,
        this.jobDescription,
        this.applicationContactEmail,
    });

    factory UpdateJobPostingBodyModel.fromJson(Map<String, dynamic> json) => UpdateJobPostingBodyModel(
        id: json["id"],
        companyId: json["companyId"],
        salary: json["salary"],
        status: json["status"],
        jobTitle: json["jobTitle"],
        jobDescription: json["jobDescription"],
        applicationContactEmail: json["applicationContactEmail"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "companyId": companyId,
        "salary": salary,
        "status": status,
        "jobTitle": jobTitle,
        "jobDescription": jobDescription,
        "applicationContactEmail": applicationContactEmail,
    };
}
