import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';
import '../../core/models/infrastructure.dart';
import '../../core/services/directions_service.dart';
import '../../core/services/google_maps_service.dart';
import '../../core/services/voice_guidance_service.dart';

class RouteScreen extends ConsumerStatefulWidget {
  final Infrastructure destination;
  final Position? currentPosition;
  final TravelMode travelMode;

  const RouteScreen({
    super.key,
    required this.destination,
    this.currentPosition,
    this.travelMode = TravelMode.driving,
  });

  @override
  ConsumerState<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends ConsumerState<RouteScreen> {
  GoogleMapController? _mapController;
  DirectionsResult? _directionsResult;
  bool _isLoading = true;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _showSteps = false;

  @override
  void initState() {
    super.initState();
    VoiceGuidanceService().addListener(_onVoiceGuidanceUpdate);
    _loadDirections();
    _setupMarkers();
  }

  @override
  void dispose() {
    VoiceGuidanceService().removeListener(_onVoiceGuidanceUpdate);
    VoiceGuidanceService().stopNavigation();
    super.dispose();
  }

  void _onVoiceGuidanceUpdate() {
    if (mounted) {
      setState(() {});
      final lastPos = VoiceGuidanceService().lastPosition;
      if (lastPos != null &&
          VoiceGuidanceService().isNavigating &&
          _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(lastPos.latitude, lastPos.longitude),
              zoom: 17.5,
              tilt: 45.0, // Perspective 3D immersive pour la navigation
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadDirections() async {
    if (widget.currentPosition == null) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Position actuelle non disponible'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      print('🚀 Chargement des directions...');

      final origin = LatLng(
        widget.currentPosition!.latitude,
        widget.currentPosition!.longitude,
      );
      final destination = LatLng(
        widget.destination.latitude,
        widget.destination.longitude,
      );

      print('📍 Origine: ${origin.latitude}, ${origin.longitude}');
      print(
        '🎯 Destination: ${destination.latitude}, ${destination.longitude}',
      );

      final directions = await DirectionsService.getDirections(
        origin: origin,
        destination: destination,
        travelMode: _getTravelModeString(widget.travelMode),
      );

      if (directions != null) {
        print('✅ Directions reçues avec succès!');
        setState(() {
          _directionsResult = directions;
        });
        _setupPolyline(directions);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Itinéraire calculé: ${directions.distance}, ${directions.duration}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('❌ Aucune direction reçue');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Impossible de calculer l\'itinéraire. Vérifiez votre connexion internet.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('💥 Erreur lors du chargement des directions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getTravelModeString(TravelMode mode) {
    switch (mode) {
      case TravelMode.driving:
        return 'DRIVING';
      case TravelMode.walking:
        return 'WALKING';
      case TravelMode.bicycling:
        return 'BICYCLING';
      case TravelMode.transit:
        return 'TRANSIT';
    }
  }

  void _setupMarkers() {
    final markers = <Marker>{};

    // Marqueur de départ
    if (widget.currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('origin'),
          position: LatLng(
            widget.currentPosition!.latitude,
            widget.currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(
            title: 'Départ',
            snippet: 'Votre position',
          ),
        ),
      );
    }

    // Marqueur de destination
    markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(
          widget.destination.latitude,
          widget.destination.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: widget.destination.name,
          snippet: widget.destination.category,
        ),
      ),
    );

    setState(() {
      _markers = markers;
    });
  }

  void _setupPolyline(DirectionsResult directions) {
    print(
      '🎨 Configuration de la polyline avec ${directions.polylinePoints.length} points',
    );

    if (directions.polylinePoints.isEmpty) {
      print('⚠️ Aucun point de polyline disponible');
      return;
    }

    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      points: directions.polylinePoints,
      color: _getPolylineColor(widget.travelMode),
      width: 5,
      patterns: widget.travelMode == TravelMode.walking
          ? [PatternItem.dash(10), PatternItem.gap(5)]
          : [],
    );

    print(
      '✨ Polyline créée avec couleur: ${_getPolylineColor(widget.travelMode)}',
    );

    setState(() {
      _polylines = {polyline};
    });

    // Ajuster la caméra pour afficher tout l'itinéraire
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitMapToRoute(directions.polylinePoints);
    });
  }

  Color _getPolylineColor(TravelMode mode) {
    switch (mode) {
      case TravelMode.driving:
        return Colors.blue;
      case TravelMode.walking:
        return Colors.green;
      case TravelMode.bicycling:
        return Colors.orange;
      case TravelMode.transit:
        return Colors.purple;
    }
  }

  void _fitMapToRoute(List<LatLng> points) {
    if (points.isEmpty || _mapController == null) {
      print(
        '⚠️ Impossible d\'ajuster la caméra: points vides ou contrôleur null',
      );
      return;
    }

    print('📷 Ajustement de la caméra pour ${points.length} points');

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    print(
      '🗺️ Limites calculées: SW(${minLat}, ${minLng}) - NE(${maxLat}, ${maxLng})',
    );

    try {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
      print('✅ Caméra ajustée avec succès');
    } catch (e) {
      print('❌ Erreur lors de l\'ajustement de la caméra: $e');
      // Fallback: centrer sur le premier point
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, 14.0),
      );
    }
  }

  IconData _getTravelModeIcon(TravelMode mode) {
    switch (mode) {
      case TravelMode.driving:
        return Icons.directions_car;
      case TravelMode.walking:
        return Icons.directions_walk;
      case TravelMode.bicycling:
        return Icons.directions_bike;
      case TravelMode.transit:
        return Icons.directions_transit;
    }
  }

  String _getTravelModeLabel(TravelMode mode) {
    switch (mode) {
      case TravelMode.driving:
        return 'En voiture';
      case TravelMode.walking:
        return 'À pied';
      case TravelMode.bicycling:
        return 'À vélo';
      case TravelMode.transit:
        return 'Transport public';
    }
  }

  IconData _getManeuverIcon(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('droite')) return Icons.turn_right;
    if (lower.contains('gauche')) return Icons.turn_left;
    if (lower.contains('demi-tour') || lower.contains('uturn')) {
      return Icons.u_turn_left;
    }
    if (lower.contains('rond-point') || lower.contains('sortie')) {
      return Icons.roundabout_right;
    }
    if (lower.contains('arrivé') || lower.contains('destination')) {
      return Icons.flag;
    }
    return Icons.straight;
  }

  void _startGuidance() {
    if (_directionsResult == null || widget.currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de démarrer : itinéraire ou position manquante'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    VoiceGuidanceService().startNavigation(
      _directionsResult!,
      widget.currentPosition!,
    );
  }

  void _stopGuidance() {
    VoiceGuidanceService().stopNavigation();
    if (_directionsResult != null &&
        _directionsResult!.polylinePoints.isNotEmpty) {
      _fitMapToRoute(_directionsResult!.polylinePoints);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vg = VoiceGuidanceService();
    final isNavigating = vg.isNavigating;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isNavigating ? 'Guidage en cours...' : 'Itinéraire vers ${widget.destination.name}',
        ),
        backgroundColor: isNavigating ? const Color(0xFF0F172A) : AppColors.primary,
        foregroundColor: AppColors.textLight,
        actions: [
          if (isNavigating)
            IconButton(
              icon: Icon(vg.isMuted ? Icons.volume_off : Icons.volume_up),
              tooltip: vg.isMuted ? 'Activer la voix' : 'Couper la voix',
              onPressed: () => vg.toggleMute(),
            ),
          IconButton(
            icon: Icon(_showSteps ? Icons.map : Icons.list),
            onPressed: () {
              setState(() {
                _showSteps = !_showSteps;
              });
            },
            tooltip: _showSteps ? 'Voir la carte' : 'Voir les étapes',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : Column(
              children: [
                // Panneau d'informations & contrôle
                Container(
                  padding: EdgeInsets.all(AppDimensions.spacingM),
                  decoration: BoxDecoration(
                    color: isNavigating ? const Color(0xFF1E293B) : AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getTravelModeIcon(widget.travelMode),
                        color: isNavigating ? const Color(0xFF10B981) : AppColors.primary,
                        size: 32,
                      ),
                      SizedBox(width: AppDimensions.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isNavigating
                                  ? 'Navigation active (${_getTravelModeLabel(widget.travelMode)})'
                                  : _getTravelModeLabel(widget.travelMode),
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isNavigating ? Colors.white : null,
                              ),
                            ),
                            if (_directionsResult != null) ...[
                              SizedBox(height: AppDimensions.spacingXs),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: isNavigating
                                        ? const Color(0xFF10B981)
                                        : AppColors.textSecondary,
                                  ),
                                  SizedBox(width: AppDimensions.spacingXs),
                                  Text(
                                    isNavigating
                                        ? vg.remainingDuration
                                        : _directionsResult!.duration,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: isNavigating ? FontWeight.bold : null,
                                      color: isNavigating ? const Color(0xFF10B981) : null,
                                    ),
                                  ),
                                  SizedBox(width: AppDimensions.spacingM),
                                  Icon(
                                    Icons.straighten,
                                    size: 16,
                                    color: isNavigating
                                        ? const Color(0xFF94A3B8)
                                        : AppColors.textSecondary,
                                  ),
                                  SizedBox(width: AppDimensions.spacingXs),
                                  Text(
                                    isNavigating
                                        ? vg.remainingDistance
                                        : _directionsResult!.distance,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: isNavigating ? const Color(0xFFE2E8F0) : null,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!isNavigating)
                        ElevatedButton.icon(
                          onPressed: _startGuidance,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981), // Vert éclatant
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: AppDimensions.spacingM,
                              vertical: AppDimensions.spacingS,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.record_voice_over, size: 18),
                          label: const Text(
                            'Démarrer',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: _stopGuidance,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: AppDimensions.spacingM,
                              vertical: AppDimensions.spacingS,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.stop, size: 18),
                          label: const Text('Arrêter'),
                        ),
                    ],
                  ),
                ),

                // Contenu principal
                Expanded(
                  child: _showSteps ? _buildStepsList() : _buildMap(isNavigating),
                ),
              ],
            ),
    );
  }

  Widget _buildNavigationHUD() {
    final vg = VoiceGuidanceService();

    return Positioned(
      top: 14,
      left: 14,
      right: 14,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(
                _getManeuverIcon(vg.currentInstruction),
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    vg.currentInstruction.isNotEmpty
                        ? vg.currentInstruction
                        : 'Suivre l\'itinéraire',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Reste: ${vg.remainingDistance}',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('•', style: TextStyle(color: Color(0xFF64748B))),
                      const SizedBox(width: 8),
                      Text(
                        vg.remainingDuration,
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(bool isNavigating) {
    final initialPosition = widget.currentPosition != null
        ? LatLng(
            widget.currentPosition!.latitude,
            widget.currentPosition!.longitude,
          )
        : LatLng(widget.destination.latitude, widget.destination.longitude);

    return Stack(
      children: [
        GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            print('🗺️ Carte créée, configuration du contrôleur...');
            _mapController = controller;

            Future.delayed(const Duration(milliseconds: 500), () {
              if (_directionsResult != null &&
                  _directionsResult!.polylinePoints.isNotEmpty) {
                print('🔄 Ajustement de la caméra après création de la carte');
                _fitMapToRoute(_directionsResult!.polylinePoints);
              }
            });
          },
          initialCameraPosition: CameraPosition(
            target: initialPosition,
            zoom: isNavigating ? 17.5 : 15.0,
            tilt: isNavigating ? 45.0 : 0.0,
          ),
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: !isNavigating,
          mapType: MapType.normal,
          onTap: (LatLng position) {
            print(
              '👆 Clic sur la carte: ${position.latitude}, ${position.longitude}',
            );
          },
        ),
        if (isNavigating) _buildNavigationHUD(),
      ],
    );
  }

  Widget _buildStepsList() {
    if (_directionsResult == null || _directionsResult!.steps.isEmpty) {
      return const Center(child: Text('Aucune étape disponible'));
    }

    return ListView.builder(
      padding: EdgeInsets.all(AppDimensions.spacingM),
      itemCount: _directionsResult!.steps.length,
      itemBuilder: (context, index) {
        final step = _directionsResult!.steps[index];
        return Card(
          margin: EdgeInsets.only(bottom: AppDimensions.spacingS),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textLight,
              child: Text('${index + 1}'),
            ),
            title: Text(step.instruction, style: AppTextStyles.bodyMedium),
            subtitle: Row(
              children: [
                Icon(
                  Icons.straighten,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: AppDimensions.spacingXs),
                Text(step.distance),
                SizedBox(width: AppDimensions.spacingM),
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: AppDimensions.spacingXs),
                Text(step.duration),
              ],
            ),
            onTap: () {
              // Centrer la carte sur cette étape
              setState(() {
                _showSteps = false;
              });
              _mapController?.animateCamera(
                CameraUpdate.newLatLng(step.startLocation),
              );
            },
          ),
        );
      },
    );
  }
}
