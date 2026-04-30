import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';

/// In-app document viewer.
///
/// Supports PDFs (rendered via pdfx with pinch-zoom) and common image formats
/// (rendered via InteractiveViewer). For unsupported types (e.g. .docx) falls
/// back to OpenFilex and pops immediately — the share sheet becomes the
/// secondary action the user can invoke from the header icon.
///
/// Assumes [localPath] points to a fully downloaded file. The download and
/// cache logic lives in openSupabaseDoc.
class DocumentPreviewScreen extends StatefulWidget {
  const DocumentPreviewScreen({
    super.key,
    required this.localPath,
    required this.displayName,
    this.subtitle,
  });

  final String localPath;
  final String displayName;
  final String? subtitle;

  @override
  State<DocumentPreviewScreen> createState() => _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends State<DocumentPreviewScreen> {
  PdfControllerPinch? _pdfCtrl;
  _DocType _docType = _DocType.pdf;

  static const _imageExts = {'.jpg', '.jpeg', '.png', '.heic', '.heif', '.webp'};

  @override
  void initState() {
    super.initState();
    final ext = _extOf(widget.localPath).toLowerCase();
    if (ext == '.pdf') {
      _docType = _DocType.pdf;
      _pdfCtrl = PdfControllerPinch(
        document: PdfDocument.openFile(widget.localPath),
      );
    } else if (_imageExts.contains(ext)) {
      _docType = _DocType.image;
    } else {
      _docType = _DocType.unsupported;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await OpenFilex.open(widget.localPath);
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  @override
  void dispose() {
    _pdfCtrl?.dispose();
    super.dispose();
  }

  String _extOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return '';
    return path.substring(dot);
  }

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(widget.localPath)],
        subject: widget.displayName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSub = widget.subtitle != null && widget.subtitle!.isNotEmpty;

    return Scaffold(
      backgroundColor: _docType == _DocType.image
          ? Colors.black
          : AppColors.background,
      appBar: AppBar(
        backgroundColor: _docType == _DocType.image
            ? Colors.black
            : AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: _docType == _DocType.image
            ? const LhotseBackButton.overImage(useLightOverlay: true)
            : const LhotseBackButton.onSurface(),
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.displayName.toUpperCase(),
              style: AppTypography.titleUppercase.copyWith(
                color: _docType == _DocType.image
                    ? Colors.white
                    : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (hasSub) ...[
              const SizedBox(height: 2),
              Text(
                widget.subtitle!.toUpperCase(),
                style: AppTypography.labelUppercaseSm.copyWith(
                  color: _docType == _DocType.image
                      ? Colors.white.withValues(alpha: 0.6)
                      : AppColors.accentMuted,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_docType != _DocType.unsupported)
            GestureDetector(
              onTap: _share,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Icon(
                    Platform.isIOS ? Icons.ios_share : Icons.share,
                    size: 22,
                    color: _docType == _DocType.image
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: switch (_docType) {
        _DocType.pdf => PdfViewPinch(
            controller: _pdfCtrl!,
            builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
              options: const DefaultBuilderOptions(),
              documentLoaderBuilder: (_) => const Center(
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
              pageLoaderBuilder: (_) => const Center(
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
              errorBuilder: (_, error) => Center(
                child: Text(
                  'No se pudo cargar el documento',
                  style: AppTypography.bodyRow.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        _DocType.image => Center(
            child: InteractiveViewer(
              child: Image.file(File(widget.localPath)),
            ),
          ),
        _DocType.unsupported => const SizedBox.shrink(),
      },
    );
  }
}

enum _DocType { pdf, image, unsupported }
