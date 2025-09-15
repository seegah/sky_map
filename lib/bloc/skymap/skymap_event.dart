import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../models/celestial_object.dart';

abstract class SkymapEvent extends Equatable {
  const SkymapEvent();

  @override
  List<Object?> get props => [];
}

class InitializeSkymap extends SkymapEvent {
  final double screenWidth;
  final double screenHeight;

  const InitializeSkymap({
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  List<Object?> get props => [screenWidth, screenHeight];
}

class UpdateLocation extends SkymapEvent {
  final Position location;

  const UpdateLocation(this.location);

  @override
  List<Object?> get props => [location];
}

class UpdateAccelerometerData extends SkymapEvent {
  final UserAccelerometerEvent accelerometerData;

  const UpdateAccelerometerData(this.accelerometerData);

  @override
  List<Object?> get props => [accelerometerData];
}

class UpdateMagnetometerData extends SkymapEvent {
  final MagnetometerEvent magnetometerData;

  const UpdateMagnetometerData(this.magnetometerData);

  @override
  List<Object?> get props => [magnetometerData];
}

class LoadCelestialObjects extends SkymapEvent {}

class SelectCelestialObject extends SkymapEvent {
  final CelestialObject object;

  const SelectCelestialObject(this.object);

  @override
  List<Object?> get props => [object];
}

class DeselectCelestialObject extends SkymapEvent {} 