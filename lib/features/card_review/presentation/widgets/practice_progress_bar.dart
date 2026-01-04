import 'package:flutter/material.dart';

/// Progress bar for practice sessions showing progress and score
class PracticeProgressBar extends StatelessWidget {
  final double progress;
  final int correctCount;
  final int incorrectCount;

  const PracticeProgressBar({
    super.key,
    required this.progress,
    required this.correctCount,
    required this.incorrectCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          minHeight: 4,
        ),

        // Score indicators
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildScoreChip(
                icon: Icons.check_circle,
                count: correctCount,
                color: Colors.green,
              ),
              const SizedBox(width: 16),
              _buildScoreChip(
                icon: Icons.cancel,
                count: incorrectCount,
                color: Colors.red,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreChip({
    required IconData icon,
    required int count,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
