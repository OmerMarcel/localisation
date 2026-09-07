import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Écran interactif permettant de zoomer, déplacer, pivoter et cadrer son visage
/// avant d'enregistrer la photo comme photo de profil.
class FaceCropScreen extends StatefulWidget {
  final File imageFile;

  const FaceCropScreen({
    super.key,
    required this.imageFile,
  });

  @override
  State<FaceCropScreen> createState() => _FaceCropScreenState();
}

class _FaceCropScreenState extends State<FaceCropScreen> {
  final GlobalKey _cropKey = GlobalKey();
  final TransformationController _transformController = TransformationController();

  double _currentScale = 1.0;
  int _rotationQuarter = 0; // 0, 1, 2, 3 (* 90 degrés)
  bool _isExporting = false;
  bool _showGuidelines = true;

  static const double _minScale = 1.0;
  static const double _maxScale = 4.0;
  static const double _cropSize = 280.0; // Taille de la fenêtre de recadrage

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformationChanged);
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformationChanged);
    _transformController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    final Matrix4 matrix = _transformController.value;
    final double scale = matrix.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.01) {
      setState(() {
        _currentScale = scale.clamp(_minScale, _maxScale);
      });
    }
  }

  void _setZoom(double targetScale) {
    targetScale = targetScale.clamp(_minScale, _maxScale);
    final Matrix4 newMatrix = Matrix4.diagonal3Values(targetScale, targetScale, 1.0);
    _transformController.value = newMatrix;
    setState(() {
      _currentScale = targetScale;
    });
  }

  void _rotateClockwise() {
    setState(() {
      _rotationQuarter = (_rotationQuarter + 1) % 4;
    });
  }

  void _rotateCounterClockwise() {
    setState(() {
      _rotationQuarter = (_rotationQuarter + 3) % 4;
    });
  }

  void _resetTransform() {
    setState(() {
      _rotationQuarter = 0;
      _currentScale = 1.0;
      _transformController.value = Matrix4.identity();
    });
  }

  Future<void> _exportCroppedImage() async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      // Petite pause pour s'assurer du rendu complet
      await Future.delayed(const Duration(milliseconds: 100));

      final RenderRepaintBoundary? boundary =
          _cropKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('Impossible de capturer l\'image');
      }

      // Capture en haute résolution (pixelRatio: 3.0 => ~840x840 px)
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Échec de la conversion de l\'image');
      }

      final pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final File croppedFile = File('${tempDir.path}/profile_avatar_$timestamp.png');

      await croppedFile.writeAsBytes(pngBytes);

      if (mounted) {
        Navigator.pop(context, croppedFile);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du recadrage : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900 sombre et moderne
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ajuster votre visage',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Pincez ou utilisez le zoom pour centrer',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _showGuidelines ? 'Masquer les repères' : 'Afficher les repères',
            icon: Icon(
              _showGuidelines ? Icons.grid_on : Icons.grid_off,
              color: _showGuidelines ? AppColors.accent : Colors.white60,
            ),
            onPressed: () {
              setState(() {
                _showGuidelines = !_showGuidelines;
              });
            },
          ),
          IconButton(
            tooltip: 'Réinitialiser',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _resetTransform,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Zone centrale avec la fenêtre de recadrage circulaire
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // RepaintBoundary pour extraire le rendu exact
                    RepaintBoundary(
                      key: _cropKey,
                      child: ClipOval(
                        child: Container(
                          width: _cropSize,
                          height: _cropSize,
                          color: Colors.black,
                          child: InteractiveViewer(
                            transformationController: _transformController,
                            minScale: _minScale,
                            maxScale: _maxScale,
                            panEnabled: true,
                            scaleEnabled: true,
                            boundaryMargin: const EdgeInsets.all(double.infinity),
                            clipBehavior: Clip.none,
                            child: RotatedBox(
                              quarterTurns: _rotationQuarter,
                              child: Image.file(
                                widget.imageFile,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.white54,
                                      size: 50,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Masque et repères visuels par dessus
                    IgnorePointer(
                      child: CustomPaint(
                        size: const Size(_cropSize + 40, _cropSize + 40),
                        painter: _CircleCropOverlayPainter(
                          radius: _cropSize / 2,
                          showGuidelines: _showGuidelines,
                          primaryColor: AppColors.primary,
                          accentColor: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Panneau de contrôle inférieur
            _buildControlsPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barre de contrôle du zoom avec slider et boutons rapides
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.zoom_out, color: Colors.white70),
                onPressed: () => _setZoom(_currentScale - 0.25),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: AppColors.accent,
                    overlayColor: AppColors.accent.withOpacity(0.2),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _currentScale,
                    min: _minScale,
                    max: _maxScale,
                    onChanged: (value) => _setZoom(value),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in, color: Colors.white70),
                onPressed: () => _setZoom(_currentScale + 0.25),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(_currentScale * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Barre d'outils (Rotation gauche, Rotation droite, Réinitialiser)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildToolButton(
                icon: Icons.rotate_left,
                label: 'Pivoter G.',
                onTap: _rotateCounterClockwise,
              ),
              _buildToolButton(
                icon: Icons.rotate_right,
                label: 'Pivoter D.',
                onTap: _rotateClockwise,
              ),
              _buildToolButton(
                icon: Icons.center_focus_strong,
                label: 'Centrer',
                onTap: _resetTransform,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Bouton principal de confirmation / validation
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isExporting ? null : _exportCroppedImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isExporting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Ajustement en cours...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Valider la photo de profil',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Peintre personnalisé pour afficher le cercle de cadrage, le contour lumineux
/// et la grille d'alignement pour cadrer le visage avec précision.
class _CircleCropOverlayPainter extends CustomPainter {
  final double radius;
  final bool showGuidelines;
  final Color primaryColor;
  final Color accentColor;

  _CircleCropOverlayPainter({
    required this.radius,
    required this.showGuidelines,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Cercle bordure extérieure
    final ringPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(center, radius, ringPaint);

    // 2. Halo lumineux extérieur
    final glowPaint = Paint()
      ..color = accentColor.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, radius + 2, glowPaint);

    // 3. Repères de grille / ovale pour aligner les yeux et le menton
    if (showGuidelines) {
      // Repère circulaire intérieur doux
      final innerGuidePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawCircle(center, radius * 0.65, innerGuidePaint);

      // Repères en croix aux 4 points cardinaux
      final tickPaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      const double tickLen = 12.0;

      // Haut
      canvas.drawLine(
        Offset(center.dx, center.dy - radius - 4),
        Offset(center.dx, center.dy - radius + tickLen),
        tickPaint,
      );
      // Bas
      canvas.drawLine(
        Offset(center.dx, center.dy + radius + 4),
        Offset(center.dx, center.dy + radius - tickLen),
        tickPaint,
      );
      // Gauche
      canvas.drawLine(
        Offset(center.dx - radius - 4, center.dy),
        Offset(center.dx - radius + tickLen, center.dy),
        tickPaint,
      );
      // Droite
      canvas.drawLine(
        Offset(center.dx + radius + 4, center.dy),
        Offset(center.dx + radius - tickLen, center.dy),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircleCropOverlayPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.showGuidelines != showGuidelines ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor;
  }
}
