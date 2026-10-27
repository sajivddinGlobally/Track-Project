import 'dart:convert';

GetMyBusinessOpportunitiesResModel getMyBusinessOpportunitiesResModelFromJson(
        String str) =>
    GetMyBusinessOpportunitiesResModel.fromJson(json.decode(str));

String getMyBusinessOpportunitiesResModelToJson(
        GetMyBusinessOpportunitiesResModel data) =>
    json.encode(data.toJson());

class GetMyBusinessOpportunitiesResModel {
  bool? success;
  String? message;
  MyBusinessOpportunitiesCounts? counts;
  List<MyBusinessOpportunityItem>? data;
  MyBusinessOpportunitiesPagination? pagination;

  GetMyBusinessOpportunitiesResModel({
    this.success,
    this.message,
    this.counts,
    this.data,
    this.pagination,
  });

  factory GetMyBusinessOpportunitiesResModel.fromJson(
          Map<String, dynamic> json) =>
      GetMyBusinessOpportunitiesResModel(
        success: json["success"],
        message: json["message"],
        counts: json["counts"] == null
            ? null
            : MyBusinessOpportunitiesCounts.fromJson(json["counts"]),
        data: json["data"] == null
            ? []
            : List<MyBusinessOpportunityItem>.from(
                json["data"]!.map((x) => MyBusinessOpportunityItem.fromJson(x)),
              ),
        pagination: json["pagination"] == null
            ? null
            : MyBusinessOpportunitiesPagination.fromJson(json["pagination"]),
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

class MyBusinessOpportunitiesCounts {
  int? totalPosts;
  int? totalApplicants;

  MyBusinessOpportunitiesCounts({
    this.totalPosts,
    this.totalApplicants,
  });

  factory MyBusinessOpportunitiesCounts.fromJson(Map<String, dynamic> json) =>
      MyBusinessOpportunitiesCounts(
        totalPosts: json["totalPosts"],
        totalApplicants: json["totalApplicants"],
      );

  Map<String, dynamic> toJson() => {
        "totalPosts": totalPosts,
        "totalApplicants": totalApplicants,
      };
}

class MyBusinessOpportunityItem {
  String? id;
  String? companyId;
  dynamic ownerId;
  String? currentOwnerId;
  dynamic previousOwnerId;
  String? companyType;
  String? opportunityType;
  String? opportunityHeadline;
  String? address;
  String? pincode;
  String? city;
  String? state;
  dynamic requiredInvest;
  String? area;
  dynamic expectedReturn;
  String? opportunityDescription;
  String? contactPersonName;
  String? mobileNumber;
  String? businessEmail;
  String? status;
  String? closingComment;
  int? applicationCount;
  List<OpportunityApplicantItem>? applicants;
  DateTime? createdAt;
  DateTime? updatedAt;

  MyBusinessOpportunityItem({
    this.id,
    this.companyId,
    this.ownerId,
    this.currentOwnerId,
    this.previousOwnerId,
    this.companyType,
    this.opportunityType,
    this.opportunityHeadline,
    this.address,
    this.pincode,
    this.city,
    this.state,
    this.requiredInvest,
    this.area,
    this.expectedReturn,
    this.opportunityDescription,
    this.contactPersonName,
    this.mobileNumber,
    this.businessEmail,
    this.status,
    this.closingComment,
    this.applicationCount,
    this.applicants,
    this.createdAt,
    this.updatedAt,
  });

  factory MyBusinessOpportunityItem.fromJson(Map<String, dynamic> json) =>
      MyBusinessOpportunityItem(
        id: json["_id"] ?? json["id"],
        companyId: json["companyId"],
        ownerId: json["ownerId"],
        currentOwnerId: json["currentOwnerId"],
        previousOwnerId: json["previousOwnerId"],
        companyType: json["companyType"],
        opportunityType: json["opportunityType"],
        opportunityHeadline: json["opportunityHeadline"],
        address: json["address"],
        pincode: json["pincode"],
        city: json["city"],
        state: json["state"],
        requiredInvest: json["requiredInvest"],
        area: json["area"],
        expectedReturn: json["expectedReturn"],
        opportunityDescription: json["opportunityDescription"],
        contactPersonName: json["contactPersonName"],
        mobileNumber: json["mobileNumber"],
        businessEmail: json["businessEmail"],
        status: json["status"],
        closingComment: json["closingComment"],
        applicationCount: json["applicationCount"] ??
            (json["applicants"] is List ? (json["applicants"] as List).length : 0),
        applicants: json["applicants"] == null
            ? []
            : List<OpportunityApplicantItem>.from(
                json["applicants"]!
                    .map((x) => OpportunityApplicantItem.fromJson(x)),
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
        "companyType": companyType,
        "opportunityType": opportunityType,
        "opportunityHeadline": opportunityHeadline,
        "address": address,
        "pincode": pincode,
        "city": city,
        "state": state,
        "requiredInvest": requiredInvest,
        "area": area,
        "expectedReturn": expectedReturn,
        "opportunityDescription": opportunityDescription,
        "contactPersonName": contactPersonName,
        "mobileNumber": mobileNumber,
        "businessEmail": businessEmail,
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

class OpportunityApplicantItem {
  String? id;
  String? userId;
  String? name;
  String? email;
  String? phone;
  String? resumeUrl;
  String? comment;
  DateTime? appliedAt;

  OpportunityApplicantItem({
    this.id,
    this.userId,
    this.name,
    this.email,
    this.phone,
    this.resumeUrl,
    this.comment,
    this.appliedAt,
  });

  factory OpportunityApplicantItem.fromJson(Map<String, dynamic> json) =>
      OpportunityApplicantItem(
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

class MyBusinessOpportunitiesPagination {
  int? page;
  int? limit;
  int? total;
  int? totalPages;

  MyBusinessOpportunitiesPagination({
    this.page,
    this.limit,
    this.total,
    this.totalPages,
  });

  factory MyBusinessOpportunitiesPagination.fromJson(
          Map<String, dynamic> json) =>
      MyBusinessOpportunitiesPagination(
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
