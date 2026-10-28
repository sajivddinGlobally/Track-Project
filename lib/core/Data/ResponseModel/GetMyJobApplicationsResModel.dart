class GetMyJobApplicationsResModel {
  final bool? success;
  final String? message;
  final List<JobApplicationItemData> data;

  GetMyJobApplicationsResModel({
    this.success,
    this.message,
    this.data = const [],
  });

  factory GetMyJobApplicationsResModel.fromJson(Map<String, dynamic> json) {
    List<JobApplicationItemData> items = [];
    final rawData = json['data'];

    if (rawData is List) {
      items = rawData
          .whereType<Map<String, dynamic>>()
          .map((e) => JobApplicationItemData.fromJson(e))
          .toList();
    } else if (rawData is Map<String, dynamic>) {
      if (rawData.containsKey('applications') && rawData['applications'] is List) {
        items = (rawData['applications'] as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => JobApplicationItemData.fromJson(e))
            .toList();
      } else if (rawData.containsKey('application') || rawData.containsKey('post')) {
        items = [JobApplicationItemData.fromJson(rawData)];
      }
    }

    return GetMyJobApplicationsResModel(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.map((e) => e.toJson()).toList(),
    };
  }
}

class JobApplicationItemData {
  final ApplicationDetail? application;
  final String? postType;
  final JobPostDetail? post;
  final bool? resumeUploaded;

  JobApplicationItemData({
    this.application,
    this.postType,
    this.post,
    this.resumeUploaded,
  });

  factory JobApplicationItemData.fromJson(Map<String, dynamic> json) {
    return JobApplicationItemData(
      application: json['application'] != null &&
              json['application'] is Map<String, dynamic>
          ? ApplicationDetail.fromJson(
              json['application'] as Map<String, dynamic>)
          : null,
      postType: json['postType'] as String?,
      post: json['post'] != null && json['post'] is Map<String, dynamic>
          ? JobPostDetail.fromJson(json['post'] as Map<String, dynamic>)
          : null,
      resumeUploaded: json['resumeUploaded'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'application': application?.toJson(),
      'postType': postType,
      'post': post?.toJson(),
      'resumeUploaded': resumeUploaded,
    };
  }
}

class ApplicationDetail {
  final String? id;
  final String? userId;
  final String? jobPostId;
  final String? name;
  final String? email;
  final String? phone;
  final String? resumeUrl;
  final String? comment;
  final String? createdAt;
  final String? updatedAt;

  ApplicationDetail({
    this.id,
    this.userId,
    this.jobPostId,
    this.name,
    this.email,
    this.phone,
    this.resumeUrl,
    this.comment,
    this.createdAt,
    this.updatedAt,
  });

  factory ApplicationDetail.fromJson(Map<String, dynamic> json) {
    return ApplicationDetail(
      id: json['_id'] as String?,
      userId: json['userId'] is String
          ? json['userId'] as String
          : (json['userId'] is Map ? json['userId']['_id'] as String? : null),
      jobPostId: json['jobPostId'] is String
          ? json['jobPostId'] as String
          : (json['jobPostId'] is Map
              ? json['jobPostId']['_id'] as String?
              : null),
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      resumeUrl: json['resumeUrl'] as String?,
      comment: json['comment'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'jobPostId': jobPostId,
      'name': name,
      'email': email,
      'phone': phone,
      'resumeUrl': resumeUrl,
      'comment': comment,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class JobPostDetail {
  final String? id;
  final String? jobTitle;
  final String? employmentType;
  final String? hierarchyLevel;
  final String? city;
  final String? state;
  final String? pincode;
  final num? annualCtcPackage;
  final String? status;
  final JobPostOwner? ownerId;

  JobPostDetail({
    this.id,
    this.jobTitle,
    this.employmentType,
    this.hierarchyLevel,
    this.city,
    this.state,
    this.pincode,
    this.annualCtcPackage,
    this.status,
    this.ownerId,
  });

  factory JobPostDetail.fromJson(Map<String, dynamic> json) {
    return JobPostDetail(
      id: json['_id'] as String?,
      jobTitle: json['jobTitle'] as String?,
      employmentType: json['employmentType'] as String?,
      hierarchyLevel: json['hierarchyLevel'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      annualCtcPackage: json['annualCtcPackage'] as num?,
      status: json['status'] as String?,
      ownerId:
          json['ownerId'] != null && json['ownerId'] is Map<String, dynamic>
              ? JobPostOwner.fromJson(json['ownerId'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'jobTitle': jobTitle,
      'employmentType': employmentType,
      'hierarchyLevel': hierarchyLevel,
      'city': city,
      'state': state,
      'pincode': pincode,
      'annualCtcPackage': annualCtcPackage,
      'status': status,
      'ownerId': ownerId?.toJson(),
    };
  }
}

class JobPostOwner {
  final String? id;
  final String? name;

  JobPostOwner({
    this.id,
    this.name,
  });

  factory JobPostOwner.fromJson(Map<String, dynamic> json) {
    return JobPostOwner(
      id: json['_id'] as String?,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
    };
  }
}
