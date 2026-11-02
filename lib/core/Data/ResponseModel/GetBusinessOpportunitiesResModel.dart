import 'dart:convert';

GetBusinessOpportunitiesResModel getBusinessOpportunitiesResModelFromJson(
        String str) =>
    GetBusinessOpportunitiesResModel.fromJson(json.decode(str));

String getBusinessOpportunitiesResModelToJson(
        GetBusinessOpportunitiesResModel data) =>
    json.encode(data.toJson());

class GetBusinessOpportunitiesResModel {
  bool? success;
  String? message;
  OpportunitiesData? data;
  OpportunitiesPagination? pagination;

  GetBusinessOpportunitiesResModel({
    this.success,
    this.message,
    this.data,
    this.pagination,
  });

  factory GetBusinessOpportunitiesResModel.fromJson(
          Map<String, dynamic> json) {
    OpportunitiesData? dataObj;
    if (json["data"] != null) {
      if (json["data"] is Map) {
        dataObj =
            OpportunitiesData.fromJson(Map<String, dynamic>.from(json["data"]));
      } else if (json["data"] is List) {
        dataObj = OpportunitiesData(
          businessPosts: List<BusinessOpportunityItem>.from(
            (json["data"] as List).map(
              (x) => BusinessOpportunityItem.fromJson(
                Map<String, dynamic>.from(x),
              ),
            ),
          ),
          jobPosts: [],
        );
      }
    }

    OpportunitiesPagination? paginationObj;
    if (json["pagination"] != null && json["pagination"] is Map) {
      paginationObj = OpportunitiesPagination.fromJson(
        Map<String, dynamic>.from(json["pagination"]),
      );
    }

    return GetBusinessOpportunitiesResModel(
      success: json["success"],
      message: json["message"],
      data: dataObj,
      pagination: paginationObj,
    );
  }

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data?.toJson(),
        "pagination": pagination?.toJson(),
      };

  List<BusinessOpportunityItem> get businessPosts => data?.businessPosts ?? [];
  List<BusinessOpportunityItem> get jobPosts => data?.jobPosts ?? [];
}

class OpportunitiesData {
  List<BusinessOpportunityItem>? businessPosts;
  List<BusinessOpportunityItem>? jobPosts;

  OpportunitiesData({
    this.businessPosts,
    this.jobPosts,
  });

  factory OpportunitiesData.fromJson(Map<String, dynamic> json) =>
      OpportunitiesData(
        businessPosts: json["businessPosts"] == null ||
                json["businessPosts"] is! List
            ? []
            : List<BusinessOpportunityItem>.from(
                (json["businessPosts"] as List).map(
                  (x) => BusinessOpportunityItem.fromJson(
                    Map<String, dynamic>.from(x),
                  ),
                ),
              ),
        jobPosts: json["jobPosts"] == null || json["jobPosts"] is! List
            ? []
            : List<BusinessOpportunityItem>.from(
                (json["jobPosts"] as List).map(
                  (x) => BusinessOpportunityItem.fromJson(
                    Map<String, dynamic>.from(x),
                  ),
                ),
              ),
      );

  Map<String, dynamic> toJson() => {
        "businessPosts": businessPosts == null
            ? []
            : List<dynamic>.from(businessPosts!.map((x) => x.toJson())),
        "jobPosts": jobPosts == null
            ? []
            : List<dynamic>.from(jobPosts!.map((x) => x.toJson())),
      };
}

class BusinessOpportunityItem {
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
  DateTime? createdAt;
  DateTime? updatedAt;
  int? v;

  // Job specific attributes
  String? jobTitle;
  String? employmentType;
  String? hierarchyLevel;
  dynamic annualCtcPackage;
  List<String>? reimbursements;
  List<String>? perksAndBenefits;
  String? jobDescription;
  List<String>? requirements;
  String? applicationContactEmail;
  String? applicationContactPhone;

  BusinessOpportunityItem({
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
    this.createdAt,
    this.updatedAt,
    this.v,
    this.jobTitle,
    this.employmentType,
    this.hierarchyLevel,
    this.annualCtcPackage,
    this.reimbursements,
    this.perksAndBenefits,
    this.jobDescription,
    this.requirements,
    this.applicationContactEmail,
    this.applicationContactPhone,
  });

  factory BusinessOpportunityItem.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic val) {
      if (val == null) return [];
      if (val is List) {
        return val
            .map((e) => e?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return [];
    }

    return BusinessOpportunityItem(
      id: json["_id"]?.toString() ?? json["id"]?.toString(),
      companyId: json["companyId"]?.toString(),
      ownerId: json["ownerId"],
      currentOwnerId: json["currentOwnerId"]?.toString(),
      previousOwnerId: json["previousOwnerId"],
      companyType: json["companyType"]?.toString(),
      opportunityType: json["opportunityType"]?.toString(),
      opportunityHeadline: json["opportunityHeadline"]?.toString(),
      address: json["address"]?.toString(),
      pincode: json["pincode"]?.toString(),
      city: json["city"]?.toString(),
      state: json["state"]?.toString(),
      requiredInvest: json["requiredInvest"],
      area: json["area"]?.toString(),
      expectedReturn: json["expectedReturn"],
      opportunityDescription: json["opportunityDescription"]?.toString(),
      contactPersonName: json["contactPersonName"]?.toString(),
      mobileNumber: json["mobileNumber"]?.toString(),
      businessEmail: json["businessEmail"]?.toString(),
      status: json["status"]?.toString(),
      closingComment: json["closingComment"]?.toString(),
      createdAt: json["createdAt"] == null
          ? null
          : DateTime.tryParse(json["createdAt"].toString()),
      updatedAt: json["updatedAt"] == null
          ? null
          : DateTime.tryParse(json["updatedAt"].toString()),
      v: json["__v"] is int
          ? json["__v"]
          : int.tryParse(json["__v"]?.toString() ?? ''),
      jobTitle: json["jobTitle"]?.toString(),
      employmentType: json["employmentType"]?.toString(),
      hierarchyLevel: json["hierarchyLevel"]?.toString(),
      annualCtcPackage: json["annualCtcPackage"],
      reimbursements: parseStringList(json["reimbursements"]),
      perksAndBenefits: parseStringList(json["perksAndBenefits"]),
      jobDescription: json["jobDescription"]?.toString(),
      requirements: parseStringList(json["requirements"]),
      applicationContactEmail: json["applicationContactEmail"]?.toString(),
      applicationContactPhone: json["applicationContactPhone"]?.toString(),
    );
  }

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
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
        "__v": v,
        "jobTitle": jobTitle,
        "employmentType": employmentType,
        "hierarchyLevel": hierarchyLevel,
        "annualCtcPackage": annualCtcPackage,
        "reimbursements": reimbursements,
        "perksAndBenefits": perksAndBenefits,
        "jobDescription": jobDescription,
        "requirements": requirements,
        "applicationContactEmail": applicationContactEmail,
        "applicationContactPhone": applicationContactPhone,
      };

  bool get isJob => (jobTitle != null && jobTitle!.trim().isNotEmpty);

  String get ownerName {
    if (ownerId is Map && (ownerId as Map)["name"] != null) {
      return (ownerId as Map)["name"].toString();
    }
    if (ownerId is String && (ownerId as String).isNotEmpty) {
      return ownerId as String;
    }
    return '';
  }
}

class OpportunitiesPagination {
  Pagination? businessPosts;
  Pagination? jobPosts;

  OpportunitiesPagination({
    this.businessPosts,
    this.jobPosts,
  });

  factory OpportunitiesPagination.fromJson(Map<String, dynamic> json) {
    Pagination? bPosts;
    Pagination? jPosts;

    if (json["businessPosts"] != null && json["businessPosts"] is Map) {
      bPosts =
          Pagination.fromJson(Map<String, dynamic>.from(json["businessPosts"]));
    }
    if (json["jobPosts"] != null && json["jobPosts"] is Map) {
      jPosts =
          Pagination.fromJson(Map<String, dynamic>.from(json["jobPosts"]));
    }

    if (bPosts == null && json.containsKey("page")) {
      bPosts = Pagination.fromJson(json);
    }

    return OpportunitiesPagination(
      businessPosts: bPosts,
      jobPosts: jPosts,
    );
  }

  Map<String, dynamic> toJson() => {
        "businessPosts": businessPosts?.toJson(),
        "jobPosts": jobPosts?.toJson(),
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
        page: json["page"] is int
            ? json["page"]
            : int.tryParse(json["page"]?.toString() ?? ''),
        limit: json["limit"] is int
            ? json["limit"]
            : int.tryParse(json["limit"]?.toString() ?? ''),
        total: json["total"] is int
            ? json["total"]
            : int.tryParse(json["total"]?.toString() ?? ''),
        totalPages: json["totalPages"] is int
            ? json["totalPages"]
            : int.tryParse(json["totalPages"]?.toString() ?? ''),
      );

  Map<String, dynamic> toJson() => {
        "page": page,
        "limit": limit,
        "total": total,
        "totalPages": totalPages,
      };
}
