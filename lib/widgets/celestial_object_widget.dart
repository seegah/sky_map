import 'package:flutter/material.dart';
import '../models/celestial_object.dart';

class CelestialObjectWidget extends StatelessWidget {
  final CelestialObject object;
  final double x;
  final double y;
  final double size;
  final VoidCallback onTap;

  const CelestialObjectWidget({
    super.key,
    required this.object,
    required this.x,
    required this.y,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x - size / 2,
      top: y - size / 2,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getObjectColor(),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: _getObjectColor().withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              object.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
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