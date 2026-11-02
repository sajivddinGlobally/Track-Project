import 'dart:convert';

SubmitFeedbackBodyModel submitFeedbackBodyModelFromJson(String str) =>
    SubmitFeedbackBodyModel.fromJson(json.decode(str));

String submitFeedbackBodyModelToJson(SubmitFeedbackBodyModel data) =>
    json.encode(data.toJson());

class SubmitFeedbackBodyModel {
  int? star;
  String? staticType;
  String? userComment;

  SubmitFeedbackBodyModel({
    this.star,
    this.staticType = 'bug_report',
    this.userComment,
  });

  factory SubmitFeedbackBodyModel.fromJson(Map<String, dynamic> json) =>
      SubmitFeedbackBodyModel(
        star: json["star"] is int
            ? json["star"] as int
            : int.tryParse(json["star"]?.toString() ?? '5') ?? 5,
        staticType: json["static"]?.toString() ??
            json["staticType"]?.toString() ??
            'bug_report',
        userComment: json["userComment"]?.toString(),
      );

  Map<String, dynamic> toJson() => {
        if (star != null) "star": star,
        "static": staticType ?? "bug_report",
        if (userComment != null) "userComment": userComment,
      };
}

