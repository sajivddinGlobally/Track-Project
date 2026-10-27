import 'dart:convert';

GetMyCompanyJobPostsResModel getMyCompanyJobPostsResModelFromJson(String str) =>
    GetMyCompanyJobPostsResModel.fromJson(json.decode(str));

String getMyCompanyJobPostsResModelToJson(GetMyCompanyJobPostsResModel data) =>
    json.encode(data.toJson());

class GetMyCompanyJobPostsResModel {
  bool? success;
  String? message;
  Counts? counts;
  List<MyCompanyJobPostItem>? data;
  Pagination? pagination;

  GetMyCompanyJobPostsResModel({
    this.success,
    this.message,
    this.counts,
    this.data,
    this.pagination,
  });

  factory GetMyCompanyJobPostsResModel.fromJson(Map<String, dynamic> json) =>
      GetMyCompanyJobPostsResModel(
        success: json["success"],
        message: json["message"],
        counts: json["counts"] == null ? null : Counts.fromJson(json["counts"]),
        data: json["data"] == null
            ? []
            : List<MyCompanyJobPostItem>.from(
                json["data"]!.map((x) => MyCompanyJobPostItem.fromJson(x)),
              ),
        pagination: json["pagination"] == null
            ? null
            : Pagination.fromJson(json["pagination"]),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "counts": counts?.toJson(),
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
        "pagination": pagination?.toJson(),
      };
}

class Counts {
  int? totalPosts;
  int? totalApplicants;

  Counts({
    this.totalPosts,
    this.totalApplicants,
  });

  factory Counts.fromJson(Map<String, dynamic> json) => Counts(
        totalPosts: json["totalPosts"],
        totalApplicants: json["totalApplicants"],
      );

  Map<String, dynamic> toJson() => {
        "totalPosts": totalPosts,
        "totalApplicants": totalApplicants,
      };
}

class MyCompanyJobPostItem {
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
  List<String>? reimbursements;
  List<String>? perksAndBenefits;
  String? jobDescription;
  List<String>? requirements;
  String? applicationContactEmail;
  String? status;
  String? closingComment;
  int? applicationCount;
  List<JobApplicantItem>? applicants;
  DateTime? createdAt;
  DateTime? updatedAt;

  MyCompanyJobPostItem({
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
    this.applicationCount,
    this.applicants,
    this.createdAt,
    this.updatedAt,
  });

  factory MyCompanyJobPostItem.fromJson(Map<String, dynamic> json) =>
      MyCompanyJobPostItem(
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
            : List<String>.from(json["reimbursements"].map((x) => x.toString())),
        perksAndBenefits: json["perksAndBenefits"] == null
            ? []
            : List<String>.from(json["perksAndBenefits"].map((x) => x.toString())),
        jobDescription: json["jobDescription"],
        requirements: json["requirements"] == null
            ? []
            : List<String>.from(json["requirements"].map((x) => x.toString())),
        applicationContactEmail: json["applicationContactEmail"],
        status: json["status"],
        closingComment: json["closingComment"],
        applicationCount: json["applicationCount"] is int
            ? json["applicationCount"]
            : (json["applicationCount"] as num?)?.toInt() ??
                (json["applicants"] as List?)?.length ??
                0,
        applicants: json["applicants"] == null
            ? []
            : List<JobApplicantItem>.from(
                json["applicants"]!.map((x) => JobApplicantItem.fromJson(x)),
              ),
        createdAt: json["createdAt"] == null
            ? null
            : DateTime.tryParse(json["createdAt"].toString()),
        updatedAt: json["updatedAt"] == null
            ? null
            : DateTime.tryParse(json["updatedAt"].toString()),
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
        "applicationCount": applicationCount,
        "applicants": applicants == null
            ? []
            : List<dynamic>.from(applicants!.map((x) => x.toJson())),
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
      };
}

class JobApplicantItem {
  String? id;
  String? userId;
  String? name;
  String? email;
  String? phone;
  String? resumeUrl;
  String? comment;
  DateTime? appliedAt;

  JobApplicantItem({
    this.id,
    this.userId,
    this.name,
    this.email,
    this.phone,
    this.resumeUrl,
    this.comment,
    this.appliedAt,
  });

  factory JobApplicantItem.fromJson(Map<String, dynamic> json) =>
      JobApplicantItem(
        id: json["_id"] ?? json["id"],
        userId: json["userId"],
        name: json["name"],
        email: json["email"],
        phone: json["phone"],
        resumeUrl: json["resumeUrl"],
        comment: json["comment"],
        appliedAt: json["appliedAt"] == null
            ? null
            : DateTime.tryParse(json["appliedAt"].toString()),
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "userId": userId,
        "name": name,
        "email": email,
        "phone": phone,
        "resumeUrl": resumeUrl,
        "comment": comment,
        "appliedAt": appliedAt?.toIso8601String(),
      };
}

class Pagination {
  int? page;
  int? limit;
  int? total;
  int? totalPages;

  Pagination({
    this.page,
    this.limit,
    this.total,
    this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
        page: json["page"],
        limit: json["limit"],
        total: json["total"],
        totalPages: json["totalPages"],
      );

  Map<String, dynamic> toJson() => {
        "page": page,
        "limit": limit,
        "total": total,
        "totalPages": totalPages,
      };
}
