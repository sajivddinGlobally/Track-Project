import 'dart:convert';

GoogleSignInBodyModel googleSignInBodyModelFromJson(String str) =>
    GoogleSignInBodyModel.fromJson(json.decode(str));

String googleSignInBodyModelToJson(GoogleSignInBodyModel data) =>
    json.encode(data.toJson());

class GoogleSignInBodyModel {
  String? idToken;

  GoogleSignInBodyModel({this.idToken});

  factory GoogleSignInBodyModel.fromJson(Map<String, dynamic> json) =>
      GoogleSignInBodyModel(
        idToken: json["idToken"],
      );

  Map<String, dynamic> toJson() => {
    "idToken": idToken,
  };
}

