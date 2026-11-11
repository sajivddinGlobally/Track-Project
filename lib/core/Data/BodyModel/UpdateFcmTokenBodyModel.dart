class UpdateFcmTokenBodyModel {
  final String? fcmToken;

  UpdateFcmTokenBodyModel({this.fcmToken});

  factory UpdateFcmTokenBodyModel.fromJson(Map<String, dynamic> json) =>
      UpdateFcmTokenBodyModel(
        fcmToken: json["fcmToken"]?.toString(),
      );

  Map<String, dynamic> toJson() => {
        "fcmToken": fcmToken,
      };
}

