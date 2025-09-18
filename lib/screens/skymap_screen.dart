// ignore_for_file: deprecated_member_use

import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skymap/widgets/celestial_object_details.dart';
import '../bloc/skymap/skymap_bloc.dart';
import '../bloc/skymap/skymap_event.dart';
import '../bloc/skymap/skymap_state.dart';
import '../models/celestial_object.dart';
import '../utils/astronomy_utils.dart';
import '../widgets/celestial_object_widget.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SkymapScreen extends StatefulWidget {
  const SkymapScreen({super.key});

  @override
  State<SkymapScreen> createState() => _SkymapScreenState();
}

class _SkymapScreenState extends State<SkymapScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _fadeController;
  Timer? _updateTimer;
  String _statusMessage = 'Initialisation...';
  bool _showUI = true;

  // Add position smoothing with increased smoothing factor
  final Map<String, Offset> _smoothedPositions = {};
  static const int _smoothingFactor = 15;

  // Add a debounce timer to prevent too frequent updates
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Check location permission only if not on web
      if (!kIsWeb) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          setState(
            () => _statusMessage = 'Demande d\'autorisation de localisation...',
          );
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            setState(() => _statusMessage = 'Autorisation de localisation refusée');
            _initializeWithoutLocation();
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          setState(
            () =>
                _statusMessage =
                    'Autorisation de localisation définitivement refusée',
          );
          _initializeWithoutLocation();
          return;
        }

        // Check if location services are enabled
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          setState(() => _statusMessage = 'Services de localisation désactivés');
          _initializeWithoutLocation();
          return;
        }
      }

      setState(() => _statusMessage = 'Obtention de la position...');

      // Initialize the app with screen dimensions
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final size = MediaQuery.of(context).size;
          context.read<SkymapBloc>().add(
            InitializeSkymap(screenWidth: size.width, screenHeight: size.height),
          );
        }
      });
    } catch (e) {
      print('Error during initialization: $e');
      _initializeWithoutLocation();
    }
  }

  void _initializeWithoutLocation() {
    setState(() => _statusMessage = 'Initialisation sans localisation...');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final size = MediaQuery.of(context).size;
        context.read<SkymapBloc>().add(
          InitializeSkymap(screenWidth: size.width, screenHeight: size.height),
        );
      }
    });
  }

  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
    });
    if (_showUI) {
      _fadeController.forward();
    } else {
      _fadeController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fadeController.dispose();
    _updateTimer?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: BlocBuilder<SkymapBloc, SkymapState>(
        builder: (context, state) {
          if (state.isLoading) {
            return _buildLoadingScreen();
          }

          if (state.error != null) {
            return _buildErrorScreen(state.error!);
          }

          // Start update timer
          _updateTimer?.cancel();
          _updateTimer = Timer.periodic(const Duration(milliseconds: 1000), (
            _,
          ) {
            if (mounted) {
              setState(() {});
            }
          });

          return GestureDetector(
            onTap: _toggleUI,
            child: Stack(
              children: [
                // Enhanced background with gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.5,
                      colors: [
                        Color(0xFF1A1A3A),
                        Color(0xFF0A0A1A),
                        Color(0xFF000000),
                      ],
                    ),
                  ),
                ),

                // Background stars with twinkling effect
                _buildEnhancedStarBackground(),

                // Grid overlay (optional)
                if (_showUI) _buildGridOverlay(),

                // Celestial objects
                ...state.celestialObjects.map((object) {
                  final rawPosition = _calculateObjectPosition(
                    object,
                    state.location,
                    state.accelerometerData,
                    state.magnetometerData,
                    state.screenWidth,
                    state.screenHeight,
                  );

                  final smoothedPosition = _getSmoothedPosition(
                    object.id,
                    rawPosition,
                  );

                  return Positioned(
                    left: smoothedPosition.dx - _calculateObjectSize(object, state.screenWidth) / 2,
                    top: smoothedPosition.dy - _calculateObjectSize(object, state.screenWidth) / 2,
                    child: CelestialObjectWidget(
                      object: object,
                      x: 0, // Position géré par Positioned
                      y: 0, // Position géré par Positioned
                      size: _calculateObjectSize(object, state.screenWidth),
                      onTap: () {
                        _debounceTimer?.cancel();
                        _debounceTimer = Timer(_debounceDuration, () {
                          context.read<SkymapBloc>().add(
                            SelectCelestialObject(object),
                          );
                        });
                      },
                    ),
                  );
                }),

                // UI Panels - Wrapped in SafeArea and properly positioned
                ..._buildUIElements(state),

                // Selected object details
                if (state.selectedObject != null)
                  CelestialObjectDetails(
                    object: state.selectedObject!,
                    onClose: () {
                      context.read<SkymapBloc>().add(DeselectCelestialObject());
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildUIElements(SkymapState state) {
    if (!_showUI) {
      return [
        // UI toggle hint
        Positioned(
          bottom: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            child: const Text(
              'Toucher pour afficher l\'interface',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ),
      ];
    }

    return [
      // Top UI Panel
      _buildTopPanel(state),
      // Bottom UI Panel with compass
      _buildBottomPanel(state),
      // Side panel with object types
      _buildSidePanel(),
    ];
  }

  Widget _buildLoadingScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0xFF1A1A3A), Color(0xFF000000)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.blue.shade300),
                    ),
                  ),
                  const Center(
                    child: Icon(Icons.explore, color: Colors.white, size: 32),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sky Map',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _statusMessage,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0xFF1A1A3A), Color(0xFF000000)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 64),
            const SizedBox(height: 24),
            const Text(
              'Erreur',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeApp,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPanel(SkymapState state) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _fadeController,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.8), Colors.transparent],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // App title
                  Row(
                    children: [
                      Icon(
                        Icons.explore,
                        color: Colors.blue.shade300,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Sky Map',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Action buttons
                  Row(
                    children: [
                      _buildActionButton(Icons.search, () {}),
                      const SizedBox(width: 8),
                      _buildActionButton(Icons.visibility, () {}),
                      const SizedBox(width: 8),
                      _buildActionButton(Icons.photo, () {}),
                      const SizedBox(width: 8),
                      _buildActionButton(Icons.settings, () {}),
                      const SizedBox(width: 8),
                      _buildActionButton(Icons.more_vert, () {}),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel(SkymapState state) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _fadeController,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withOpacity(0.8), Colors.transparent],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Compass
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                          ),
                        ),
                        const Center(
                          child: Icon(
                            Icons.navigation,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                        const Positioned(
                          top: 8,
                          left: 0,
                          right: 0,
                          child: Text(
                            'N',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Direction indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'OUEST',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Time info
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidePanel() {
    return Positioned(
      left: 16,
      top: 120,
      child: FadeTransition(
        opacity: _fadeController,
        child: Container(
          width: 60,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSideButton(Icons.wb_sunny, Colors.yellow, true),
              _buildSideButton(Icons.brightness_3, Colors.grey, false),
              _buildSideButton(Icons.public, Colors.orange, false),
              _buildSideButton(Icons.star, Colors.white, false),
              _buildSideButton(Icons.grid_on, Colors.blue, false),
              _buildSideButton(Icons.blur_on, Colors.green, false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildSideButton(IconData icon, Color color, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.2) : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? color : Colors.white.withOpacity(0.3),
              width: isActive ? 2 : 1,
            ),
          ),
          child: Icon(icon, color: isActive ? color : Colors.white70, size: 24),
        ),
      ),
    );
  }

  Widget _buildEnhancedStarBackground() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return CustomPaint(
          painter: EnhancedStarBackgroundPainter(_animationController.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildGridOverlay() {
    return CustomPaint(painter: GridOverlayPainter(), size: Size.infinite);
  }

  // Rest of your existing methods remain the same...
  Offset _getSmoothedPosition(String objectId, Offset newPosition) {
    if (!_smoothedPositions.containsKey(objectId)) {
      _smoothedPositions[objectId] = newPosition;
      return newPosition;
    }

    final currentPosition = _smoothedPositions[objectId]!;
    final distance = (newPosition - currentPosition).distance;

    if (distance < 1.0) {
      return currentPosition;
    }

    final smoothingFactor =
        distance > 50.0 ? _smoothingFactor * 2 : _smoothingFactor;

    final smoothedX =
        currentPosition.dx +
        (newPosition.dx - currentPosition.dx) / smoothingFactor;
    final smoothedY =
        currentPosition.dy +
        (newPosition.dy - currentPosition.dy) / smoothingFactor;

    final smoothedPosition = Offset(smoothedX, smoothedY);
    _smoothedPositions[objectId] = smoothedPosition;

    return smoothedPosition;
  }

  Offset _calculateObjectPosition(
    CelestialObject object,
    Position? location,
    UserAccelerometerEvent? accelerometerData,
    MagnetometerEvent? magnetometerData,
    double screenWidth,
    double screenHeight,
  ) {
    if (location == null) {
      final random = Random(object.id.hashCode);
      final x = random.nextDouble() * screenWidth;
      final y = random.nextDouble() * screenHeight;
      return Offset(x, y);
    }

    try {
      return AstronomyUtils.calculateScreenPosition(
        object,
        location,
        accelerometerData,
        magnetometerData,
        screenWidth,
        screenHeight,
      );
    } catch (e) {
      // Fallback en cas d'erreur
      final random = Random(object.id.hashCode);
      final x = random.nextDouble() * screenWidth;
      final y = random.nextDouble() * screenHeight;
      return Offset(x, y);
    }
  }

  double _calculateObjectSize(CelestialObject object, double screenWidth) {
    switch (object.type) {
      case CelestialObjectType.sun:
        return screenWidth * 0.1;
      case CelestialObjectType.moon:
        return screenWidth * 0.08;
      case CelestialObjectType.planet:
        return screenWidth * 0.05;
      case CelestialObjectType.star:
        return screenWidth * 0.02;
      case CelestialObjectType.constellation:
        return screenWidth * 0.15;
    }
  }
}

class EnhancedStarBackgroundPainter extends CustomPainter {
  final double animationValue;

  EnhancedStarBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    final paint = Paint();

    // Draw stars with twinkling effect
    for (int i = 0; i < 300; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final baseRadius = random.nextDouble() * 2 + 0.5;

      // Twinkling effect
      final twinkle = sin((animationValue * 2 * pi) + (i * 0.1)) * 0.5 + 0.5;
      final radius = baseRadius * (0.7 + twinkle * 0.3);
      final opacity = 0.3 + twinkle * 0.7;

      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GridOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..strokeWidth = 0.5;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += size.width / 8) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += size.height / 8) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}