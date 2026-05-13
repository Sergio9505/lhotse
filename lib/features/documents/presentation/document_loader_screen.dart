import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/supabase_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/open_supabase_doc.dart';
import '../../../core/widgets/lhotse_async_list_states.dart';

/// Intermediate screen for push-notification deep links of the form
/// `/documents/<id>`. Fetches the doc row, downloads via [openSupabaseDoc],
/// and `pushReplacement`s itself with the in-app document preview so the
/// back button returns to the prior screen — not to this loader.
class DocumentLoaderScreen extends ConsumerStatefulWidget {
  const DocumentLoaderScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<DocumentLoaderScreen> createState() =>
      _DocumentLoaderScreenState();
}

class _DocumentLoaderScreenState extends ConsumerState<DocumentLoaderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final supabase = ref.read(supabaseClientProvider);
    Map<String, dynamic>? row;
    try {
      row = await supabase
          .from('documents')
          .select('file_url, name')
          .eq('id', widget.documentId)
          .maybeSingle();
    } catch (e) {
      if (!mounted) return;
      _fail('No se pudo cargar el documento.');
      return;
    }
    if (!mounted) return;
    if (row == null) {
      _fail('Documento no encontrado.');
      return;
    }
    await openSupabaseDoc(
      context,
      fileUrl: row['file_url'] as String,
      fileName: row['name'] as String,
      docId: widget.documentId,
      replace: true,
    );
  }

  void _fail(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: LhotseAsyncLoading()),
    );
  }
}
