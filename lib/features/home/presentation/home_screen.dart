import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/data/news_provider.dart';
import '../../../core/data/projects_provider.dart';
import '../../../core/data/supabase_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_shell_header.dart';
import 'widgets/news_section.dart';
import 'widgets/project_carousel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRole = ref.watch(currentUserRoleProvider);
    final projectsAsync = ref.watch(projectsProvider);
    final newsAsync = ref.watch(newsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header()),

          // Project carousel
          SliverToBoxAdapter(
            child: LayoutBuilder(builder: (context, constraints) {
              final screen = MediaQuery.of(context).size.height;
              final topSafe = MediaQuery.of(context).padding.top;
              final bottomSafe = MediaQuery.of(context).padding.bottom;
              final headerH = topSafe + 96;
              final navbarH = 48 + bottomSafe;
              final available = screen - headerH - navbarH;
              return SizedBox(
                height: available,
                child: projectsAsync.when(
                  data: (projects) => projects.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        )
                      : ProjectCarousel(
                          projects: projects.take(5).toList(),
                          currentRole: currentRole,
                        ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                  error: (e, _) => Center(child: Text('$e')),
                ),
              );
            }),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'NOTICIAS',
              onTap: () => context.push('/news'),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: newsAsync.when(
                data: (news) => NewsSection(news: news.take(5).toList()),
                loading: () => const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                ),
                error: (e, _) => const SizedBox(height: 200),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'SOBRE NOSOTROS',
              onTap: () {},
            ),
          ),

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
