import 'dart:async';

import 'package:flutter/material.dart';

import 'food_ordering_widgets.dart';

class ResidenceFavouritesSlideshow extends StatefulWidget {
  const ResidenceFavouritesSlideshow({super.key});

  @override
  State<ResidenceFavouritesSlideshow> createState() =>
      _ResidenceFavouritesSlideshowState();
}

class _ResidenceFavouritesSlideshowState
    extends State<ResidenceFavouritesSlideshow> {
  static const _imagePaths = [
    'assets/images/residence_favourite_1.png',
    'assets/images/residence_favourite_2.png',
    'assets/images/residence_favourite_3.png',
  ];

  static const _slideInterval = Duration(seconds: 3);
  static const _fadeDuration = Duration(milliseconds: 700);

  Timer? _slideTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _slideTimer?.cancel();
    _slideTimer = Timer.periodic(_slideInterval, (_) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _imagePaths.length;
        });
      }
    });
  }

  void _showImage(int index) {
    if (index == _currentIndex) {
      _startTimer();
      return;
    }

    setState(() => _currentIndex = index);
    _startTimer();
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 285,
      decoration: BoxDecoration(
        color: const Color(0xFFDCE9D9),
        borderRadius: BorderRadius.circular(30),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: _fadeDuration,
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              layoutBuilder: (currentChild, previousChildren) => Stack(
                fit: StackFit.expand,
                children: [
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              ),
              child: Image.asset(
                _imagePaths[_currentIndex],
                key: ValueKey(_imagePaths[_currentIndex]),
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
            ),
            Positioned(
              left: 16,
              bottom: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 14,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: KslColors.orange, size: 19),
                    SizedBox(width: 5),
                    Text(
                      'Residence favourites',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_imagePaths.length, (index) {
                  final isSelected = index == _currentIndex;
                  return IconButton(
                    onPressed: () => _showImage(index),
                    tooltip: 'Show food image ${index + 1}',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 24,
                      height: 24,
                    ),
                    icon: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isSelected ? 16 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(color: Color(0x55000000), blurRadius: 4),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
