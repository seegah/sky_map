import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/celestial_object.dart';

class CelestialService {
  static const String _apiBaseUrl = 'https://api.example.com/celestial'; // Replace with actual API URL
  static const String _apiKey = 'YOUR_API_KEY'; // Replace with actual API key
  static const String _cacheKey = 'celestial_objects_cache';
  static const Duration _cacheExpiration = Duration(hours: 24);

  // Fetch celestial objects from API or cache
  Future<List<CelestialObject>> fetchCelestialObjects() async {
    try {
      // Try to get cached data first
      final cachedData = await _getCachedData();
      if (cachedData != null) {
        return cachedData;
      }

      // If no cached data, fetch from API
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/objects'),
        headers: {'Authorization': 'Bearer $_apiKey'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final objects = _parseApiResponse(data);
        
        // Cache the fetched data
        await _cacheData(objects);
        
        return objects;
      } else {
        throw Exception('Failed to fetch celestial objects: ${response.statusCode}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching celestial objects: $e');
      // Return default objects as fallback
      return _getDefaultCelestialObjects();
    }
  }

  // Parse API response into CelestialObject instances
  List<CelestialObject> _parseApiResponse(List<dynamic> data) {
    return data.map((item) => CelestialObject.fromJson(item)).toList();
  }

  // Cache celestial objects
  Future<void> _cacheData(List<CelestialObject> objects) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = objects.map((obj) => obj.toJson()).toList();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    await prefs.setString(_cacheKey, json.encode({
      'timestamp': timestamp,
      'data': jsonData,
    }));
  }

  // Get cached celestial objects if available and not expired
  Future<List<CelestialObject>?> _getCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedString = prefs.getString(_cacheKey);
    
    if (cachedString != null) {
      final cached = json.decode(cachedString);
      final timestamp = cached['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Check if cache is still valid
      if (now - timestamp < _cacheExpiration.inMilliseconds) {
        final List<dynamic> data = cached['data'];
        return data.map((item) => CelestialObject.fromJson(item)).toList();
      }
    }
    
    return null;
  }

  // Default celestial objects as fallback
  List<CelestialObject> _getDefaultCelestialObjects() {
    return [
      CelestialObject(
        id: 'sun',
        name: 'Sun',
        type: CelestialObjectType.sun,
        rightAscension: 0.0,
        declination: 0.0,
        magnitude: -26.7,
        description: 'The Sun is the star at the center of the Solar System.',
        imageUrl: 'https://example.com/sun.jpg',
        size: 1919.0,
      ),
      CelestialObject(
        id: 'moon',
        name: 'Moon',
        type: CelestialObjectType.moon,
        rightAscension: 0.0,
        declination: 0.0,
        magnitude: -12.7,
        description: 'The Moon is Earth\'s only natural satellite.',
        imageUrl: 'https://example.com/moon.jpg',
        size: 1867.0,
      ),
    ];
  }
} 