import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../models/celestial_object.dart';

class SkymapState extends Equatable {
  final bool isLoading;
  final String? error;
  final Position? location;
  final List<CelestialObject> celestialObjects;
  final CelestialObject? selectedObject;
  final UserAccelerometerEvent? accelerometerData;
  final MagnetometerEvent? magnetometerData;
  final double screenWidth;
  final double screenHeight;

  const SkymapState({
    this.isLoading = false,
    this.error,
    this.location,
    this.celestialObjects = const [],
    this.selectedObject,
    this.accelerometerData,
    this.magnetometerData,
    this.screenWidth = 0,
    this.screenHeight = 0,
  });

  SkymapState copyWith({
    bool? isLoading,
    String? error,
    Position? location,
    List<CelestialObject>? celestialObjects,
    CelestialObject? selectedObject,
    UserAccelerometerEvent? accelerometerData,
    MagnetometerEvent? magnetometerData,
    double? screenWidth,
    double? screenHeight,
  }) {
    return SkymapState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      location: location ?? this.location,
      celestialObjects: celestialObjects ?? this.celestialObjects,
      selectedObject: selectedObject ?? this.selectedObject,
      accelerometerData: accelerometerData ?? this.accelerometerData,
      magnetometerData: magnetometerData ?? this.magnetometerData,
      screenWidth: screenWidth ?? this.screenWidth,
      screenHeight: screenHeight ?? this.screenHeight,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        error,
        location,
        celestialObjects,
        selectedObject,
        accelerometerData,
        magnetometerData,
        screenWidth,
        screenHeight,
      ];
} 