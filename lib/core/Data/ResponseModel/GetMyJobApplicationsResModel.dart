import 'dart:convert';

GetMyJobApplicationsResModel getMyJobApplicationsResModelFromJson(String str) =>
    GetMyJobApplicationsResModel.fromJson(json.decode(str));

String getMyJobApplicationsResModelToJson(GetMyJobApplicationsResModel data) =>
    json.encode(data.toJson());

class GetMyJobApplicationsResModel {
  final bool? success;
  final String? message;
  final MyJobApplicationsData? data;

  GetMyJobApplicationsResModel({
    this.success,
    this.message,
    this.data,
  });

  factory GetMyJobApplicationsResModel.fromJson(Map<String, dynamic> json) {
    MyJobApplicationsData? dataObj;
    final rawData = json['data'];

    if (rawData is Map<String, dynamic>) {
      dataObj = MyJobApplicationsData.fromJson(rawData);
    } else if (rawData is Map) {
      dataObj = MyJobApplicationsData.fromJson(
        Map<String, dynamic>.from(rawData),
      );
    } else if (rawData is List) {
      final list = <MyApplicationEntry>[];
      for (final item in rawData) {
        if (item is Map) {
          list.add(MyApplicationEntry.fromJson(
            Map<String, dynamic>.from(item),
            isJob: true,
          ));
        }
      }
      dataObj = MyJobApplicationsData(
        jobProfile: JobProfileDetails(
          counts: JobProfileCounts(
            totalApplications: list.length,
            jobApplicationCount: list.length,
            businessApplicationCount: 0,
          ),
          jobApplications: list,
          businessApplications: [],
        ),
      );
    }

    return GetMyJobApplicationsResModel(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: dataObj,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data?.toJson(),
      };

  List<MyApplicationEntry> get jobApplications =>
      data?.jobProfile?.jobApplications ?? [];

  List<MyApplicationEntry> get businessApplications =>
      data?.jobProfile?.businessApplications ?? [];

  List<MyApplicationEntry> get allApplications =>
      [...jobApplications, ...businessApplications];

  JobProfileCounts? get counts =>
      data?.jobProfile?.counts ??
      JobProfileCounts(
        totalApplications: allApplications.length,
        jobApplicationCount: jobApplications.length,
        businessApplicationCount: businessApplications.length,
      );

  JobProfileDetails? get profile => data?.jobProfile;
}

class MyJobApplicationsData {
  final String? userId;
  final JobProfileDetails? jobProfile;

  MyJobApplicationsData({
    this.userId,
    this.jobProfile,
  });

  factory MyJobApplicationsData.fromJson(Map<String, dynamic> json) {
    return MyJobApplicationsData(
      userId: json['userId']?.toString(),
      jobProfile: json['jobProfile'] != null && json['jobProfile'] is Map
          ? JobProfileDetails.fromJson(
              Map<String, dynamic>.from(json['jobProfile'] as Map),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'jobProfile': jobProfile?.toJson(),
      };
}

class JobProfileDetails {
  final String? name;
  final String? email;
  final String? phone;
  final String? resumeUrl;
  final JobProfileCounts? counts;
  final List<MyApplicationEntry> jobApplications;
  final List<MyApplicationEntry> businessApplications;

  JobProfileDetails({
    this.name,
    this.email,
    this.phone,
    this.resumeUrl,
    this.counts,
    this.jobApplications = const [],
    this.businessApplications = const [],
  });

  factory JobProfileDetails.fromJson(Map<String, dynamic> json) {
    final rawJobApps = json['jobApplications'];
    final List<MyApplicationEntry> jApps = [];
    if (rawJobApps is List) {
      for (final item in rawJobApps) {
        if (item is Map) {
          jApps.add(MyApplicationEntry.fromJson(
            Map<String, dynamic>.from(item),
            isJob: true,
          ));
        }
      }
    }

    final rawBizApps = json['businessApplications'];
    final List<MyApplicationEntry> bApps = [];
    if (rawBizApps is List) {
      for (final item in rawBizApps) {
        if (item is Map) {
          bApps.add(MyApplicationEntry.fromJson(
            Map<String, dynamic>.from(item),
            isJob: false,
          ));
        }
      }
    }

    JobProfileCounts? countsObj;
    if (json['counts'] != null && json['counts'] is Map) {
      countsObj = JobProfileCounts.fromJson(
        Map<String, dynamic>.from(json['counts'] as Map),
      );
    } else {
      countsObj = JobProfileCounts(
        totalApplications: jApps.length + bApps.length,
        jobApplicationCount: jApps.length,
        businessApplicationCount: bApps.length,
      );
    }

    return JobProfileDetails(
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      resumeUrl: json['resumeUrl']?.toString(),
      counts: countsObj,
      jobApplications: jApps,
      businessApplications: bApps,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'resumeUrl': resumeUrl,
        'counts': counts?.toJson(),
        'jobApplications': jobApplications.map((e) => e.toJson()).toList(),
        'businessApplications':
            businessApplications.map((e) => e.toJson()).toList(),
      };
}

class JobProfileCounts {
  final int totalApplications;
  final int jobApplicationCount;
  final int businessApplicationCount;

  JobProfileCounts({
    this.totalApplications = 0,
    this.jobApplicationCount = 0,
    this.businessApplicationCount = 0,
  });

  factory JobProfileCounts.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val is int) return val;
      if (val != null) return int.tryParse(val.toString()) ?? 0;
      return 0;
    }

    return JobProfileCounts(
      totalApplications: parseInt(json['totalApplications']),
      jobApplicationCount: parseInt(json['jobApplicationCount']),
      businessApplicationCount: parseInt(json['businessApplicationCount']),
    );
  }

  Map<String, dynamic> toJson() => {
        'totalApplications': totalApplications,
        'jobApplicationCount': jobApplicationCount,
        'businessApplicationCount': businessApplicationCount,
      };
}

class MyApplicationEntry {
  final String? applicationId;
  final ApplicantProfile? applicantProfile;
  final String? comment;
  final String? appliedAt;
  final String? updatedAt;
  final ApplicationPostDetail? post;
  final bool isJob;

  MyApplicationEntry({
    this.applicationId,
    this.applicantProfile,
    this.comment,
    this.appliedAt,
    this.updatedAt,
    this.post,
    this.isJob = true,
  });

  factory MyApplicationEntry.fromJson(
    Map<String, dynamic> json, {
    bool isJob = true,
  }) {
    ApplicationPostDetail? postObj;
    if (json['post'] != null && json['post'] is Map) {
      postObj = ApplicationPostDetail.fromJson(
        Map<String, dynamic>.from(json['post'] as Map),
      );
    }

    return MyApplicationEntry(
      applicationId: json['applicationId']?.toString() ??
          json['_id']?.toString() ??
          json['id']?.toString(),
      applicantProfile: json['applicantProfile'] != null &&
              json['applicantProfile'] is Map
          ? ApplicantProfile.fromJson(
              Map<String, dynamic>.from(json['applicantProfile'] as Map),
            )
          : null,
      comment: json['comment']?.toString(),
      appliedAt: json['appliedAt']?.toString() ?? json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      post: postObj,
      isJob: isJob,
    );
  }

  Map<String, dynamic> toJson() => {
        'applicationId': applicationId,
        'applicantProfile': applicantProfile?.toJson(),
        'comment': comment,
        'appliedAt': appliedAt,
        'updatedAt': updatedAt,
        'post': post?.toJson(),
        'isJob': isJob,
      };
}

class ApplicantProfile {
  final String? name;
  final String? email;
  final String? phone;
  final String? resumeUrl;

  ApplicantProfile({
    this.name,
    this.email,
    this.phone,
    this.resumeUrl,
  });

  factory ApplicantProfile.fromJson(Map<String, dynamic> json) {
    return ApplicantProfile(
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      resumeUrl: json['resumeUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'resumeUrl': resumeUrl,
      };
}

class ApplicationPostDetail {
  final String? id;
  final String? jobTitle;
  final String? employmentType;
  final String? hierarchyLevel;
  final String? opportunityHeadline;
  final String? opportunityType;
  final String? city;
  final String? state;
  final String? pincode;
  final dynamic annualCtcPackage;
  final dynamic requiredInvest;
  final String? status;
  final dynamic ownerId;

  ApplicationPostDetail({
    this.id,
    this.jobTitle,
    this.employmentType,
    this.hierarchyLevel,
    this.opportunityHeadline,
    this.opportunityType,
    this.city,
    this.state,
    this.pincode,
    this.annualCtcPackage,
    this.requiredInvest,
    this.status,
    this.ownerId,
  });

  factory ApplicationPostDetail.fromJson(Map<String, dynamic> json) {
    return ApplicationPostDetail(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      jobTitle: json['jobTitle']?.toString(),
      employmentType: json['employmentType']?.toString(),
      hierarchyLevel: json['hierarchyLevel']?.toString(),
      opportunityHeadline: json['opportunityHeadline']?.toString(),
      opportunityType: json['opportunityType']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      pincode: json['pincode']?.toString(),
      annualCtcPackage: json['annualCtcPackage'],
      requiredInvest: json['requiredInvest'],
      status: json['status']?.toString(),
      ownerId: json['ownerId'],
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'jobTitle': jobTitle,
        'employmentType': employmentType,
        'hierarchyLevel': hierarchyLevel,
        'opportunityHeadline': opportunityHeadline,
        'opportunityType': opportunityType,
        'city': city,
        'state': state,
        'pincode': pincode,
        'annualCtcPackage': annualCtcPackage,
        'requiredInvest': requiredInvest,
        'status': status,
        'ownerId': ownerId,
      };

  String get ownerName {
    if (ownerId is Map && (ownerId as Map)['name'] != null) {
      return (ownerId as Map)['name'].toString();
    }
    if (ownerId is String && (ownerId as String).isNotEmpty) {
      return ownerId as String;
    }
    return '';
  }

  bool get isJob => (jobTitle != null && jobTitle!.trim().isNotEmpty);
}

// Backward compatibility type aliases
typedef JobApplicationItemData = MyApplicationEntry;
typedef JobPostDetail = ApplicationPostDetail;
