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
  List<BusinessOpportunityItem>? data;
  Pagination? pagination;

  GetBusinessOpportunitiesResModel({
    this.success,
    this.message,
    this.data,
    this.pagination,
  });

  factory GetBusinessOpportunitiesResModel.fromJson(
          Map<String, dynamic> json) =>
      GetBusinessOpportunitiesResModel(
        success: json["success"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<BusinessOpportunityItem>.from(
                json["data"]!.map((x) => BusinessOpportunityItem.fromJson(x))),
        pagination: json["pagination"] == null
            ? null
            : Pagination.fromJson(json["pagination"]),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
        "pagination": pagination?.toJson(),
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
  });

  factory BusinessOpportunityItem.fromJson(Map<String, dynamic> json) =>
      BusinessOpportunityItem(
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
      };

  String get ownerName {
    if (ownerId is Map && (ownerId as Map)["name"] != null) {
      return (ownerId as Map)["name"].toString();
    }
    return '';
  }
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
