import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/data/mock/mock_news.dart';
import '../../../core/data/mock/mock_projects.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_shell_header.dart';
import 'widgets/news_section.dart';
import 'widgets/project_carousel.dart';

final _homeNews = mockNews
    .take(5)
    .map((n) => NewsData(
          title: n.title,
          brand: n.brand,
          subtitle: n.subtitle,
          imageUrl: n.imageUrl,
          hasPlayButton: n.hasPlayButton,
        ))
    .toList();

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header: "PROYECTOS" + logo
          SliverToBoxAdapter(child: _Header()),

          // Project carousel
          SliverToBoxAdapter(
            child: SizedBox(
              height: 520,
              child: ProjectCarousel(projects: mockProjects.take(5).toList()),
            ),
          ),

          // Spacing
          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // "NOTICIAS" header
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'NOTICIAS',
              onTap: () => context.push('/news'),
            ),
          ),

          // News horizontal scroll
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: NewsSection(news: _homeNews),
            ),
          ),

          // Spacing
          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // "SOBRE NOSOTROS" header
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'SOBRE NOSOTROS',
              onTap: () {
                // TODO: navigate to about us
              },
            ),
          ),

          // TODO: Sobre Nosotros content

          // Bottom spacing for nav bar
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LhotseShellHeader(
      child: GestureDetector(
        onTap: () => context.push('/projects'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PROYECTOS',
              style: AppTypography.headingLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: PhosphorIcon(
                PhosphorIconsThin.arrowUpRight,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onTap});

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.pagePadding,
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: AppTypography.headingLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: PhosphorIcon(
                PhosphorIconsThin.arrowUpRight,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
