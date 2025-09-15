import 'dart:async';
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
      // For now, we'll use dummy data
      final List<CelestialObject> objects = [
        // Sun
        CelestialObject(
          id: 'sun',
          name: 'Sun',
          type: CelestialObjectType.sun,
          rightAscension: 0,
          declination: 0,
          magnitude: -26.7,
          description: 'The Sun is the star at the center of the Solar System. It is a nearly perfect sphere of hot plasma, with internal convective motion that generates a magnetic field via a dynamo process.',
          size: 1919.0,
        ),
        
        // Moon
        CelestialObject(
          id: 'moon',
          name: 'Moon',
          type: CelestialObjectType.moon,
          rightAscension: 0,
          declination: 0,
          magnitude: -12.7,
          description: 'The Moon is Earth\'s only natural satellite. It is the fifth largest satellite in the Solar System and the largest and most massive relative to its parent planet.',
          size: 1737.0,
        ),
        
        // Planets
        CelestialObject(
          id: 'mercury',
          name: 'Mercury',
          type: CelestialObjectType.planet,
          rightAscension: 0,
          declination: 0,
          magnitude: -1.9,
          description: 'Mercury is the smallest and innermost planet in the Solar System. Its orbital period around the Sun of 87.97 days is the shortest of all the planets.',
          size: 2439.7,
        ),
        CelestialObject(
          id: 'venus',
          name: 'Venus',
          type: CelestialObjectType.planet,
          rightAscension: 0,
          declination: 0,
          magnitude: -4.7,
          description: 'Venus is the second planet from the Sun and is Earth\'s closest planetary neighbor. It\'s one of the four inner, terrestrial planets, and it\'s often called Earth\'s twin because it\'s similar in size and density.',
          size: 6051.8,
        ),
        CelestialObject(
          id: 'earth',
          name: 'Earth',
          type: CelestialObjectType.planet,
          rightAscension: 0,
          declination: 0,
          magnitude: 0,
          description: 'Earth is the third planet from the Sun and the only astronomical object known to harbor life. About 71% of Earth\'s surface is covered with water.',
          size: 6371.0,
        ),
        CelestialObject(
          id: 'mars',
          name: 'Mars',
          type: CelestialObjectType.planet,
          rightAscension: 0,
          declination: 0,
          magnitude: -2.6,
          description: 'Mars is the fourth planet from the Sun and the second-smallest planet in the Solar System. It is often called the "Red Planet" due to its reddish appearance.',
          size: 3389.5,
        ),
        CelestialObject(
          id: 'jupiter',
          name: 'Jupiter',
          type: CelestialObjectType.planet,
          rightAscension: 0,
          declination: 0,
          magnitude: -2.2,
          description: 'Jupiter is the fifth planet from the Sun and the largest in the Solar System. It is a gas giant with a mass more than two and a half times that of all the other planets combined.',
          size: 69911.0,
        ),
        CelestialObject(
          id: 'saturn',
          name: 'Saturn',
          type: CelestialObjectType.planet,
          rightAscension: 0,
          declination: 0,
          magnitude: 0.5,
          description: 'Saturn is the sixth planet from the Sun and the second-largest in the Solar System, after Jupiter. It is a gas giant with an average radius of about nine and a half times that of Earth.',
          size: 58232.0,
        ),
        CelestialObject(
          id: 'uranus',
          name: 'Uranus',
          type: CelestialObjectType.planet,
          rightAscension: 0,
          declination: 0,
          magnitude: 5.3,
          description: 'Uranus is the seventh planet from the Sun. It has the third-largest planetary radius and fourth-largest planetary mass in the Solar System.',
          size: 25362.0,
        ),
        CelestialObject(
          id: 'neptune',
          name: 'Neptune',
          type: CelestialObjectType.planet,
          rightAscension: 0,
          declination: 0,
          magnitude: 7.8,
          description: 'Neptune is the eighth and farthest known planet from the Sun. It is the fourth-largest planet by diameter and the third-most-massive.',
          size: 24622.0,
        ),
        
        // Constellations
        CelestialObject(
          id: 'orion',
          name: 'Orion',
          type: CelestialObjectType.constellation,
          rightAscension: 5.5,
          declination: 0,
          magnitude: 0,
          description: 'Orion is a prominent constellation located on the celestial equator and visible throughout the world. It is one of the most conspicuous and recognizable constellations in the night sky.',
          size: 0,
        ),
        CelestialObject(
          id: 'ursa_major',
          name: 'Ursa Major',
          type: CelestialObjectType.constellation,
          rightAscension: 11.3,
          declination: 50,
          magnitude: 0,
          description: 'Ursa Major is a constellation in the northern sky, whose associated mythology likely dates back into prehistory. Its Latin name means "greater (or larger) she-bear".',
          size: 0,
        ),
        CelestialObject(
          id: 'cassiopeia',
          name: 'Cassiopeia',
          type: CelestialObjectType.constellation,
          rightAscension: 1.0,
          declination: 60,
          magnitude: 0,
          description: 'Cassiopeia is a constellation in the northern sky, named after the vain queen Cassiopeia in Greek mythology, who boasted about her unrivaled beauty.',
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