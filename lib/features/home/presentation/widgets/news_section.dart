import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/mock/mock_news.dart';
import '../../../../core/widgets/lhotse_news_card.dart';

class NewsSection extends StatelessWidget {
  const NewsSection({super.key, required this.news});

  final List<NewsItemData> news;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
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
            height: 200,
            width: 300,
            onTap: () => context.push('/news/${data.id}'),
          );
        },
      ),
    );
  }
}
