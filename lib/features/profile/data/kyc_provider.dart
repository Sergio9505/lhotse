import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/supabase_provider.dart';

class KycDocument {
  const KycDocument({
    required this.docType,
    required this.status,
    this.fileUrl,
  });

  final String docType;  // 'dni_pasaporte' | 'justificante_domicilio' | 'origen_fondos' | 'contrato_marco'
  final String status;   // 'verified' | 'pending' | 'required'
  final String? fileUrl;

  String get displayName => switch (docType) {
        'dni_pasaporte' => 'DNI / Pasaporte',
        'justificante_domicilio' => 'Justificante de domicilio',
        'origen_fondos' => 'Origen de fondos',
        'contrato_marco' => 'Contrato marco',
        _ => docType,
      };

  factory KycDocument.fromJson(Map<String, dynamic> json) => KycDocument(
        docType: json['doc_type'] as String,
        status: json['status'] as String,
        fileUrl: json['file_url'] as String?,
      );
}

final kycDocumentsProvider = FutureProvider<List<KycDocument>>((ref) async {
  final userId = ref.watch(currentUserIdProvider).valueOrNull;
  if (userId == null) return [];
  final data = await ref
      .watch(supabaseClientProvider)
      .from('kyc_documents')
      .select()
      .eq('user_id', userId);
  return (data as List<dynamic>)
      .map((e) => KycDocument.fromJson(e as Map<String, dynamic>))
      .toList();
});
