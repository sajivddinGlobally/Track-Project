
// To parse this JSON data, do
//
//     final createOpportunityReportResModel = createOpportunityReportResModelFromJson(jsonString);

import 'dart:convert';

CreateOpportunityReportResModel createOpportunityReportResModelFromJson(String str) => CreateOpportunityReportResModel.fromJson(json.decode(str));

String createOpportunityReportResModelToJson(CreateOpportunityReportResModel data) => json.encode(data.toJson());

class CreateOpportunityReportResModel {
    bool? success;
    String? message;
    Data? data;

    CreateOpportunityReportResModel({
        this.success,
        this.message,
        this.data,
    });

    factory CreateOpportunityReportResModel.fromJson(Map<String, dynamic> json) => CreateOpportunityReportResModel(
        success: json["success"],
        message: json["message"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data?.toJson(),
    };
}

class Data {
    String? id;
    String? recordType;
    String? dataPostId;
    String? postId;
    String? postType;
    String? reasonCategory;
    String? additionalDetails;
    String? evidenceAttachmentUrl;
    DateTime? timestamp;

    Data({
        this.id,
        this.recordType,
        this.dataPostId,
        this.postId,
        this.postType,
        this.reasonCategory,
        this.additionalDetails,
        this.evidenceAttachmentUrl,
        this.timestamp,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: json["_id"],
        recordType: json["recordType"],
        dataPostId: json["postID "],
        postId: json["postID"],
        postType: json["postType"],
        reasonCategory: json["reasonCategory"],
        additionalDetails: json["additionalDetails"],
        evidenceAttachmentUrl: json["evidenceAttachmentUrl"],
        timestamp: json["timestamp"] == null ? null : DateTime.parse(json["timestamp"]),
    );

    Map<String, dynamic> toJson() => {
        "_id": id,
        "recordType": recordType,
        "postID ": dataPostId,
        "postID": postId,
        "postType": postType,
        "reasonCategory": reasonCategory,
        "additionalDetails": additionalDetails,
        "evidenceAttachmentUrl": evidenceAttachmentUrl,
        "timestamp": timestamp?.toIso8601String(),
    };
}
