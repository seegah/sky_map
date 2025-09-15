import 'package:flutter/material.dart';
import '../models/celestial_object.dart';

class CelestialObjectDetails extends StatelessWidget {
  final CelestialObject object;
  final VoidCallback onClose;

  const CelestialObjectDetails({
    Key? key,
    required this.object,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getObjectColor(),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                object.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Future.delayed(const Duration(milliseconds: 50), onClose);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Type: ${_getObjectTypeName()}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Right Ascension: ${object.rightAscension.toStringAsFixed(2)} hours',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Declination: ${object.declination.toStringAsFixed(2)}°',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Magnitude: ${object.magnitude.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Size: ${object.size.toStringAsFixed(2)} km',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Text(
            object.description,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  String _getObjectTypeName() {
    switch (object.type) {
      case CelestialObjectType.sun:
        return 'Sun';
      case CelestialObjectType.moon:
        return 'Moon';
      case CelestialObjectType.planet:
        return 'Planet';
      case CelestialObjectType.star:
        return 'Star';
      case CelestialObjectType.constellation:
        return 'Constellation';
    }
  }

  Color _getObjectColor() {
    switch (object.type) {
      case CelestialObjectType.sun:
        return Colors.yellow;
      case CelestialObjectType.moon:
        return Colors.grey;
      case CelestialObjectType.planet:
        return Colors.orange;
      case CelestialObjectType.star:
        return Colors.white;
      case CelestialObjectType.constellation:
        return Colors.blue;
    }
  }
} 