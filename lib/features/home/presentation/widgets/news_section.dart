import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/lhotse_news_card.dart';

class NewsData {
  const NewsData({
    required this.title,
    required this.brand,
    required this.subtitle,
    required this.imageUrl,
    this.hasPlayButton = false,
  });

  final String title;
  final String brand;
  final String subtitle;
  final String imageUrl;
  final bool hasPlayButton;
}

class NewsSection extends StatelessWidget {
  const NewsSection({super.key, required this.news});

  final List<NewsData> news;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 213,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: news.length + 1,
        itemBuilder: (context, i) {
          if (i == news.length) return const _ExploreAllCard();
          final data = news[i];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: LhotseNewsCard(
              title: data.title,
              imageUrl: data.imageUrl,
              badge: data.brand,
              subtitle: data.subtitle,
              hasPlayButton: data.hasPlayButton,
            ),
          );
        },
      ),
    );
  }
}

class _ExploreAllCard extends StatelessWidget {
  const _ExploreAllCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 213,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'EXPLORAR TODO',
                    style: AppTypography.headingLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '3 PUBLICACIONES',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
