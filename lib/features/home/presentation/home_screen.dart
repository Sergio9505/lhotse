import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/data/mock/mock_projects.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/news_section.dart';
import 'widgets/project_carousel.dart';

const _kNewsImages = [
  'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=600&q=80',
  'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=600&q=80',
];

final _mockNews = [
  NewsData(
    title: 'Visión 2025: Carta del CEO',
    brand: 'Myttas',
    subtitle: 'Video Brief — 3:45',
    imageUrl: _kNewsImages[0],
  ),
  NewsData(
    title: 'Avance de Obra: Red Clay',
    brand: 'Vellte',
    subtitle: 'Video Brief — 2:15',
    imageUrl: _kNewsImages[1],
    hasPlayButton: true,
  ),
];

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
              onTap: () {
                // TODO: navigate to all news
              },
            ),
          ),

          // News horizontal scroll
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: NewsSection(news: _mockNews),
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
    final topPadding = MediaQuery.of(context).padding.top;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, topPadding + 16, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.push('/projects'),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                  child: Icon(
                    LucideIcons.arrowUpRight,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          SvgPicture.asset(
            'assets/images/lhotse_logo.svg',
            width: 20,
            height: 18,
            colorFilter: const ColorFilter.mode(
              AppColors.primary,
              BlendMode.srcIn,
            ),
          ),
        ],
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
              child: Icon(
                LucideIcons.arrowUpRight,
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
