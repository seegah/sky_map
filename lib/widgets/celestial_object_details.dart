// celestial_object_details.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../models/celestial_object.dart';

class CelestialObjectDetails extends StatelessWidget {
  final CelestialObject object;
  final VoidCallback onClose;
  const CelestialObjectDetails({
    super.key,
    required this.object,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fond transparent qui gère le clic extérieur
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onClose,
          child: Container(
            color: Colors.transparent,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        // Contenu principal
        Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.95),
                  _getObjectColor().withOpacity(0.1),
                  Colors.black.withOpacity(0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getObjectColor(),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getObjectColor().withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec nom et bouton de fermeture
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              object.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: _getObjectColor(),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getObjectColor().withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _getObjectColor(),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _getObjectTypeName(),
                                style: TextStyle(
                                  color: _getObjectColor(),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Bouton X
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            onClose();
                          },
                          borderRadius: BorderRadius.circular(25),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Informations techniques dans des cartes
                  _buildInfoCard(
                    icon: Icons.location_on,
                    title: "Coordonnées",
                    children: [
                      _buildInfoRow(
                        "Ascension droite",
                        "${object.rightAscension.toStringAsFixed(2)}h"
                      ),
                      _buildInfoRow(
                        "Déclinaison",
                        "${object.declination.toStringAsFixed(2)}°"
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    icon: Icons.star,
                    title: "Caractéristiques",
                    children: [
                      _buildInfoRow(
                        "Magnitude",
                        object.magnitude.toStringAsFixed(2)
                      ),
                      _buildInfoRow(
                        "Taille",
                        "${object.size.toStringAsFixed(2)} km"
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Description
                  if (object.description.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: _getObjectColor(),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Description",
                                style: TextStyle(
                                  color: _getObjectColor(),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            object.description,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Bouton de fermeture en bas
                  Center(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          onClose();
                        },
                        borderRadius: BorderRadius.circular(25),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _getObjectColor().withOpacity(0.2),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: _getObjectColor(),
                            ),
                          ),
                          child: const Text(
                            "Fermer",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: _getObjectColor(),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: _getObjectColor(),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getObjectTypeName() {
    switch (object.type) {
      case CelestialObjectType.sun:
        return 'Soleil';
      case CelestialObjectType.moon:
        return 'Lune';
      case CelestialObjectType.planet:
        return 'Planète';
      case CelestialObjectType.star:
        return 'Étoile';
      case CelestialObjectType.constellation:
        return 'Constellation';
    }
  }

  Color _getObjectColor() {
    switch (object.type) {
      case CelestialObjectType.sun:
        return Colors.yellow;
      case CelestialObjectType.moon:
        return Colors.grey.shade300;
      case CelestialObjectType.planet:
        return Colors.orange;
      case CelestialObjectType.star:
        return Colors.white;
      case CelestialObjectType.constellation:
        return Colors.blue.shade300;
    }
  }
}