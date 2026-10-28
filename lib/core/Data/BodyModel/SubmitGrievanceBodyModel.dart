class SubmitGrievanceBodyModel {
  final String? category;
  final String? description;
  final bool? isVerified;

  SubmitGrievanceBodyModel({
    this.category,
    this.description,
    this.isVerified,
  });

  factory SubmitGrievanceBodyModel.fromJson(Map<String, dynamic> json) =>
      SubmitGrievanceBodyModel(
        category: json["category"],
        description: json["description"],
        isVerified: json["is_verified"],
      );

  Map<String, dynamic> toJson() => {
        if (category != null) "category": category,
        if (description != null) "description": description,
        if (isVerified != null) "is_verified": isVerified,
      };
}
