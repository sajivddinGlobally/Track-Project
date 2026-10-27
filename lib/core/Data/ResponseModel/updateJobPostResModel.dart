// To parse this JSON data, do
//
//     final updateJobPostingResModel = updateJobPostingResModelFromJson(jsonString);

import 'dart:convert';

UpdateJobPostingResModel updateJobPostingResModelFromJson(String str) => UpdateJobPostingResModel.fromJson(json.decode(str));

String updateJobPostingResModelToJson(UpdateJobPostingResModel data) => json.encode(data.toJson());

class UpdateJobPostingResModel {
    bool? success;
    String? message;
    Data? data;

    UpdateJobPostingResModel({
        this.success,
        this.message,
        this.data,
    });

    factory UpdateJobPostingResModel.fromJson(Map<String, dynamic> json) => UpdateJobPostingResModel(
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
    int? salary;

    Data({
        this.id,
        this.salary,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: json["_id"],
        salary: json["salary"],
    );

    Map<String, dynamic> toJson() => {
        "_id": id,
        "salary": salary,
    };
}
