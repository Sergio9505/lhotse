import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/project_data.dart';
import 'project_card.dart';

export 'package:lhotse/core/domain/project_data.dart';

class ProjectCarousel extends StatefulWidget {
  const ProjectCarousel({super.key, required this.projects});

  final List<ProjectData> projects;

  @override
  State<ProjectCarousel> createState() => _ProjectCarouselState();
}

class _ProjectCarouselState extends State<ProjectCarousel> {
  final _controller = PageController();
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % widget.projects.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.projects.length,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemBuilder: (context, i) => ProjectCard(
                project: widget.projects[i],
                onTap: () =>
                    context.push('/projects/${widget.projects[i].id}'),
              ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _ProgressBar(
            total: widget.projects.length,
            current: _currentPage,
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.total, required this.current});

  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8,
      child: Row(
        children: List.generate(total, (i) {
          return Expanded(
            child: Container(
              color: i <= current
                  ? Colors.white
                  : Colors.black.withValues(alpha: 0.25),
            ),
          );
        }),
      ),
    );
  }
}
