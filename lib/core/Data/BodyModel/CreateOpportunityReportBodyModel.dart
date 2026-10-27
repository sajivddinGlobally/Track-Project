import 'dart:convert';

CreateOpportunityReportBodyModel createOpportunityReportBodyModelFromJson(
        String str) =>
    CreateOpportunityReportBodyModel.fromJson(json.decode(str));

String createOpportunityReportBodyModelToJson(
        CreateOpportunityReportBodyModel data) =>
    json.encode(data.toJson());

class CreateOpportunityReportBodyModel {
  String? postID;
  String? reasonCategory;
  String? additionalDetails;
  String? evidenceAttachmentUrl;
  String? timestamp;

  CreateOpportunityReportBodyModel({
    this.postID,
    this.reasonCategory,
    this.additionalDetails,
    this.evidenceAttachmentUrl,
    this.timestamp,
  });

  factory CreateOpportunityReportBodyModel.fromJson(
          Map<String, dynamic> json) =>
      CreateOpportunityReportBodyModel(
        postID: json["postID"],
        reasonCategory: json["reasonCategory"],
        additionalDetails: json["additionalDetails"],
        evidenceAttachmentUrl: json["evidenceAttachmentUrl"],
        timestamp: json["timestamp"],
      );

  Map<String, dynamic> toJson() => {
        if (postID != null) "postID": postID,
        if (reasonCategory != null) "reasonCategory": reasonCategory,
        if (additionalDetails != null && additionalDetails!.isNotEmpty)
          "additionalDetails": additionalDetails,
        if (evidenceAttachmentUrl != null && evidenceAttachmentUrl!.isNotEmpty)
          "evidenceAttachmentUrl": evidenceAttachmentUrl,
        if (timestamp != null) "timestamp": timestamp,
      };
}
