import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../models/celestial_object.dart';

class AstronomyUtils {
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

  // Calculate the altitude and azimuth of a celestial object
  static Map<String, double> calculateAltAz(
    CelestialObject object,
    Position location,
    DateTime time,
  ) {
    // Convert right ascension and declination to radians
    final ra = degreesToRadians(hoursToDegrees(object.rightAscension));
    final dec = degreesToRadians(object.declination);

    // Calculate the local sidereal time (LST)
    final lst = calculateLST(location, time);

    // Calculate the hour angle (HA)
    final ha = lst - ra;

    // Convert latitude to radians
    final lat = degreesToRadians(location.latitude);

    // Calculate altitude (alt)
    final sinAlt = sin(dec) * sin(lat) + cos(dec) * cos(lat) * cos(ha);
    final alt = radiansToDegrees(asin(sinAlt));

    // Calculate azimuth (az)
    final sinAz = -sin(ha) * cos(dec) / cos(degreesToRadians(alt));
    final cosAz = (sin(dec) - sin(degreesToRadians(alt)) * sin(lat)) /
        (cos(degreesToRadians(alt)) * cos(lat));
    final az = radiansToDegrees(atan2(sinAz, cosAz));

    // Normalize azimuth to 0-360
    final normalizedAz = (az + 360) % 360;

    return {
      'altitude': alt,
      'azimuth': normalizedAz,
    };
  }

  // Calculate the local sidereal time (LST)
  static double calculateLST(Position location, DateTime time) {
    // Calculate the Julian date
    final jd = calculateJulianDate(time);

    // Calculate the Greenwich mean sidereal time (GMST)
    final t = (jd - 2451545.0) / 36525.0;
    final gmst = 280.46061837 + 360.98564736629 * (jd - 2451545.0) +
        0.000387933 * t * t - t * t * t / 38710000.0;
    final normalizedGmst = gmst % 360;

    // Calculate the local sidereal time (LST)
    final lst = normalizedGmst + location.longitude;
    final normalizedLst = lst % 360;

    // Convert to hours
    return normalizedLst / 15.0;
  }

  // Calculate the Julian date
  static double calculateJulianDate(DateTime time) {
    final year = time.year;
    final month = time.month;
    final day = time.day;
    final hour = time.hour;
    final minute = time.minute;
    final second = time.second;

    final a = (14 - month) ~/ 12;
    final y = year + 4800 - a;
    final m = month + 12 * a - 3;

    final jd = day + (153 * m + 2) ~/ 5 + 365 * y + y ~/ 4 - y ~/ 100 + y ~/ 400 - 32045;
    final jdFrac = (hour - 12) / 24.0 + minute / 1440.0 + second / 86400.0;

    return jd + jdFrac;
  }

  // Convert altitude and azimuth to screen coordinates
  static Offset altAzToScreenCoordinates(
    double altitude,
    double azimuth,
    double screenWidth,
    double screenHeight,
  ) {
    // Convert altitude and azimuth to radians
    degreesToRadians(altitude);
    final azRad = degreesToRadians(azimuth);

    // Calculate the x and y coordinates
    // The azimuth is measured clockwise from the north, so we need to adjust it
    final adjustedAzRad = azRad - pi / 2;

    // The altitude is measured from the horizon, so we need to adjust it
    // 0 degrees is at the horizon, 90 degrees is at the zenith
    final radius = (90 - altitude) / 90.0;

    // Calculate the x and y coordinates
    final x = screenWidth / 2 + radius * cos(adjustedAzRad) * screenWidth / 2;
    final y = screenHeight / 2 + radius * sin(adjustedAzRad) * screenHeight / 2;

    return Offset(x, y);
  }

  // Calculate the screen position of a celestial object based on sensor data
  static Offset calculateScreenPosition(
    CelestialObject object,
    Position location,
    UserAccelerometerEvent? accelerometerData,
    MagnetometerEvent? magnetometerData,
    double screenWidth,
    double screenHeight,
  ) {
    // Get the current time
    final now = DateTime.now();

    // Calculate the altitude and azimuth of the object
    final altAz = calculateAltAz(object, location, now);

    // If we have accelerometer and magnetometer data, adjust the position
    if (accelerometerData != null && magnetometerData != null) {
      // Calculate the device orientation
      final deviceOrientation = calculateDeviceOrientation(
        accelerometerData,
        magnetometerData,
      );

      // Adjust the altitude and azimuth based on the device orientation
      final adjustedAltAz = adjustAltAzForDeviceOrientation(
        altAz['altitude']!,
        altAz['azimuth']!,
        deviceOrientation,
      );

      // Convert the adjusted altitude and azimuth to screen coordinates
      return altAzToScreenCoordinates(
        adjustedAltAz['altitude']!,
        adjustedAltAz['azimuth']!,
        screenWidth,
        screenHeight,
      );
    }

    // If we don't have sensor data, just use the calculated altitude and azimuth
    return altAzToScreenCoordinates(
      altAz['altitude']!,
      altAz['azimuth']!,
      screenWidth,
      screenHeight,
    );
  }

  // Calculate the device orientation from accelerometer and magnetometer data
  static Map<String, double> calculateDeviceOrientation(
    UserAccelerometerEvent accelerometerData,
    MagnetometerEvent magnetometerData,
  ) {
    // Calculate the roll (rotation around the x-axis)
    final roll = atan2(accelerometerData.y, accelerometerData.z);

    // Calculate the pitch (rotation around the y-axis)
    final pitch = atan2(
      -accelerometerData.x,
      sqrt(accelerometerData.y * accelerometerData.y +
          accelerometerData.z * accelerometerData.z),
    );

    // Calculate the yaw (rotation around the z-axis)
    final yaw = atan2(magnetometerData.y, magnetometerData.x);

    return {
      'roll': radiansToDegrees(roll),
      'pitch': radiansToDegrees(pitch),
      'yaw': radiansToDegrees(yaw),
    };
  }

  // Adjust altitude and azimuth based on device orientation
  static Map<String, double> adjustAltAzForDeviceOrientation(
    double altitude,
    double azimuth,
    Map<String, double> deviceOrientation,
  ) {
    // Convert altitude and azimuth to radians
    final altRad = degreesToRadians(altitude);
    final azRad = degreesToRadians(azimuth);

    // Convert device orientation to radians
    degreesToRadians(deviceOrientation['roll']!);
    final pitchRad = degreesToRadians(deviceOrientation['pitch']!);
    final yawRad = degreesToRadians(deviceOrientation['yaw']!);

    // Adjust the altitude and azimuth based on the device orientation
    // This is a simplified calculation and may not be accurate for all orientations
    final adjustedAlt = altRad - pitchRad;
    final adjustedAz = azRad - yawRad;

    // Convert back to degrees
    return {
      'altitude': radiansToDegrees(adjustedAlt),
      'azimuth': (radiansToDegrees(adjustedAz) + 360) % 360,
    };
  }
} 