class UpdateConsentsBodyModel {
  final bool? realTimeLocation;
  final bool? jobMarketplace;
  final bool? analytics;

  UpdateConsentsBodyModel({
    this.realTimeLocation,
    this.jobMarketplace,
    this.analytics,
  });

  factory UpdateConsentsBodyModel.fromJson(Map<String, dynamic> json) =>
      UpdateConsentsBodyModel(
        realTimeLocation: json["realTimeLocation"],
        jobMarketplace: json["jobMarketplace"],
        analytics: json["analytics"],
      );

  Map<String, dynamic> toJson() => {
        if (realTimeLocation != null) "realTimeLocation": realTimeLocation,
        if (jobMarketplace != null) "jobMarketplace": jobMarketplace,
        if (analytics != null) "analytics": analytics,
      };
}
