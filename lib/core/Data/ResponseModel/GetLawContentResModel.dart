import 'dart:convert';

GetLawContentResModel getLawContentResModelFromJson(String str) =>
    GetLawContentResModel.fromJson(json.decode(str));

String getLawContentResModelToJson(GetLawContentResModel data) =>
    json.encode(data.toJson());

class GetLawContentResModel {
  bool? success;
  int? count;
  List<LawContentItem>? data;

  GetLawContentResModel({
    this.success,
    this.count,
    this.data,
  });

  factory GetLawContentResModel.fromJson(Map<String, dynamic> json) =>
      GetLawContentResModel(
        success: json["success"],
        count: json["count"] is int
            ? json["count"]
            : int.tryParse(json["count"]?.toString() ?? ''),
        data: json["data"] == null
            ? []
            : List<LawContentItem>.from(
                json["data"]!.map((x) => LawContentItem.fromJson(x)),
              ),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "count": count,
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

class LawContentItem {
  String? id;
  String? title;
  String? type;
  String? url;
  String? section;
  String? lawModule;
  String? category;
  String? state;
  String? description;
  DateTime? createdAt;
  DateTime? updatedAt;

  LawContentItem({
    this.id,
    this.title,
    this.type,
    this.url,
    this.section,
    this.lawModule,
    this.category,
    this.state,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory LawContentItem.fromJson(Map<String, dynamic> json) => LawContentItem(
        id: json["_id"] ?? json["id"],
        title: json["title"],
        type: json["type"],
        url: json["url"],
        section: json["section"],
        lawModule: json["lawModule"],
        category: json["category"],
        state: json["state"],
        description: json["description"],
        createdAt: json["createdAt"] == null
            ? null
            : DateTime.tryParse(json["createdAt"].toString()),
        updatedAt: json["updatedAt"] == null
            ? null
            : DateTime.tryParse(json["updatedAt"].toString()),
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "title": title,
        "type": type,
        "url": url,
        "section": section,
        "lawModule": lawModule,
        "category": category,
        "state": state,
        "description": description,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
      };
}
