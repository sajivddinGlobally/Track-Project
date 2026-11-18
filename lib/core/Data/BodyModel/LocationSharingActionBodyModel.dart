class LocationSharingActionBodyModel {
  final bool? locationAccessDisable;
  final bool? locationAccessRenew;
  final bool? locationAccessDisableAll;
  final bool? locationAccessRenewAll;
  final dynamic userIds;

  LocationSharingActionBodyModel({
    this.locationAccessDisable,
    this.locationAccessRenew,
    this.locationAccessDisableAll,
    this.locationAccessRenewAll,
    this.userIds,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (locationAccessDisable != null) {
      data['locationAccessDisable'] = locationAccessDisable;
    }
    if (locationAccessRenew != null) {
      data['locationAccessRenew'] = locationAccessRenew;
    }
    if (locationAccessDisableAll != null) {
      data['locationAccessDisableAll'] = locationAccessDisableAll;
    }
    if (locationAccessRenewAll != null) {
      data['locationAccessRenewAll'] = locationAccessRenewAll;
    }
    if (userIds != null) {
      data['userIds'] = userIds;
    }
    return data;
  }
}

