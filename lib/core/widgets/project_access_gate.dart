import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/supabase_provider.dart';
import '../domain/project_data.dart';
import '../domain/user_role.dart';
import '../../features/home/presentation/widgets/vip_lock_sheet.dart';

/// Returns true when [project] is a VIP project and the current user's role
/// is not [UserRole.investorVip]. Every entry point must check this before
/// navigating to the project detail screen.
bool isProjectLocked(WidgetRef ref, ProjectData project) {
  if (!project.isVip) return false;
  return ref.read(currentUserRoleProvider) != UserRole.investorVip;
}

/// Navigates to /projects/:id or shows the VIP lock sheet, depending on the
/// current user's role. Use this at every entry point that has a fully-loaded
/// [ProjectData] object.
void openProjectOrLock(
  BuildContext context,
  WidgetRef ref,
  ProjectData project,
) {
  if (isProjectLocked(ref, project)) {
    showVipLockSheet(context);
  } else {
    context.push('/projects/${project.id}', extra: project);
  }
}
