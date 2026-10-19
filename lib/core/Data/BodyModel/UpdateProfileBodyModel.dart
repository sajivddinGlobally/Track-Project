import 'dart:convert';

UpdateProfileBodyModel updateProfileBodyModelFromJson(String str) =>
    UpdateProfileBodyModel.fromJson(json.decode(str));

String updateProfileBodyModelToJson(UpdateProfileBodyModel data) =>
    json.encode(data.toJson());

class UpdateProfileBodyModel {
  String? name;
  String? email;
  String? phone;
  String? password;
  bool? isVerified;
  String? profileImage;
  String? bio;
  String? profession;
  String? education;
  String? city;
  String? state;
  String? country;
  String? pincode;
  String? school;
  String? college;
  String? villageTown;
  String? campusLocation;
  String? graduationYear;
  String? currentAddress;
  String? permanentAddress;

  UpdateProfileBodyModel({
    this.name,
    this.email,
    this.phone,
    this.password,
    this.isVerified,
    this.profileImage,
    this.bio,
    this.profession,
    this.education,
    this.city,
    this.state,
    this.country,
    this.pincode,
    this.school,
    this.college,
    this.villageTown,
    this.campusLocation,
    this.graduationYear,
    this.currentAddress,
    this.permanentAddress,
  });

  factory UpdateProfileBodyModel.fromJson(Map<String, dynamic> json) =>
      UpdateProfileBodyModel(
        name: json["name"],
        email: json["email"],
        phone: json["phone"],
        password: json["password"],
        isVerified: json["isVerified"],
        profileImage: json["profileImage"],
        bio: json["bio"],
        profession: json["profession"],
        education: json["education"],
        city: json["city"],
        state: json["state"],
        country: json["country"],
        pincode: json["pincode"],
        school: json["school"],
        college: json["college"],
        villageTown: json["villageTown"],
        campusLocation: json["campusLocation"],
        graduationYear: json["graduationYear"],
        currentAddress: json["currentAddress"],
        permanentAddress: json["permanentAddress"],
      );

  Map<String, dynamic> toJson() => {
        if (name != null) "name": name,
        if (email != null) "email": email,
        if (phone != null) "phone": phone,
        if (password != null) "password": password,
        if (isVerified != null) "isVerified": isVerified,
        if (profileImage != null) "profileImage": profileImage,
        if (bio != null) "bio": bio,
        if (profession != null) "profession": profession,
        if (education != null) "education": education,
        if (city != null) "city": city,
        if (state != null) "state": state,
        if (country != null) "country": country,
        if (pincode != null) "pincode": pincode,
        if (school != null) "school": school,
        if (college != null) "college": college,
        if (villageTown != null) "villageTown": villageTown,
        if (campusLocation != null) "campusLocation": campusLocation,
        if (graduationYear != null) "graduationYear": graduationYear,
        if (currentAddress != null) "currentAddress": currentAddress,
        if (permanentAddress != null) "permanentAddress": permanentAddress,
      };
}
