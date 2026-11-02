import 'dart:convert';

MatchContactsBodyModel matchContactsBodyModelFromJson(String str) =>
    MatchContactsBodyModel.fromJson(json.decode(str));

String matchContactsBodyModelToJson(MatchContactsBodyModel data) =>
    json.encode(data.toJson());

class MatchContactsBodyModel {
  List<ContactItem>? contacts;
  bool? consentGrantedAffirmatively;
  String? syncMechanism;
  String? hashingProtocol;

  MatchContactsBodyModel({
    this.contacts,
    this.consentGrantedAffirmatively,
    this.syncMechanism,
    this.hashingProtocol,
  });

  factory MatchContactsBodyModel.fromJson(Map<String, dynamic> json) =>
      MatchContactsBodyModel(
        contacts: json["contacts"] == null
            ? []
            : List<ContactItem>.from(
                json["contacts"]!.map((x) => ContactItem.fromJson(x)),
              ),
        consentGrantedAffirmatively:
            json["consent_granted_affirmatively"] ?? json["consentGrantedAffirmatively"],
        syncMechanism: json["sync_mechanism"] ?? json["syncMechanism"],
        hashingProtocol: json["hashing_protocol"] ?? json["hashingProtocol"],
      );

  Map<String, dynamic> toJson() => {
        "contacts": contacts == null
            ? []
            : List<dynamic>.from(contacts!.map((x) => x.toJson())),
        if (consentGrantedAffirmatively != null)
          "consent_granted_affirmatively": consentGrantedAffirmatively,
        if (syncMechanism != null) "sync_mechanism": syncMechanism,
        if (hashingProtocol != null) "hashing_protocol": hashingProtocol,
      };
}

class ContactItem {
  String? name;
  String? phone;
  String? phoneHash;

  ContactItem({this.name, this.phone, this.phoneHash});

  factory ContactItem.fromJson(Map<String, dynamic> json) => ContactItem(
        name: json["name"],
        phone: json["phone"],
        phoneHash: json["phoneHash"] ?? json["phone_hash"],
      );

  Map<String, dynamic> toJson() => {
        if (name != null) "name": name,
        if (phone != null) "phone": phone,
        if (phoneHash != null) "phoneHash": phoneHash,
        if (phoneHash != null) "phone_hash": phoneHash,
      };
}
