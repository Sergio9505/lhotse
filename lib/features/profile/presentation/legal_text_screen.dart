import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';

/// Shared screen for static legal text (Terms & Conditions, Privacy Policy).
class LegalTextScreen extends StatelessWidget {
  const LegalTextScreen({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _Header(topPadding: topPadding, title: title),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                bottomPadding + AppSpacing.xl,
              ),
              child: Text(
                body,
                style: AppTypography.bodyReading.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.topPadding, required this.title});

  final double topPadding;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        topPadding + 16,
        AppSpacing.lg,
        16,
      ),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            const LhotseBackButton.onSurface(),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                title,
                style: AppTypography.titleUppercase.copyWith(
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Placeholder legal text
// ---------------------------------------------------------------------------

abstract final class LegalContent {
  static const terms = '''
1. OBJETO

Las presentes condiciones generales regulan el acceso y uso de la aplicación móvil de Lhotse Group, S.L. (en adelante, "Lhotse Group"), destinada a facilitar a los inversores el seguimiento de sus inversiones inmobiliarias.

2. ACCESO Y REGISTRO

El acceso a la aplicación requiere registro previo. El usuario se compromete a proporcionar información veraz y actualizada. Lhotse Group se reserva el derecho de verificar la identidad del usuario conforme a la normativa vigente de prevención de blanqueo de capitales.

3. SERVICIOS

La aplicación ofrece los siguientes servicios:
— Consulta del estado de las inversiones realizadas a través de las firmas del grupo.
— Acceso a documentación asociada a cada inversión.
— Información sobre nuevos proyectos y oportunidades de inversión.
— Comunicaciones y notificaciones relevantes.

4. RESPONSABILIDAD

La información mostrada en la aplicación tiene carácter informativo. Los valores, rentabilidades y estimaciones no constituyen asesoramiento financiero ni garantía de rendimiento futuro.

5. PROPIEDAD INTELECTUAL

Todos los contenidos de la aplicación (textos, imágenes, logotipos, diseño) son propiedad de Lhotse Group o de sus licenciantes. Queda prohibida su reproducción sin autorización expresa.

6. PROTECCIÓN DE DATOS

El tratamiento de datos personales se realiza conforme al Reglamento General de Protección de Datos (RGPD) y la Ley Orgánica 3/2018. Para más información, consulte nuestra Política de Privacidad.

7. MODIFICACIONES

Lhotse Group se reserva el derecho de modificar las presentes condiciones. Las modificaciones serán comunicadas a los usuarios a través de la aplicación.

8. LEGISLACIÓN APLICABLE

Las presentes condiciones se rigen por la legislación española. Para la resolución de cualquier controversia, las partes se someten a los juzgados y tribunales de Madrid.

Última actualización: abril 2026.''';

  static const privacy = '''
1. RESPONSABLE DEL TRATAMIENTO

Lhotse Group, S.L., con domicilio social en Madrid, es el responsable del tratamiento de los datos personales recabados a través de esta aplicación.

2. DATOS RECOPILADOS

Recopilamos los siguientes datos personales:
— Datos identificativos: nombre, apellidos, DNI/NIE/pasaporte.
— Datos de contacto: dirección, teléfono, correo electrónico.
— Datos financieros: información sobre inversiones realizadas.
— Datos de uso: actividad dentro de la aplicación, dispositivo, IP.

3. FINALIDAD DEL TRATAMIENTO

Los datos se tratan con las siguientes finalidades:
— Gestión de la relación contractual con el inversor.
— Cumplimiento de obligaciones legales (KYC, prevención de blanqueo).
— Envío de comunicaciones sobre inversiones y servicios.
— Mejora de la experiencia de usuario.

4. BASE LEGAL

— Ejecución de un contrato.
— Cumplimiento de obligaciones legales.
— Consentimiento del interesado para comunicaciones comerciales.
— Interés legítimo para mejora del servicio.

5. CONSERVACIÓN

Los datos se conservarán mientras se mantenga la relación contractual y, posteriormente, durante los plazos legales aplicables.

6. DERECHOS

El usuario puede ejercer sus derechos de acceso, rectificación, supresión, portabilidad, limitación y oposición dirigiéndose a privacidad@lhotsegroup.com.

7. SEGURIDAD

Lhotse Group implementa medidas técnicas y organizativas para garantizar la seguridad de los datos personales, incluyendo cifrado, control de acceso y auditorías periódicas.

8. COOKIES Y TECNOLOGÍAS SIMILARES

La aplicación puede utilizar tecnologías de seguimiento para mejorar el servicio. El usuario puede configurar sus preferencias en los ajustes de la aplicación.

Última actualización: abril 2026.''';
}
