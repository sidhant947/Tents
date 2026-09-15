import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tents/ui/core/theme/app_colors.dart';
import 'package:tents/ui/core/widgets/tangible_button.dart';
import 'package:tents/ui/providers.dart';

class HowToPlayView extends ConsumerWidget {
  const HowToPlayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    AppColors.currentTheme = settings.theme;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: AppColors.headingDark,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'How to Play',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.headingDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  _guideStep(
                    stepNumber: '1',
                    title: 'Row & Column Numbers',
                    description: 'The numbers along the top and left edges indicate exactly how many tents must be placed in that row or column.',
                  ),
                  const SizedBox(height: 16),
                  _guideStep(
                    stepNumber: '2',
                    title: 'Pair With Trees',
                    description: 'Each tent must be directly adjacent (horizontally or vertically) to at least one tree. Every tree must connect to a tent.',
                  ),
                  const SizedBox(height: 16),
                  _guideStep(
                    stepNumber: '3',
                    title: 'No Touching Tents',
                    description: 'Tents cannot touch each other in any direction — not even diagonally.',
                  ),
                  const SizedBox(height: 16),
                  _guideStep(
                    stepNumber: '4',
                    title: 'Controls',
                    description: '• Tap a cell to place or remove a Tent.\n• Long press a cell to mark or clear a Cross.',
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: TangibleButton(
                text: 'Got it',
                height: 44,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guideStep({
    required String stepNumber,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$stepNumber.',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.headingDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.headingDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.subtext,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
