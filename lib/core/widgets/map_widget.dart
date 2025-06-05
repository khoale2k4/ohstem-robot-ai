import 'package:flutter/material.dart';
import 'package:robot_ai/services/navigation_service.dart';

class MapWidget extends StatelessWidget {
  final List<MapPoint> exploredPoints;
  final List<Obstacle> obstacles;
  final MapPoint? currentPosition;
  final MapPoint? targetPosition;
  final Function(MapPoint)? onMapTap;

  const MapWidget({
    Key? key,
    required this.exploredPoints,
    required this.obstacles,
    this.currentPosition,
    this.targetPosition,
    this.onMapTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          onTapDown: (details) {
            if (onMapTap != null) {
              final box = context.findRenderObject() as RenderBox;
              final localPosition = box.globalToLocal(details.globalPosition);
              _handleMapTap(localPosition, box.size);
            }
          },
          child: CustomPaint(
            painter: MapPainter(
              exploredPoints: exploredPoints,
              obstacles: obstacles,
              currentPosition: currentPosition,
              targetPosition: targetPosition,
            ),
            child: Container(),
          ),
        ),
      ),
    );
  }

  void _handleMapTap(Offset localPosition, Size size) {
    // Convert screen coordinates to map coordinates
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = 1.0; // Adjust scale as needed

    final mapX = (localPosition.dx - centerX) / scale;
    final mapY = (localPosition.dy - centerY) / scale;

    final mapPoint = MapPoint(
      x: mapX,
      y: mapY,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    onMapTap?.call(mapPoint);
  }
}

class MapPainter extends CustomPainter {
  final List<MapPoint> exploredPoints;
  final List<Obstacle> obstacles;
  final MapPoint? currentPosition;
  final MapPoint? targetPosition;

  MapPainter({
    required this.exploredPoints,
    required this.obstacles,
    this.currentPosition,
    this.targetPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = 1.0; // Adjust scale for zoom

    // Draw grid
    _drawGrid(canvas, size, centerX, centerY, scale);

    // Draw explored path
    _drawExploredPath(canvas, centerX, centerY, scale);

    // Draw obstacles
    _drawObstacles(canvas, centerX, centerY, scale);

    // Draw target position
    if (targetPosition != null) {
      _drawTarget(canvas, centerX, centerY, scale);
    }

    // Draw current position (robot)
    if (currentPosition != null) {
      _drawRobot(canvas, centerX, centerY, scale);
    }

    // Draw legend
    _drawLegend(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size, double centerX, double centerY, double scale) {
    final paint = Paint()
      ..color = Colors.grey[800]!
      ..strokeWidth = 0.5;

    // Draw grid lines
    final gridSpacing = 20.0 * scale;
    
    // Vertical lines
    for (double x = centerX % gridSpacing; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    // Horizontal lines
    for (double y = centerY % gridSpacing; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw axes
    final axisPaint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 1;

    // X axis
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), axisPaint);
    // Y axis
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), axisPaint);
  }

  void _drawExploredPath(Canvas canvas, double centerX, double centerY, double scale) {
    if (exploredPoints.length < 2) return;

    final pathPaint = Paint()
      ..color = Colors.blue.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final path = Path();
    bool isFirstPoint = true;

    for (final point in exploredPoints) {
      final screenX = centerX + point.x * scale;
      final screenY = centerY + point.y * scale;

      if (isFirstPoint) {
        path.moveTo(screenX, screenY);
        isFirstPoint = false;
      } else {
        path.lineTo(screenX, screenY);
      }

      // Draw point
      canvas.drawCircle(Offset(screenX, screenY), 1, pointPaint);
    }

    canvas.drawPath(path, pathPaint);
  }

  void _drawObstacles(Canvas canvas, double centerX, double centerY, double scale) {
    final obstaclePaint = Paint()
      ..color = Colors.red.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    for (final obstacle in obstacles) {
      final screenX = centerX + obstacle.x * scale;
      final screenY = centerY + obstacle.y * scale;
      final radius = obstacle.radius * scale;

      canvas.drawCircle(Offset(screenX, screenY), radius, obstaclePaint);
    }
  }

  void _drawRobot(Canvas canvas, double centerX, double centerY, double scale) {
    final screenX = centerX + currentPosition!.x * scale;
    final screenY = centerY + currentPosition!.y * scale;

    // Robot body
    final robotPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(screenX, screenY), 8, robotPaint);

    // Robot direction indicator
    final directionPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(screenX, screenY),
      Offset(screenX, screenY - 10),
      directionPaint,
    );

    // Robot outline
    final outlinePaint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(screenX, screenY), 8, outlinePaint);
  }

  void _drawTarget(Canvas canvas, double centerX, double centerY, double scale) {
    final screenX = centerX + targetPosition!.x * scale;
    final screenY = centerY + targetPosition!.y * scale;

    // Target outer circle
    final targetPaint = Paint()
      ..color = Colors.orange.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(screenX, screenY), 12, targetPaint);

    // Target cross
    final crossPaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(screenX - 8, screenY),
      Offset(screenX + 8, screenY),
      crossPaint,
    );
    canvas.drawLine(
      Offset(screenX, screenY - 8),
      Offset(screenX, screenY + 8),
      crossPaint,
    );

    // Target outline
    final outlinePaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(screenX, screenY), 12, outlinePaint);
  }

  void _drawLegend(Canvas canvas, Size size) {
    final legendPaint = Paint()
      ..color = Colors.black.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final legendRect = Rect.fromLTWH(10, 10, 120, 80);
    canvas.drawRRect(
      RRect.fromRectAndRadius(legendRect, const Radius.circular(8)),
      legendPaint,
    );

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Legend items
    final legendItems = [
      {'color': Colors.green, 'text': 'Robot'},
      {'color': Colors.orange, 'text': 'Target'},
      {'color': Colors.blue, 'text': 'Path'},
      {'color': Colors.red, 'text': 'Obstacle'},
    ];

    double y = 20;
    for (final item in legendItems) {
      // Color indicator
      final colorPaint = Paint()
        ..color = item['color'] as Color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(20, y), 4, colorPaint);

      // Text
      textPainter.text = TextSpan(
        text: item['text'] as String,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(30, y - 5));

      y += 15;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 