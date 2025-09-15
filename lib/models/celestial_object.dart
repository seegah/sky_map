import 'package:equatable/equatable.dart';

enum CelestialObjectType {
  planet,
  star,
  moon,
  sun,
  constellation
}

class CelestialObject extends Equatable {
  final String id;
  final String name;
  final CelestialObjectType type;
  final double rightAscension; // in hours (0-24)
  final double declination; // in degrees (-90 to 90)
  final double magnitude; // brightness
  final String description;
  final String? imageUrl;
  final double size; // apparent size in arcseconds

  const CelestialObject({
    required this.id,
    required this.name,
    required this.type,
    required this.rightAscension,
    required this.declination,
    required this.magnitude,
    required this.description,
    this.imageUrl,
    required this.size,
  });

  // Create a CelestialObject from a JSON map
  factory CelestialObject.fromJson(Map<String, dynamic> json) {
    return CelestialObject(
      id: json['id'] as String,
      name: json['name'] as String,
      type: CelestialObjectType.values.firstWhere(
        (e) => e.toString() == 'CelestialObjectType.${json['type']}',
        orElse: () => CelestialObjectType.star,
      ),
      rightAscension: (json['rightAscension'] as num).toDouble(),
      declination: (json['declination'] as num).toDouble(),
      magnitude: (json['magnitude'] as num).toDouble(),
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String?,
      size: (json['size'] as num).toDouble(),
    );
  }

  // Convert a CelestialObject to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'rightAscension': rightAscension,
      'declination': declination,
      'magnitude': magnitude,
      'description': description,
      'imageUrl': imageUrl,
      'size': size,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        rightAscension,
        declination,
        magnitude,
        description,
        imageUrl,
        size,
      ];
} 