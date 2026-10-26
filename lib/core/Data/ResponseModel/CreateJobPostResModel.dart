import 'dart:convert';

CreateJobPostResModel createJobPostResModelFromJson(String str) =>
    CreateJobPostResModel.fromJson(json.decode(str));

String createJobPostResModelToJson(CreateJobPostResModel data) =>
    json.encode(data.toJson());

class CreateJobPostResModel {
  bool? success;
  String? message;
  JobPostData? data;

  CreateJobPostResModel({
    this.success,
    this.message,
    this.data,
  });

  factory CreateJobPostResModel.fromJson(Map<String, dynamic> json) =>
      CreateJobPostResModel(
        success: json["success"],
        message: json["message"],
        data: json["data"] == null ? null : JobPostData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data?.toJson(),
      };
}

class JobPostData {
  String? id;
  String? companyId;
  String? ownerId;
  String? currentOwnerId;
  dynamic previousOwnerId;
  String? jobTitle;
  String? employmentType;
  String? hierarchyLevel;
  String? city;
  String? state;
  String? pincode;
  num? annualCtcPackage;
  List<dynamic>? reimbursements;
  List<dynamic>? perksAndBenefits;
  String? jobDescription;
  List<String>? requirements;
  String? applicationContactEmail;
  String? status;
  String? closingComment;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? v;

  JobPostData({
    this.id,
    this.companyId,
    this.ownerId,
    this.currentOwnerId,
    this.previousOwnerId,
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
    this.status,
    this.closingComment,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory JobPostData.fromJson(Map<String, dynamic> json) => JobPostData(
        id: json["_id"] ?? json["id"],
        companyId: json["companyId"],
        ownerId: json["ownerId"],
        currentOwnerId: json["currentOwnerId"],
        previousOwnerId: json["previousOwnerId"],
        jobTitle: json["jobTitle"],
        employmentType: json["employmentType"],
        hierarchyLevel: json["hierarchyLevel"],
        city: json["city"],
        state: json["state"],
        pincode: json["pincode"],
        annualCtcPackage: json["annualCtcPackage"],
        reimbursements: json["reimbursements"] == null
            ? []
            : List<dynamic>.from(json["reimbursements"].map((x) => x)),
        perksAndBenefits: json["perksAndBenefits"] == null
            ? []
            : List<dynamic>.from(json["perksAndBenefits"].map((x) => x)),
        jobDescription: json["jobDescription"],
        requirements: json["requirements"] == null
            ? []
            : List<String>.from(json["requirements"].map((x) => x.toString())),
        applicationContactEmail: json["applicationContactEmail"],
        status: json["status"],
        closingComment: json["closingComment"],
        createdAt: json["createdAt"] == null
            ? null
            : DateTime.parse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null
            ? null
            : DateTime.parse(json["updatedAt"]),
        v: json["__v"],
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "companyId": companyId,
        "ownerId": ownerId,
        "currentOwnerId": currentOwnerId,
        "previousOwnerId": previousOwnerId,
        "jobTitle": jobTitle,
        "employmentType": employmentType,
        "hierarchyLevel": hierarchyLevel,
        "city": city,
        "state": state,
        "pincode": pincode,
        "annualCtcPackage": annualCtcPackage,
        "reimbursements": reimbursements,
        "perksAndBenefits": perksAndBenefits,
        "jobDescription": jobDescription,
        "requirements": requirements,
        "applicationContactEmail": applicationContactEmail,
        "status": status,
        "closingComment": closingComment,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
        "__v": v,
      };
}
