import 'package:flutter/material.dart';

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
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: news.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final data = news[i];
          return LhotseNewsCard(
            title: data.title,
            imageUrl: data.imageUrl,
            brand: data.brand,
            subtitle: data.subtitle,
            hasPlayButton: data.hasPlayButton,
          );
        },
      ),
    );
  }
}
