// // import 'package:flutter/material.dart';
// //
// // void main() {
// //   runApp(MaterialApp(
// //     home: Scaffold(
// //       body: Center(
// //         child: FringedContainer(),
// //       ),
// //     ),
// //   ));
// // }
// //
// // class FringedContainer extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return ClipPath(
// //       clipper: FringeClipper(),
// //       child: Container(
// //         color: Colors.blue, // Your container color
// //         padding: const EdgeInsets.all(20),
// //         child: const Text(
// //           'Welcome to my shop!',
// //           style: TextStyle(color: Colors.white),
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // class FringeClipper extends CustomClipper<Path> {
// //   @override
// //   Path getClip(Size size) {
// //     Path path = Path();
// //     path.lineTo(0, size.height - 30); // Start slightly above the bottom
// //
// //     // Set the radius and spacing for the semicircles
// //     double fringeRadius =15; // Increased radius for deeper fringes
// //     double fringeSpacing = 25; // Adjusted spacing to make fringes sharper
// //
// //     // Create semicircles along the bottom edge
// //     for (double i = 0; i < size.width; i += fringeSpacing) {
// //       path.lineTo(i, size.height - 30); // Move to the bottom edge before adding the arc
// //       path.arcToPoint(
// //         Offset(i + fringeSpacing, size.height - 30), // Endpoint of the arc
// //         radius: Radius.circular(fringeRadius), // Radius of the semicircle
// //         clockwise: false,
// //       );
// //     }
// //
// //     // Close the path
// //     path.lineTo(size.width, size.height - 30); // Move to the bottom right corner
// //     path.lineTo(size.width, 0); // Move to the top right corner
// //     path.close(); // Close the path
// //
// //     return path;
// //   }
// //
// //   @override
// //   bool shouldReclip(CustomClipper<Path> oldClipper) => true; // Reclip if needed
// // }
// import 'package:flutter/material.dart';
// import 'dart:math';
//
// void main() {
//   runApp(const MaterialApp(
//     home: Scaffold(
//       body: Center(
//         child: FringedContainer(),
//       ),
//     ),
//   ));
// }
//
// class FringedContainer extends StatelessWidget {
//   const FringedContainer({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         // Shadow layer for subtle darkness
//         Positioned(
//           top: 0,
//           child: ClipPath(
//             clipper: TornPaperClipper(),
//             child: Container(
//               // width: 300,
//               // height: 100,
//               decoration: BoxDecoration(
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(1), // Darker shadow
//                     blurRadius: 20, // Increased blur
//                     spreadRadius: 10, // Slight spread
//                     offset: const Offset(10, 20), // Offset for depth
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
// class TornPaperClipper extends CustomClipper<Path> {
//   final Random random = Random();
//
//   @override
//   Path getClip(Size size) {
//     Path path = Path();
//     path.lineTo(0, size.height - 20); // Start slightly higher
//
//     double x = 0;
//     while (x < size.width) {
//       // More frequent, smaller tears
//       double yOffset = 20 + random.nextDouble() * 10; // Reduced variation
//       double nextX = x + 5 + random.nextDouble() * 30; // Closer spacing
//
//       path.lineTo(x, size.height - yOffset);
//       path.lineTo(nextX, size.height - 20);
//
//       x = nextX;
//     }
//
//     path.lineTo(size.width, size.height - 20);
//     path.lineTo(size.width, 0);
//     path.close();
//
//     return path;
//   }
//
//   @override
//   bool shouldReclip(CustomClipper<Path> oldClipper) => true;
// }
import 'dart:math';

import 'package:flutter/material.dart';

class WavyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 30); // Start slightly above the bottom

    // Create wave pattern along the bottom edge
    double waveWidth = 15; // Width of each wave
    double waveHeight = 3; // Height of the wave

    for (double i = 0; i < size.width; i += waveWidth) {
      path.quadraticBezierTo(
        i + waveWidth / 4, size.height - 30 - waveHeight, // Control point
        i + waveWidth / 2, size.height - 30, // Endpoint of the first half-wave
      );
      path.quadraticBezierTo(
        i + 3 * waveWidth / 4, size.height - 30 + waveHeight, // Control point
        i + waveWidth, size.height - 30, // Endpoint of the second half-wave
      );
    }

    path.lineTo(size.width, size.height - 30); // Bottom right corner
    path.lineTo(size.width, 0); // Top right corner
    path.close(); // Close the path

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}


class DuskyGlitterBackground extends StatelessWidget {
  const DuskyGlitterBackground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            Color(0xFF4A4A4A), // Dark grey
            Color(0xFF9E9E9E), // Glitter grey
          ],
          stops: [0.4, 1.0],
        ),
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}

class GlitterPainter extends CustomPainter {
  final int _numParticles = 100; // Adjust particle count

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random();
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < _numParticles; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 2; // Glitter dot size
      paint.color = Colors.white.withOpacity(random.nextDouble() * 0.5);
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
class LoadingImage extends StatelessWidget {
  final String imageUrl;

  const LoadingImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const DuskyGlitterBackground(), // Background shimmer effect
        Center(
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const DuskyGlitterBackground();
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.error, color: Colors.red),
              );
            },
          ),
        ),
      ],
    );
  }
}
