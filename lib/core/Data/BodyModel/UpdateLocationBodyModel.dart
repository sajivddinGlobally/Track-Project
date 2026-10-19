class UpdateLocationBodyModel {
    double? latitude;
    double? longitude;

    UpdateLocationBodyModel({
        this.latitude,
        this.longitude,
    });

    factory UpdateLocationBodyModel.fromJson(Map<String, dynamic> json) => UpdateLocationBodyModel(
        latitude: (json["latitude"] as num?)?.toDouble(),
        longitude: (json["longitude"] as num?)?.toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "latitude": latitude,
        "longitude": longitude,
    };
}
