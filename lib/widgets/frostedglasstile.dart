import 'dart:math';

import 'package:flutter/material.dart';
import 'package:wx_text/wx_text.dart';

class FrostedGlassTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;

  const FrostedGlassTile({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color _getRandomColor() {
      Random random = Random();

      // Generate RGB values in the range of 180 to 255 for vibrant colors
      return Color.fromARGB(
        255, 180 + random.nextInt(76), // R: High brightness
        180 + random.nextInt(76), // G: High brightness
        180 + random.nextInt(76), // B: High brightness
      ).withOpacity(0.7); // High opacity for vividness
    }
    final double tileHeight = 150 + (icon.codePoint % 300);

    return SingleChildScrollView(
      child: Container(
        constraints: BoxConstraints(
          minHeight: 150,
          maxHeight: tileHeight,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
            colors: [Colors.red, Colors.blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.lightBlue.shade200
                : Colors.white.withOpacity(0.9),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: Colors.white.withOpacity(isSelected ? 0.2 : 0.5),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      color: Colors.black87,
                      size: 32),
                  const SizedBox(height: 10),
                  WxText(title,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      filter: [
                        WxTextFilter.highlight(
                          search: title,
                          style: TextStyle(
                              backgroundColor: isSelected
                                  ? Colors.green.shade200
                                  : Colors.transparent),
                        ),
                      ]),
                  const SizedBox(height: 6),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Text(
                        description,
                        style: TextStyle(
                            color: isSelected ? Colors.black : Colors.black87,
                            fontSize: 15,
                            fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400),
                        overflow: TextOverflow.fade,
                        maxLines: 4,
                      ),
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
}