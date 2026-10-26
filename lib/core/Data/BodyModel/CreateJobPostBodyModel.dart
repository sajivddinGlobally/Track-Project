import 'dart:convert';

CreateJobPostBodyModel createJobPostBodyModelFromJson(String str) =>
    CreateJobPostBodyModel.fromJson(json.decode(str));

String createJobPostBodyModelToJson(CreateJobPostBodyModel data) =>
    json.encode(data.toJson());

class CreateJobPostBodyModel {
  String? companyId;
  String? jobTitle;
  String? employmentType;
  String? hierarchyLevel;
  String? city;
  String? state;
  String? pincode;
  num? annualCtcPackage;
  List<String>? reimbursements;
  List<String>? perksAndBenefits;
  String? jobDescription;
  List<String>? requirements;
  String? applicationContactEmail;

  // Optional legacy fields for backward compatibility
  String? companyName;
  String? employerType;
  String? jobLocation;
  num? salary;
  String? applicationEmail;

  CreateJobPostBodyModel({
    this.companyId,
    this.jobTitle,
    this.employmentType,
    this.hierarchyLevel,
    this.city,
    this.state,
    this.pincode,
    this.annualCtcPackage,
    this.reimbursements,
    this.perksAndBenefits,
    this.jobDescription,
    this.requirements,
    this.applicationContactEmail,
    this.companyName,
    this.employerType,
    this.jobLocation,
    this.salary,
    this.applicationEmail,
  });

  factory CreateJobPostBodyModel.fromJson(Map<String, dynamic> json) =>
      CreateJobPostBodyModel(
        companyId: json["companyId"],
        jobTitle: json["jobTitle"],
        employmentType: json["employmentType"] ?? json["employerType"],
        hierarchyLevel: json["hierarchyLevel"],
        city: json["city"] ?? json["jobLocation"],
        state: json["state"],
        pincode: json["pincode"],
        annualCtcPackage: json["annualCtcPackage"] ?? json["salary"],
        reimbursements: json["reimbursements"] == null
            ? []
            : List<String>.from(
                json["reimbursements"].map((x) => x.toString()),
              ),
        perksAndBenefits: json["perksAndBenefits"] == null
            ? []
            : List<String>.from(
                json["perksAndBenefits"].map((x) => x.toString()),
              ),
        jobDescription: json["jobDescription"],
        requirements: json["requirements"] == null
            ? []
            : List<String>.from(
                json["requirements"].map((x) => x.toString()),
              ),
        applicationContactEmail:
            json["applicationContactEmail"] ?? json["applicationEmail"],
        companyName: json["companyName"],
        employerType: json["employerType"],
        jobLocation: json["jobLocation"],
        salary: json["salary"],
        applicationEmail: json["applicationEmail"],
      );

  Map<String, dynamic> toJson() => {
        "companyId": companyId,
        "jobTitle": jobTitle,
        "employmentType": employmentType,
        "hierarchyLevel": hierarchyLevel,
        "city": city,
        if (state != null && state!.isNotEmpty) "state": state,
        "pincode": pincode,
        "annualCtcPackage": annualCtcPackage,
        "reimbursements": reimbursements ?? [],
        "perksAndBenefits": perksAndBenefits ?? [],
        "jobDescription": jobDescription,
        "requirements": requirements ?? [],
        "applicationContactEmail": applicationContactEmail,
        if (companyName != null && companyName!.isNotEmpty)
          "companyName": companyName,
      };
}
