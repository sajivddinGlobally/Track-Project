class FriendLocationSharingStatusResModel {
  final bool? success;
  final String? message;
  final FriendLocationSharingAccessData? data;

  FriendLocationSharingStatusResModel({
    this.success,
    this.message,
    this.data,
  });

  factory FriendLocationSharingStatusResModel.fromJson(
    Map<String, dynamic> json,
  ) =>
      FriendLocationSharingStatusResModel(
        success: json["success"] as bool?,
        message: json["message"]?.toString(),
        data: json["data"] == null
            ? null
            : FriendLocationSharingAccessData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        if (message != null) "message": message,
        "data": data?.toJson(),
      };
}

class FriendLocationSharingAccessData {
  final bool? access;

  FriendLocationSharingAccessData({this.access});

  factory FriendLocationSharingAccessData.fromJson(
    Map<String, dynamic> json,
  ) =>
      FriendLocationSharingAccessData(
        access: json["access"] as bool?,
      );

  Map<String, dynamic> toJson() => {
        "access": access,
      };
}

