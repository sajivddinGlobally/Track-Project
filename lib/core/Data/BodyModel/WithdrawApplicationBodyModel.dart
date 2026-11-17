class WithdrawApplicationBodyModel {
  final String? userId;
  final String? postId;

  WithdrawApplicationBodyModel({
    this.userId,
    this.postId,
  });

  factory WithdrawApplicationBodyModel.fromJson(Map<String, dynamic> json) =>
      WithdrawApplicationBodyModel(
        userId: json["userId"]?.toString(),
        postId: json["postId"]?.toString(),
      );

  Map<String, dynamic> toJson() => {
        "userId": userId,
        "postId": postId,
      };
}

