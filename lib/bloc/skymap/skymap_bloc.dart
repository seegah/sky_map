import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../models/celestial_object.dart';
import 'skymap_event.dart';
import 'skymap_state.dart';

class SkymapBloc extends Bloc<SkymapEvent, SkymapState> {
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  StreamSubscription<Position>? _positionSubscription;

  SkymapBloc() : super(const SkymapState()) {
    on<InitializeSkymap>(_onInitializeSkymap);
    on<UpdateLocation>(_onUpdateLocation);
    on<UpdateAccelerometerData>(_onUpdateAccelerometerData);
    on<UpdateMagnetometerData>(_onUpdateMagnetometerData);
    on<LoadCelestialObjects>(_onLoadCelestialObjects);
    on<SelectCelestialObject>(_onSelectCelestialObject);
    on<DeselectCelestialObject>(_onDeselectCelestialObject);
  }
  double _getCurrentSunRA() {
  final now = DateTime.now();
  final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
  
  // Approximation simple de la position du soleil
  // Position du soleil change d'environ 1 degré par jour
  final sunLongitude = (dayOfYear * 0.9856) % 360;
  return sunLongitude / 15.0; // Convertir en heures
}

double _getCurrentSunDec() {
  final now = DateTime.now();
  final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
  
  // Déclinaison du soleil varie entre -23.5° et +23.5°
  final sunDeclination = 23.5 * sin((dayOfYear - 81) * 0.0172);
  return sunDeclination;
}

double _getCurrentMoonRA() {
  final now = DateTime.now();
  final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
  
  // La lune se déplace d'environ 13 degrés par jour
  final moonLongitude = (dayOfYear * 13.176) % 360;
  return moonLongitude / 15.0;
}

double _getCurrentMoonDec() {
  final now = DateTime.now();
  final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
  
  // Déclinaison de la lune varie entre -28.5° et +28.5°
  final moonDeclination = 28.5 * sin((dayOfYear - 81) * 0.0172 * 13.176);
  return moonDeclination;
}

  Future<void> _onInitializeSkymap(
    InitializeSkymap event,
    Emitter<SkymapState> emit,
  ) async {
    emit(state.copyWith(
      screenWidth: event.screenWidth,
      screenHeight: event.screenHeight,
    ));

    // Request location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        emit(state.copyWith(
          error: 'Location permissions are required for this app',
        ));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      emit(state.copyWith(
        error: 'Location permissions are permanently denied',
      ));
      return;
    }

    // Start location updates
    _positionSubscription = Geolocator.getPositionStream().listen(
      (Position position) {
        add(UpdateLocation(position));
      },
      onError: (error) {
        emit(state.copyWith(error: 'Error getting location: $error'));
      },
    );

    // Start accelerometer updates
    // ignore: deprecated_member_use
    _accelerometerSubscription = userAccelerometerEvents.listen(
      (UserAccelerometerEvent event) {
        add(UpdateAccelerometerData(event));
      },
      onError: (error) {
        emit(state.copyWith(error: 'Error getting accelerometer data: $error'));
      },
    );

    // Start magnetometer updates
    // ignore: deprecated_member_use
    _magnetometerSubscription = magnetometerEvents.listen(
      (MagnetometerEvent event) {
        add(UpdateMagnetometerData(event));
      },
      onError: (error) {
        emit(state.copyWith(error: 'Error getting magnetometer data: $error'));
      },
    );

    // Load initial celestial objects
    add(LoadCelestialObjects());
  }

  void _onUpdateLocation(
    UpdateLocation event,
    Emitter<SkymapState> emit,
  ) {
    emit(state.copyWith(location: event.location));
  }

  void _onUpdateAccelerometerData(
    UpdateAccelerometerData event,
    Emitter<SkymapState> emit,
  ) {
    emit(state.copyWith(accelerometerData: event.accelerometerData));
  }

  void _onUpdateMagnetometerData(
    UpdateMagnetometerData event,
    Emitter<SkymapState> emit,
  ) {
    emit(state.copyWith(magnetometerData: event.magnetometerData));
  }

  Future<void> _onLoadCelestialObjects(
    LoadCelestialObjects event,
    Emitter<SkymapState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      final List<CelestialObject> objects = [
  // Sun - Position approximative mise à jour
  CelestialObject(
    id: 'sun',
    name: 'Sun',
    type: CelestialObjectType.sun,
    rightAscension: _getCurrentSunRA(), // Position dynamique du soleil
    declination: _getCurrentSunDec(),   // Position dynamique du soleil
    magnitude: -26.7,
    description: 'The Sun is the star at the center of the Solar System. It is a nearly perfect sphere of hot plasma, with internal convective motion that generates a magnetic field via a dynamo process.',
    size: 1919.0,
  ),
  
  // Moon - Position approximative
  CelestialObject(
    id: 'moon',
    name: 'Moon',
    type: CelestialObjectType.moon,
    rightAscension: _getCurrentMoonRA(),
    declination: _getCurrentMoonDec(),
    magnitude: -12.7,
    description: 'The Moon is Earth\'s only natural satellite.',
    size: 1737.0,
  ),
  
  // Mars - Position réelle
  CelestialObject(
    id: 'mars',
    name: 'Mars',
    type: CelestialObjectType.planet,
    rightAscension: 14.2, // Position approximative pour septembre 2025
    declination: -12.5,
    magnitude: -2.6,
    description: 'Mars is the fourth planet from the Sun and the second-smallest planet in the Solar System. It is often called the "Red Planet" due to its reddish appearance.',
    size: 3389.5,
  ),
  
  // Venus - Position réelle
  CelestialObject(
    id: 'venus',
    name: 'Venus',
    type: CelestialObjectType.planet,
    rightAscension: 11.8, // Position approximative pour septembre 2025
    declination: 8.2,
    magnitude: -4.7,
    description: 'Venus is the second planet from the Sun and is Earth\'s closest planetary neighbor.',
    size: 6051.8,
  ),
  
  // Constellations avec vraies coordonnées
  CelestialObject(
    id: 'orion',
    name: 'Orion',
    type: CelestialObjectType.constellation,
    rightAscension: 5.5, // Coordonnées correctes d'Orion
    declination: 0,
    magnitude: 0,
    description: 'Orion is a prominent constellation located on the celestial equator and visible throughout the world.',
    size: 0,
  ),
  
  CelestialObject(
    id: 'ursa_major',
    name: 'Ursa Major',
    type: CelestialObjectType.constellation,
    rightAscension: 11.3, // Coordonnées correctes de la Grande Ourse
    declination: 50,
    magnitude: 0,
    description: 'Ursa Major is a constellation in the northern sky. Its Latin name means "greater she-bear".',
    size: 0,
  ),
  
  CelestialObject(
    id: 'cassiopeia',
    name: 'Cassiopeia',
    type: CelestialObjectType.constellation,
    rightAscension: 1.0, // Coordonnées correctes de Cassiopée
    declination: 60,
    magnitude: 0,
    description: 'Cassiopeia is a constellation in the northern sky, named after the vain queen Cassiopeia in Greek mythology.',
    size: 0,
  ),
];

      emit(state.copyWith(
        celestialObjects: objects,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: 'Error loading celestial objects: $e',
        isLoading: false,
      ));
    }
  }

  void _onSelectCelestialObject(
    SelectCelestialObject event,
    Emitter<SkymapState> emit,
  ) {
    emit(state.copyWith(selectedObject: event.object));
  }

  void _onDeselectCelestialObject(
    DeselectCelestialObject event,
    Emitter<SkymapState> emit,
  ) {
    emit(state.copyWith(selectedObject: null));
  }

  @override
  Future<void> close() {
    _accelerometerSubscription?.cancel();
    _magnetometerSubscription?.cancel();
    _positionSubscription?.cancel();
    return super.close();
  }
} 