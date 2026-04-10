import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/data/mock/mock_projects.dart';
import '../../../core/domain/project_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';

class ProjectDetailScreen extends StatelessWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    final project = findProjectById(projectId);

    if (project == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Proyecto no encontrado',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return _ProjectDetailBody(project: project);
  }
}

class _ProjectDetailBody extends StatefulWidget {
  const _ProjectDetailBody({required this.project});

  final ProjectData project;

  @override
  State<_ProjectDetailBody> createState() => _ProjectDetailBodyState();
}

class _ProjectDetailBodyState extends State<_ProjectDetailBody> {
  late final ScrollController _scrollController;
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final expandedHeight = MediaQuery.of(context).size.height * 0.55;
    final collapsedHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
    final threshold = expandedHeight - collapsedHeight - 40;
    final collapsed = _scrollController.offset >= threshold;

    if (collapsed != _isCollapsed) {
      setState(() => _isCollapsed = collapsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final expandedHeight = screenHeight * 0.55;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _isCollapsed
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              pinned: true,
              stretch: true,
              expandedHeight: expandedHeight,
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              elevation: _isCollapsed ? 0.5 : 0,
              leading: _isCollapsed
                  ? const LhotseBackButton.onSurface()
                  : const LhotseBackButton.onImage(),
              title: AnimatedOpacity(
                opacity: _isCollapsed ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  widget.project.name.toUpperCase(),
                  style: AppTypography.headingSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Hero image
                    Image.network(
                      widget.project.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Container(color: AppColors.surface),
                    ),

                    // Gradient overlay
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.center,
                          colors: [
                            Color(0x66000000),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content panel
            SliverToBoxAdapter(
              child: _ContentPanel(project: widget.project),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentPanel extends StatelessWidget {
  const _ContentPanel({required this.project});

  final ProjectData project;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Color(0x4D000000),
            blurRadius: 60,
            offset: Offset(0, -20),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project name
          Text(
            project.name.toUpperCase(),
            style: AppTypography.displayLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.48,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Brand + location
          Row(
            children: [
              Text(
                project.brand.toUpperCase(),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.8,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '•',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.4),
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  project.location.toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.accentMuted,
                    letterSpacing: 1.35,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Tagline
          Opacity(
            opacity: 0.9,
            child: Text(
              project.tagline,
              style: AppTypography.headingMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Description with bold parsing
          _buildRichDescription(project.description),

          const SizedBox(height: AppSpacing.xl),

          // Gallery thumbnail
          if (project.galleryImages.isNotEmpty)
            ClipRRect(
              child: SizedBox(
                width: 190,
                height: 152,
                child: Image.network(
                  project.galleryImages.first,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Container(color: AppColors.surface),
                ),
              ),
            ),

          const SizedBox(height: AppSpacing.xxl),

          // "INFO DEL PROYECTO" section header
          Center(
            child: Text(
              'INFO DEL PROYECTO',
              style: AppTypography.headingMedium.copyWith(
                color: Colors.black,
                letterSpacing: -0.48,
              ),
            ),
          ),

          SizedBox(height: bottomPadding + 80),
        ],
      ),
    );
  }

  Widget _buildRichDescription(String text) {
    final paragraphs = text.split('\n\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((paragraph) {
        final parts = paragraph.split('**');
        return Padding(
          padding: EdgeInsets.only(
            bottom: paragraph == paragraphs.last ? 0 : AppSpacing.md,
          ),
          child: RichText(
            text: TextSpan(
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              children: parts.asMap().entries.map((entry) {
                final isBold = entry.key.isOdd;
                return TextSpan(
                  text: entry.value,
                  style: isBold
                      ? TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        )
                      : null,
                );
              }).toList(),
            ),
          ),
        );
      }).toList(),
    );
  }
}
