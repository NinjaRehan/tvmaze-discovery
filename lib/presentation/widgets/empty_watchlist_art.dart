import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

/// Code-drawn artwork: stays crisp at every screen size and needs no download.
class EmptyWatchlistArt extends StatelessWidget {
  const EmptyWatchlistArt({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'An open purple box with a heart',
    image: true,
    child: const SizedBox(
      width: 190,
      height: 180,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _BoxPainter())),
          Positioned(
            top: 0,
            left: 67,
            child: Icon(
              Icons.favorite_rounded,
              size: 56,
              color: AppTheme.purple,
            ),
          ),
        ],
      ),
    ),
  );
}

class _BoxPainter extends CustomPainter {
  const _BoxPainter();
  @override
  void paint(Canvas canvas, Size size) {
    void face(List<Offset> points, Color color) {
      final path = Path()
        ..moveTo(points.first.dx * size.width, points.first.dy * size.height);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx * size.width, point.dy * size.height);
      }
      canvas.drawPath(path..close(), Paint()..color = color);
    }

    face(const [
      Offset(.25, .47),
      Offset(.5, .57),
      Offset(.5, .95),
      Offset(.25, .82),
    ], const Color(0xFF7743D5));
    face(const [
      Offset(.5, .57),
      Offset(.75, .47),
      Offset(.75, .82),
      Offset(.5, .95),
    ], const Color(0xFF5329A4));
    face(const [
      Offset(.25, .47),
      Offset(.5, .35),
      Offset(.75, .47),
      Offset(.5, .6),
    ], const Color(0xFF45257E));
    face(const [
      Offset(.1, .48),
      Offset(.35, .32),
      Offset(.5, .46),
      Offset(.3, .63),
    ], const Color(0xFFA47BFF));
    face(const [
      Offset(.5, .46),
      Offset(.65, .32),
      Offset(.9, .48),
      Offset(.7, .63),
    ], const Color(0xFF8755EF));
    final rays = Paint()
      ..color = const Color(0xFFC3A2FF)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final pair in [
      [const Offset(.13, .2), const Offset(.18, .22)],
      [const Offset(.24, .03), const Offset(.26, .07)],
      [const Offset(.75, .03), const Offset(.73, .07)],
      [const Offset(.82, .22), const Offset(.87, .2)],
    ]) {
      canvas.drawLine(
        Offset(pair[0].dx * size.width, pair[0].dy * size.height),
        Offset(pair[1].dx * size.width, pair[1].dy * size.height),
        rays,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BoxPainter oldDelegate) => false;
}
