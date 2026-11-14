class LocationSharingActionBodyModel {
  final bool? locationAccessDisable;
  final bool? locationAccessRenew;

  LocationSharingActionBodyModel({
    this.locationAccessDisable,
    this.locationAccessRenew,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (locationAccessDisable != null) {
      data['locationAccessDisable'] = locationAccessDisable;
    }
    if (locationAccessRenew != null) {
      data['locationAccessRenew'] = locationAccessRenew;
    }
    return data;
  }
}

