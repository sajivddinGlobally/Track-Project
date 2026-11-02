class UpdateUserLocationBodyModel {
  final LocationPoint location;

  UpdateUserLocationBodyModel({required this.location});

  factory UpdateUserLocationBodyModel.fromJson(Map<String, dynamic> json) =>
      UpdateUserLocationBodyModel(
        location: LocationPoint.fromJson(json["location"] ?? {}),
      );

  Map<String, dynamic> toJson() => {
        "location": location.toJson(),
      };
}

class LocationPoint {
  final String type;
  final List<double> coordinates; // [longitude, latitude]

  LocationPoint({
    this.type = "Point",
    required this.coordinates,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) => LocationPoint(
        type: json["type"] ?? "Point",
        coordinates: json["coordinates"] == null
            ? [0.0, 0.0]
            : List<double>.from(
                json["coordinates"].map((x) => (x as num).toDouble()),
              ),
      );

  Map<String, dynamic> toJson() => {
        "type": type,
        "coordinates": coordinates,
      };
}

