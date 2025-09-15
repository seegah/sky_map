// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../models/celestial_object.dart';

class CelestialObjectWidget extends StatefulWidget {
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
  State<CelestialObjectWidget> createState() => _CelestialObjectWidgetState();
}

class _CelestialObjectWidgetState extends State<CelestialObjectWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation de pulsation pour les étoiles et le soleil
    _pulseController = AnimationController(
      duration: Duration(
        milliseconds: _getPulseDuration(),
      ),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Animation de rotation pour les planètes
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_rotationController);

    // Démarrer les animations selon le type d'objet
    if (_shouldPulse()) {
      _pulseController.repeat(reverse: true);
    }
    
    if (_shouldRotate()) {
      _rotationController.repeat();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  bool _shouldPulse() {
    return widget.object.type == CelestialObjectType.sun ||
           widget.object.type == CelestialObjectType.star;
  }

  bool _shouldRotate() {
    return widget.object.type == CelestialObjectType.planet;
  }

  int _getPulseDuration() {
    switch (widget.object.type) {
      case CelestialObjectType.sun:
        return 2000;
      case CelestialObjectType.star:
        return 3000 + (widget.object.id.hashCode % 2000);
      default:
        return 2000;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ne pas afficher si les coordonnées sont hors écran
    if (widget.x < -100 || widget.y < -100 || 
        widget.x > MediaQuery.of(context).size.width + 100 ||
        widget.y > MediaQuery.of(context).size.height + 100) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: widget.x - widget.size / 2,
      top: widget.y - widget.size / 2,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: widget.size * 2, // Zone de tap plus large
          height: widget.size * 2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Halo lumineux animé
              AnimatedBuilder(
                animation: _shouldPulse() ? _pulseAnimation : _rotationAnimation,
                builder: (context, child) {
                  final scale = _shouldPulse() ? _pulseAnimation.value : 1.0;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: widget.size * 2,
                      height: widget.size * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _getObjectColor().withOpacity(0.3),
                            blurRadius: widget.size * 0.8,
                            spreadRadius: widget.size * 0.2,
                          ),
                          BoxShadow(
                            color: _getObjectColor().withOpacity(0.1),
                            blurRadius: widget.size * 1.5,
                            spreadRadius: widget.size * 0.5,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              // Objet principal avec animation
              AnimatedBuilder(
                animation: _shouldRotate() ? _rotationAnimation : _pulseAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _shouldRotate() ? _rotationAnimation.value * 2 * 3.14159 : 0,
                    child: Transform.scale(
                      scale: _shouldPulse() ? _pulseAnimation.value : 1.0,
                      child: Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          shape: _getObjectShape(),
                          color: _getObjectColor(),
                          gradient: _getObjectGradient(),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.6),
                            width: _getBorderWidth(),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _getObjectColor().withOpacity(0.5),
                              blurRadius: widget.size * 0.3,
                              spreadRadius: widget.size * 0.1,
                            ),
                          ],
                        ),
                        child: _buildObjectContent(),
                      ),
                    ),
                  );
                },
              ),
              
              // Étiquette avec nom si l'objet est assez grand
              if (widget.size > 25)
                Positioned(
                  bottom: -25,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getObjectColor().withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.object.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _getLabelFontSize(),
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: _getObjectColor(),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // Indicateur de magnitude pour les étoiles
              if (widget.object.type == CelestialObjectType.star && widget.size > 20)
                Positioned(
                  top: -15,
                  right: -10,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text(
                        widget.object.magnitude.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildObjectContent() {
    switch (widget.object.type) {
      case CelestialObjectType.sun:
        return Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.wb_sunny,
              color: Colors.white,
              size: widget.size * 0.6,
            ),
            // Rayons du soleil
            for (int i = 0; i < 8; i++)
              Transform.rotate(
                angle: (i * 3.14159 / 4),
                child: Container(
                  width: 2,
                  height: widget.size * 0.8,
                  decoration: BoxDecoration(
                    color: Colors.yellow.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
          ],
        );
        
      case CelestialObjectType.moon:
        return Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.brightness_3,
              color: Colors.white,
              size: widget.size * 0.7,
            ),
            // Cratères de la lune
            Positioned(
              top: widget.size * 0.2,
              left: widget.size * 0.3,
              child: Container(
                width: widget.size * 0.15,
                height: widget.size * 0.15,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        );
        
      case CelestialObjectType.planet:
        return Stack(
          alignment: Alignment.center,
          children: [
            // Anneaux pour Saturne
            if (widget.object.name.toLowerCase() == 'saturn')
              Container(
                width: widget.size * 1.4,
                height: widget.size * 0.3,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
                  borderRadius: BorderRadius.circular(widget.size * 0.7),
                ),
              ),
            // Corps de la planète
            Container(
              width: widget.size * 0.8,
              height: widget.size * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _getObjectColor().withOpacity(0.8),
                    _getObjectColor(),
                  ],
                ),
              ),
            ),
            // Détails spécifiques à chaque planète
            _buildPlanetDetails(),
          ],
        );
        
      case CelestialObjectType.star:
        return Icon(
          Icons.star,
          color: Colors.white,
          size: widget.size * 0.8,
        );
        
      case CelestialObjectType.constellation:
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: ConstellationPainter(),
        );
    }
  }

  Widget _buildPlanetDetails() {
    switch (widget.object.name.toLowerCase()) {
      case 'mars':
        return Container(
          width: widget.size * 0.3,
          height: widget.size * 0.3,
          decoration: BoxDecoration(
            color: Colors.red.shade800,
            shape: BoxShape.circle,
          ),
        );
      case 'jupiter':
        return Container(
          width: widget.size * 0.6,
          height: widget.size * 0.1,
          decoration: BoxDecoration(
            color: Colors.brown.shade300,
            borderRadius: BorderRadius.circular(widget.size * 0.05),
          ),
        );
      case 'earth':
        return Stack(
          children: [
            Container(
              width: widget.size * 0.4,
              height: widget.size * 0.4,
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: widget.size * 0.3,
              height: widget.size * 0.2,
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: BorderRadius.circular(widget.size * 0.1),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  BoxShape _getObjectShape() {
    return BoxShape.circle;
  }

  double _getBorderWidth() {
    switch (widget.object.type) {
      case CelestialObjectType.sun:
        return 2.0;
      case CelestialObjectType.moon:
        return 1.5;
      case CelestialObjectType.planet:
        return 1.0;
      case CelestialObjectType.star:
        return 0.5;
      case CelestialObjectType.constellation:
        return 1.0;
    }
  }

  double _getLabelFontSize() {
    if (widget.size > 60) return 12;
    if (widget.size > 40) return 10;
    return 8;
  }

  Color _getObjectColor() {
    switch (widget.object.type) {
      case CelestialObjectType.sun:
        return Colors.yellow.shade600;
      case CelestialObjectType.moon:
        return Colors.grey.shade300;
      case CelestialObjectType.planet:
        return _getPlanetColor();
      case CelestialObjectType.star:
        return _getStarColor();
      case CelestialObjectType.constellation:
        return Colors.blue.shade300;
    }
  }

  Color _getPlanetColor() {
    switch (widget.object.name.toLowerCase()) {
      case 'mercury':
        return Colors.grey.shade600;
      case 'venus':
        return Colors.orange.shade300;
      case 'earth':
        return Colors.blue.shade600;
      case 'mars':
        return Colors.red.shade600;
      case 'jupiter':
        return Colors.orange.shade700;
      case 'saturn':
        return Colors.yellow.shade700;
      case 'uranus':
        return Colors.cyan.shade600;
      case 'neptune':
        return Colors.blue.shade800;
      default:
        return Colors.orange;
    }
  }

  Color _getStarColor() {
    // Couleur basée sur la magnitude
    if (widget.object.magnitude < 0) {
      return Colors.white;
    } else if (widget.object.magnitude < 2) {
      return Colors.yellow.shade100;
    } else if (widget.object.magnitude < 4) {
      return Colors.blue.shade100;
    } else {
      return Colors.red.shade100;
    }
  }

  Gradient? _getObjectGradient() {
    switch (widget.object.type) {
      case CelestialObjectType.sun:
        return RadialGradient(
          colors: [
            Colors.yellow.shade200,
            Colors.orange.shade600,
            Colors.red.shade700,
          ],
        );
      case CelestialObjectType.moon:
        return RadialGradient(
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade400,
            Colors.grey.shade600,
          ],
        );
      case CelestialObjectType.planet:
        final baseColor = _getPlanetColor();
        return RadialGradient(
          colors: [
            baseColor.withOpacity(0.7),
            baseColor,
            baseColor.withOpacity(0.8),
          ],
        );
      default:
        return null;
    }
  }
}

// Painter personnalisé pour dessiner les constellations
class ConstellationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.shade300
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    // Dessiner un motif d'étoiles connectées
    final points = [
      Offset(center.dx - radius, center.dy - radius),
      Offset(center.dx + radius, center.dy - radius),
      Offset(center.dx + radius, center.dy + radius),
      Offset(center.dx - radius, center.dy + radius),
      Offset(center.dx, center.dy),
    ];

    // Connecter les points
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }

    // Dessiner des étoiles aux points de connexion
    final starPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point, 2, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}