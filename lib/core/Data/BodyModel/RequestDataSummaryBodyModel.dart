class RequestDataSummaryBodyModel {
  final String email;

  RequestDataSummaryBodyModel({required this.email});

  factory RequestDataSummaryBodyModel.fromJson(Map<String, dynamic> json) =>
      RequestDataSummaryBodyModel(
        email: json["email"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "email": email,
      };
}
