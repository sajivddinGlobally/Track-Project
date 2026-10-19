import 'dart:convert';

MatchContactsBodyModel matchContactsBodyModelFromJson(String str) =>
    MatchContactsBodyModel.fromJson(json.decode(str));

String matchContactsBodyModelToJson(MatchContactsBodyModel data) =>
    json.encode(data.toJson());

class MatchContactsBodyModel {
  List<ContactItem>? contacts;

  MatchContactsBodyModel({this.contacts});

  factory MatchContactsBodyModel.fromJson(Map<String, dynamic> json) =>
      MatchContactsBodyModel(
        contacts: json["contacts"] == null
            ? []
            : List<ContactItem>.from(
                json["contacts"]!.map((x) => ContactItem.fromJson(x)),
              ),
      );

  Map<String, dynamic> toJson() => {
        "contacts": contacts == null
            ? []
            : List<dynamic>.from(contacts!.map((x) => x.toJson())),
      };
}

class ContactItem {
  String? name;
  String? phone;

  ContactItem({this.name, this.phone});

  factory ContactItem.fromJson(Map<String, dynamic> json) => ContactItem(
        name: json["name"],
        phone: json["phone"],
      );

  Map<String, dynamic> toJson() => {
        if (name != null) "name": name,
        if (phone != null) "phone": phone,
      };
}
