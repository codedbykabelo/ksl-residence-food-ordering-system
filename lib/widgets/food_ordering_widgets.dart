import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/meal_images.dart';

class KslColors {
  static const green = Color(0xFF126B4F);
  static const darkGreen = Color(0xFF123B2F);
  static const lightGreen = Color(0xFFEAF4EE);
  static const background = Color(0xFFF7F8F5);
  static const text = Color(0xFF202922);
  static const muted = Color(0xFF69756D);
  static const orange = Color(0xFFF4A340);
}

class KslBrand extends StatelessWidget {
  final bool compact;

  const KslBrand({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 38 : 44,
          height: compact ? 38 : 44,
          decoration: BoxDecoration(
            color: KslColors.green,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.restaurant_rounded,
            size: compact ? 21 : 24,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 11),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'KSL Residence',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: KslColors.darkGreen,
                  fontSize: compact ? 14 : 16,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              if (!compact)
                Text(
                  'FOOD ORDERING',
                  style: TextStyle(
                    color: KslColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class KslMealArtwork extends StatelessWidget {
  final String image;
  final double height;
  final BorderRadius borderRadius;

  const KslMealArtwork({
    super.key,
    required this.image,
    this.height = 168,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4EBD9), Color(0xFFE9F2E8)],
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Image.asset(
                MealImages.fallback,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const ColoredBox(color: Color(0xFFE9F2E8)),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white.withValues(alpha: 0.75),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KslEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const KslEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: KslColors.lightGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: KslColors.green),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: KslColors.darkGreen,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: KslColors.muted, height: 1.5),
              ),
            ),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

class KslStudentFooter extends StatelessWidget {
  final ValueChanged<int> onNavigate;

  const KslStudentFooter({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: const Color(0xFF102E25),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 24,
            spacing: 48,
            children: [
              SizedBox(
                width: 260,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KSL Residence\nFood Ordering',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Fresh favourites, made easy for residence life.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              _FooterLinks(
                title: 'Student',
                links: const ['Home', 'Meals', 'Orders', 'Profile'],
                onTap: (label) => onNavigate(
                  const {
                        'Home': 0,
                        'Meals': 1,
                        'Orders': 2,
                        'Profile': 4,
                      }[label] ??
                      0,
                ),
              ),
              _FooterLinks(
                title: 'Support',
                links: const ['Help', 'Contact'],
                onTap: (label) => _showSupport(context, label),
              ),
              _FooterLinks(
                title: 'Staff Portal',
                links: const ['Staff Login'],
                onTap: (_) => Navigator.of(context).pushNamed('/staff'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSupport(BuildContext context, String topic) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(topic),
        content: const Text(
          'For help with a meal order, please contact the KSL Residence dining team.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _FooterLinks extends StatelessWidget {
  final String title;
  final List<String> links;
  final ValueChanged<String> onTap;

  const _FooterLinks({
    required this.title,
    required this.links,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 145,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 11),
          for (final link in links)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: InkWell(
                onTap: () => onTap(link),
                child: Text(
                  link,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
