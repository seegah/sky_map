import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../models/celestial_object.dart';

class AstronomyUtils {
  // Constantes astronomiques
  static const double _auInKm = 149597870.7; // Unité astronomique en km
// Jour sidéral en heures
  
  // Convert degrees to radians
  static double degreesToRadians(double degrees) {
    return degrees * (pi / 180.0);
  }

  // Convert radians to degrees
  static double radiansToDegrees(double radians) {
    return radians * (180.0 / pi);
  }

  // Convert hours to degrees
  static double hoursToDegrees(double hours) {
    return hours * 15.0;
  }

  // Convert degrees to hours
  static double degreesToHours(double degrees) {
    return degrees / 15.0;
  }

  // Normaliser un angle entre 0 et 360 degrés
  static double normalizeAngle(double angle) {
    while (angle < 0) angle += 360;
    while (angle >= 360) angle -= 360;
    return angle;
  }

  // Normaliser un angle entre -180 et 180 degrés
  static double normalizeAngle180(double angle) {
    while (angle < -180) angle += 360;
    while (angle > 180) angle -= 360;
    return angle;
  }

  // Calculate the Julian date with better precision
  static double calculateJulianDate(DateTime time) {
    final year = time.year;
    final month = time.month;
    final day = time.day;
    final hour = time.hour;
    final minute = time.minute;
    final second = time.second;
    final millisecond = time.millisecond;

    // Ajustement pour les mois de janvier et février
    int adjustedYear = year;
    int adjustedMonth = month;
    
    if (month <= 2) {
      adjustedYear = year - 1;
      adjustedMonth = month + 12;
    }

    // Correction grégorienne
    final a = (adjustedYear / 100).floor();
    final b = 2 - a + (a / 4).floor();

    // Calcul du jour julien
    final jd = (365.25 * (adjustedYear + 4716)).floor() +
               (30.6001 * (adjustedMonth + 1)).floor() +
               day + b - 1524;

    // Fraction du jour
    final dayFraction = (hour - 12) / 24.0 + 
                       minute / 1440.0 + 
                       second / 86400.0 + 
                       millisecond / 86400000.0;

    return jd + dayFraction;
  }

  // Calculate the Greenwich Mean Sidereal Time (GMST)
  static double calculateGMST(DateTime time) {
    final jd = calculateJulianDate(time);
    final t = (jd - 2451545.0) / 36525.0;

    // Formule IAU pour GMST
    double gmst = 280.46061837 + 
                 360.98564736629 * (jd - 2451545.0) +
                 0.000387933 * t * t - 
                 (t * t * t) / 38710000.0;

    return normalizeAngle(gmst);
  }

  // Calculate the local sidereal time (LST)
  static double calculateLST(Position location, DateTime time) {
    final gmst = calculateGMST(time);
    final lst = gmst + location.longitude;
    return normalizeAngle(lst);
  }

  // Calcul de l'équation du temps (pour la position précise du soleil)
  static double calculateEquationOfTime(DateTime time) {
    final dayOfYear = time.difference(DateTime(time.year, 1, 1)).inDays + 1;
    final b = 2 * pi * (dayOfYear - 81) / 365;
    
    final equationOfTime = 9.87 * sin(2 * b) - 
                          7.53 * cos(b) - 
                          1.5 * sin(b);
    
    return equationOfTime; // en minutes
  }

  // Calculate the altitude and azimuth of a celestial object
  static Map<String, double> calculateAltAz(
    CelestialObject object,
    Position location,
    DateTime time,
  ) {
    // Convertir les coordonnées en radians
    final ra = degreesToRadians(hoursToDegrees(object.rightAscension));
    final dec = degreesToRadians(object.declination);
    final lat = degreesToRadians(location.latitude);

    // Calculer l'heure sidérale locale
    final lst = calculateLST(location, time);
    final lstRad = degreesToRadians(lst);

    // Calculer l'angle horaire
    final ha = lstRad - ra;

    // Calculer l'altitude
    final sinAlt = sin(dec) * sin(lat) + cos(dec) * cos(lat) * cos(ha);
    final alt = asin(sinAlt);

    // Calculer l'azimut
    final cosAlt = cos(alt);
    final sinAz = -sin(ha) * cos(dec) / cosAlt;
    final cosAz = (sin(dec) - sin(alt) * sin(lat)) / (cosAlt * cos(lat));
    
    double az = atan2(sinAz, cosAz);
    az = normalizeAngle(radiansToDegrees(az));

    return {
      'altitude': radiansToDegrees(alt),
      'azimuth': az,
    };
  }

  // Calculer la position du soleil avec plus de précision
  static Map<String, double> calculateSunPosition(Position location, DateTime time) {
    final dayOfYear = time.difference(DateTime(time.year, 1, 1)).inDays + 1;
    
    // Longitude écliptique du soleil (approximation)
    final meanLongitude = 280.460 + 0.9856474 * dayOfYear;
    final meanAnomaly = degreesToRadians(357.528 + 0.9856003 * dayOfYear);
    
    // Équation du centre
    final center = 1.915 * sin(meanAnomaly) + 0.020 * sin(2 * meanAnomaly);
    final trueLongitude = degreesToRadians(meanLongitude + center);
    
    // Obliquité de l'écliptique
    final obliquity = degreesToRadians(23.439 - 0.0000004 * dayOfYear);
    
    // Coordonnées équatoriales
    final ra = atan2(cos(obliquity) * sin(trueLongitude), cos(trueLongitude));
    final dec = asin(sin(obliquity) * sin(trueLongitude));
    
    // Créer un objet soleil temporaire avec les vraies coordonnées
    final sunObject = CelestialObject(
      id: 'sun_calculated',
      name: 'Sun',
      type: CelestialObjectType.sun,
      rightAscension: degreesToHours(radiansToDegrees(ra)),
      declination: radiansToDegrees(dec),
      magnitude: -26.7,
      description: 'Calculated Sun position',
      size: 1919.0,
    );
    
    return calculateAltAz(sunObject, location, time);
  }

  // Calculer la position de la lune (approximation)
  static Map<String, double> calculateMoonPosition(Position location, DateTime time) {
    final daysSinceEpoch = time.difference(DateTime(2000, 1, 1, 12)).inDays;
    
    // Longitude écliptique moyenne de la lune
    final meanLongitude = 218.316 + 13.176396 * daysSinceEpoch;
    final meanAnomaly = degreesToRadians(134.963 + 13.064993 * daysSinceEpoch);
    
    // Corrections principales
    final evection = 1.274 * sin(degreesToRadians(meanLongitude) - 2 * meanAnomaly);
    final variation = 0.658 * sin(2 * degreesToRadians(meanLongitude));
    
    final correctedLongitude = degreesToRadians(meanLongitude + evection + variation);
    
    // Latitude écliptique (approximation)
    final latitude = degreesToRadians(5.128 * sin(degreesToRadians(93.272 + 13.229350 * daysSinceEpoch)));
    
    // Obliquité
    final obliquity = degreesToRadians(23.439);
    
    // Conversion vers coordonnées équatoriales
    final ra = atan2(
      sin(correctedLongitude) * cos(obliquity) - tan(latitude) * sin(obliquity),
      cos(correctedLongitude)
    );
    
    final dec = asin(
      sin(latitude) * cos(obliquity) + cos(latitude) * sin(obliquity) * sin(correctedLongitude)
    );
    
    final moonObject = CelestialObject(
      id: 'moon_calculated',
      name: 'Moon',
      type: CelestialObjectType.moon,
      rightAscension: degreesToHours(normalizeAngle(radiansToDegrees(ra))),
      declination: radiansToDegrees(dec),
      magnitude: -12.7,
      description: 'Calculated Moon position',
      size: 1737.0,
    );
    
    return calculateAltAz(moonObject, location, time);
  }

  // Convert altitude and azimuth to screen coordinates with improved projection
  static Offset altAzToScreenCoordinates(
    double altitude,
    double azimuth,
    double screenWidth,
    double screenHeight,
  ) {
    // Ne pas afficher les objets sous l'horizon
    if (altitude < -5) {
      return const Offset(-1000, -1000);
    }
    
    // Projection stéréographique pour une meilleure représentation du ciel
    final altRad = degreesToRadians(max(altitude, 0));
    final azRad = degreesToRadians(azimuth);
    
    // Rayon basé sur l'altitude (projection stéréographique)
    final zenithAngle = pi/2 - altRad;
    final radius = tan(zenithAngle / 2) * min(screenWidth, screenHeight) * 0.4;
    
    // Azimut ajusté (0° = Nord = haut de l'écran)
    final adjustedAzRad = azRad - pi/2;
    
    // Calculer les coordonnées d'écran
    final x = screenWidth / 2 + radius * cos(adjustedAzRad);
    final y = screenHeight / 2 + radius * sin(adjustedAzRad);
    
    return Offset(x, y);
  }

  // Calculate device orientation from sensor data
  static Map<String, double> calculateDeviceOrientation(
    UserAccelerometerEvent accelerometerData,
    MagnetometerEvent magnetometerData,
  ) {
    // Filtrage des données pour réduire le bruit
    final ax = accelerometerData.x;
    final ay = accelerometerData.y;
    final az = accelerometerData.z;
    
    final mx = magnetometerData.x;
    final my = magnetometerData.y;
    final mz = magnetometerData.z;
    
    // Calculer le roll (inclinaison latérale)
    final roll = atan2(ay, az);
    
    // Calculer le pitch (inclinaison avant/arrière)
    final pitch = atan2(-ax, sqrt(ay * ay + az * az));
    
    // Calculer le yaw (orientation magnétique) avec compensation d'inclinaison
    final magX = mx * cos(pitch) + mz * sin(pitch);
    final magY = mx * sin(roll) * sin(pitch) + my * cos(roll) - mz * sin(roll) * cos(pitch);
    
    final yaw = atan2(-magY, magX);
    
    return {
      'roll': normalizeAngle180(radiansToDegrees(roll)),
      'pitch': normalizeAngle180(radiansToDegrees(pitch)),
      'yaw': normalizeAngle(radiansToDegrees(yaw)),
    };
  }

  // Main function to calculate screen position with sensor compensation
  static Offset calculateScreenPosition(
    CelestialObject object,
    Position location,
    UserAccelerometerEvent? accelerometerData,
    MagnetometerEvent? magnetometerData,
    double screenWidth,
    double screenHeight,
  ) {
    final now = DateTime.now();
    
    // Utiliser des calculs spécialisés pour le soleil et la lune
    Map<String, double> altAz;
    
    if (object.type == CelestialObjectType.sun) {
      altAz = calculateSunPosition(location, now);
    } else if (object.type == CelestialObjectType.moon) {
      altAz = calculateMoonPosition(location, now);
    } else {
      altAz = calculateAltAz(object, location, now);
    }
    
    double altitude = altAz['altitude']!;
    double azimuth = altAz['azimuth']!;
    
    // Compensation basée sur l'orientation du dispositif
    if (accelerometerData != null && magnetometerData != null) {
      final deviceOrientation = calculateDeviceOrientation(
        accelerometerData,
        magnetometerData,
      );
      
      // Ajuster l'azimut selon l'orientation du téléphone
      azimuth = normalizeAngle(azimuth - deviceOrientation['yaw']!);
      
      // Ajuster l'altitude selon l'inclinaison du téléphone
      altitude += deviceOrientation['pitch']! * 0.5; // Facteur d'amortissement
    }
    
    // Convertir en coordonnées d'écran
    return altAzToScreenCoordinates(altitude, azimuth, screenWidth, screenHeight);
  }

  // Calculer la distance apparente entre deux objets célestes
  static double calculateAngularDistance(
    CelestialObject object1,
    CelestialObject object2,
  ) {
    final ra1 = degreesToRadians(hoursToDegrees(object1.rightAscension));
    final dec1 = degreesToRadians(object1.declination);
    final ra2 = degreesToRadians(hoursToDegrees(object2.rightAscension));
    final dec2 = degreesToRadians(object2.declination);
    
    // Formule de la distance angulaire sur la sphère céleste
    final cosDistance = sin(dec1) * sin(dec2) + 
                       cos(dec1) * cos(dec2) * cos(ra1 - ra2);
    
    return radiansToDegrees(acos(cosDistance.clamp(-1.0, 1.0)));
  }

  // Calculer la magnitude apparente ajustée selon la distance
  static double calculateApparentMagnitude(
    CelestialObject object,
    double distanceKm,
  ) {
    if (object.type == CelestialObjectType.star || 
        object.type == CelestialObjectType.constellation) {
      return object.magnitude; // Les étoiles ont une magnitude fixe
    }
    
    // Pour les objets du système solaire, ajuster selon la distance
    final referenceMagnitude = object.magnitude;
    final referenceDistance = _auInKm; // Distance de référence (1 AU)
    
    // Loi de l'inverse du carré pour la luminosité
    final magnitudeAdjustment = 2.5 * log(pow(distanceKm / referenceDistance, 2)) / ln10;
    
    return referenceMagnitude + magnitudeAdjustment;
  }

  // Vérifier si un objet est visible (au-dessus de l'horizon)
  static bool isObjectVisible(
    CelestialObject object,
    Position location,
    DateTime time,
  ) {
    final altAz = calculateAltAz(object, location, time);
    return altAz['altitude']! > -5; // Marge de 5 degrés pour la réfraction
  }

  // Calculer les heures de lever et coucher d'un objet céleste
  static Map<String, DateTime?> calculateRiseSetTimes(
    CelestialObject object,
    Position location,
    DateTime date,
  ) {
    DateTime? riseTime;
    DateTime? setTime;
    
    // Parcourir la journée par intervalles de 30 minutes
    for (int minutes = 0; minutes < 1440; minutes += 30) {
      final testTime = DateTime(date.year, date.month, date.day).add(Duration(minutes: minutes));
      final altAz = calculateAltAz(object, location, testTime);
      final altitude = altAz['altitude']!;
      
      if (minutes > 0) {
        final prevTime = testTime.subtract(const Duration(minutes: 30));
        final prevAltAz = calculateAltAz(object, location, prevTime);
        final prevAltitude = prevAltAz['altitude']!;
        
        // Lever : passage de négatif à positif
        if (prevAltitude < 0 && altitude > 0 && riseTime == null) {
          riseTime = _interpolateRiseSetTime(object, location, prevTime, testTime, true);
        }
        
        // Coucher : passage de positif à négatif
        if (prevAltitude > 0 && altitude < 0 && setTime == null && riseTime != null) {
          setTime = _interpolateRiseSetTime(object, location, prevTime, testTime, false);
        }
      }
    }
    
    return {
      'rise': riseTime,
      'set': setTime,
    };
  }

  // Interpolation précise pour les heures de lever/coucher
  static DateTime _interpolateRiseSetTime(
    CelestialObject object,
    Position location,
    DateTime time1,
    DateTime time2,
    bool isRising,
  ) {
    // Interpolation binaire pour trouver le moment exact
    DateTime start = time1;
    DateTime end = time2;
    
    for (int i = 0; i < 10; i++) { // 10 itérations donnent une précision d'environ 30 secondes
      final mid = start.add(Duration(milliseconds: end.difference(start).inMilliseconds ~/ 2));
      final altAz = calculateAltAz(object, location, mid);
      final altitude = altAz['altitude']!;
      
      if ((isRising && altitude < 0) || (!isRising && altitude > 0)) {
        start = mid;
      } else {
        end = mid;
      }
    }
    
    return start.add(Duration(milliseconds: end.difference(start).inMilliseconds ~/ 2));
  }

  // Calculer la phase de la lune (0 = nouvelle lune, 0.5 = pleine lune, 1 = nouvelle lune suivante)
  static double calculateMoonPhase(DateTime time) {
    // Époque de référence : nouvelle lune du 6 janvier 2000
    final epoch = DateTime(2000, 1, 6, 18, 14);
    final daysSinceEpoch = time.difference(epoch).inDays;
    
    // Cycle lunaire moyen : 29.53059 jours
    const lunarCycle = 29.53059;
    final phase = (daysSinceEpoch % lunarCycle) / lunarCycle;
    
    return phase;
  }

  // Obtenir le nom de la phase lunaire
  static String getMoonPhaseName(double phase) {
    if (phase < 0.0625 || phase >= 0.9375) return 'Nouvelle Lune';
    if (phase < 0.1875) return 'Premier Croissant';
    if (phase < 0.3125) return 'Premier Quartier';
    if (phase < 0.4375) return 'Lune Gibbeuse Croissante';
    if (phase < 0.5625) return 'Pleine Lune';
    if (phase < 0.6875) return 'Lune Gibbeuse Décroissante';
    if (phase < 0.8125) return 'Dernier Quartier';
    return 'Dernier Croissant';
  }

  // Calculer l'âge de la lune en jours
  static double getMoonAge(DateTime time) {
    final phase = calculateMoonPhase(time);
    return phase * 29.53059;
  }
}