/// ============================================================
/// HOME OPTION CARD WIDGET
/// ============================================================
/// A reusable card widget used on the Home Page dashboard grid.
/// Each card displays an icon, title, and navigates to a screen.
///
/// Usage:
///   HomeOptionCard(
///     icon: Icons.camera,
///     title: 'Start Detection',
///     color: Colors.blue,
///     onTap: () => Navigator.push(...),
///   )
/// ============================================================

import 'package:flutter/material.dart';

class HomeOptionCard extends StatelessWidget {
  // Icon displayed at the center of the card
  final IconData icon;

  // Title text displayed below the icon
  final String title;

  // Background accent color for the card's icon area
  final Color color;

  // Callback function when the card is tapped
  final VoidCallback onTap;

  const HomeOptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          // White card background
          color: Colors.white,
          // Rounded corners for modern look
          borderRadius: BorderRadius.circular(18),
          // Subtle shadow for depth
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ---- Icon Container ----
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // Light tinted background using the card's color
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            const SizedBox(height: 14),

            // ---- Title Text ----
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3436),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
