enum QuestionType { single, multi }

class OnboardingOption {
  const OnboardingOption({required this.value, required this.label});

  final String value; // stored in Supabase (English)
  final String label; // displayed in UI (Spanish)
}

class OnboardingQuestion {
  const OnboardingQuestion({
    required this.column,
    required this.question,
    required this.type,
    required this.options,
    this.helper,
    this.maxSelections,
  });

  final String column;
  final String question;
  final QuestionType type;
  final List<OnboardingOption> options;
  final String? helper;
  final int? maxSelections; // null = unlimited for multi
}

const kOnboardingQuestions = <OnboardingQuestion>[
  OnboardingQuestion(
    column: 'primary_goal',
    question: '¿Cuál es tu principal objetivo hoy?',
    type: QuestionType.single,
    options: [
      OnboardingOption(value: 'generate_passive_income', label: 'Generar ingresos pasivos'),
      OnboardingOption(value: 'grow_wealth', label: 'Hacer crecer mi patrimonio'),
      OnboardingOption(value: 'protect_capital', label: 'Proteger mi capital'),
      OnboardingOption(value: 'diversify', label: 'Diversificar inversiones'),
      OnboardingOption(value: 'access_exclusive', label: 'Acceder a oportunidades exclusivas'),
      OnboardingOption(value: 'exploring', label: 'Aún lo estoy explorando'),
    ],
  ),
  OnboardingQuestion(
    column: 'investor_profile',
    question: '¿Qué relación tienes actualmente con la inversión?',
    type: QuestionType.single,
    options: [
      OnboardingOption(value: 'never_invested', label: 'Nunca he invertido'),
      OnboardingOption(value: 'occasional', label: 'He invertido puntualmente'),
      OnboardingOption(value: 'recurring', label: 'Invierto de forma recurrente'),
      OnboardingOption(value: 'structured', label: 'Tengo una estrategia estructurada'),
      OnboardingOption(value: 'professional', label: 'Soy inversor profesional / avanzado'),
    ],
  ),
  OnboardingQuestion(
    column: 'asset_experience',
    question: '¿En qué tipos de activos has invertido?',
    type: QuestionType.multi,
    options: [
      OnboardingOption(value: 'real_estate', label: 'Inmobiliario'),
      OnboardingOption(value: 'stocks_funds', label: 'Bolsa / fondos'),
      OnboardingOption(value: 'crypto_alternatives', label: 'Cripto / alternativos'),
      OnboardingOption(value: 'own_businesses', label: 'Negocios propios'),
      OnboardingOption(value: 'other', label: 'Otros'),
      OnboardingOption(value: 'none', label: 'Ninguno'),
    ],
  ),
  OnboardingQuestion(
    column: 'ticket_size',
    question: '¿Cuál es el rango típico de inversión por operación?',
    type: QuestionType.single,
    options: [
      OnboardingOption(value: 'under_25k', label: 'Menos de 25.000 €'),
      OnboardingOption(value: '25k_100k', label: '25.000 – 100.000 €'),
      OnboardingOption(value: '100k_300k', label: '100.000 – 300.000 €'),
      OnboardingOption(value: '300k_1m', label: '300.000 € – 1M €'),
      OnboardingOption(value: 'over_1m', label: 'Más de 1M €'),
    ],
  ),
  OnboardingQuestion(
    column: 'risk_appetite',
    question: '¿Cómo defines tu relación con el riesgo?',
    type: QuestionType.single,
    options: [
      OnboardingOption(value: 'conservative', label: 'Muy conservador (priorizo seguridad)'),
      OnboardingOption(value: 'moderate', label: 'Moderado (equilibrio riesgo-retorno)'),
      OnboardingOption(value: 'dynamic', label: 'Dinámico (busco crecimiento)'),
      OnboardingOption(value: 'aggressive', label: 'Agresivo (priorizo rentabilidad)'),
    ],
  ),
  OnboardingQuestion(
    column: 'time_horizon',
    question: '¿Qué plazo encaja mejor contigo?',
    type: QuestionType.single,
    options: [
      OnboardingOption(value: 'short', label: 'Corto (0 – 1 año)'),
      OnboardingOption(value: 'medium', label: 'Medio (1 – 3 años)'),
      OnboardingOption(value: 'long', label: 'Largo (3 – 10 años)'),
      OnboardingOption(value: 'very_long', label: 'Muy largo (más de 10 años)'),
    ],
  ),
  OnboardingQuestion(
    column: 'decision_drivers',
    question: '¿Qué valoras más en una inversión?',
    type: QuestionType.multi,
    helper: 'Elige máximo dos.',
    maxSelections: 2,
    options: [
      OnboardingOption(value: 'profitability', label: 'Rentabilidad'),
      OnboardingOption(value: 'security', label: 'Seguridad'),
      OnboardingOption(value: 'liquidity', label: 'Liquidez'),
      OnboardingOption(value: 'simplicity', label: 'Simplicidad / delegación'),
      OnboardingOption(value: 'exclusivity', label: 'Exclusividad / acceso'),
      OnboardingOption(value: 'long_term_legacy', label: 'Impacto patrimonial a largo plazo'),
    ],
  ),
  OnboardingQuestion(
    column: 'involvement_level',
    question: '¿Cuánto quieres involucrarte en la gestión?',
    type: QuestionType.single,
    options: [
      OnboardingOption(value: 'delegate_all', label: 'Nada (quiero delegar todo)'),
      OnboardingOption(value: 'light_oversight', label: 'Poco (seguimiento puntual)'),
      OnboardingOption(value: 'engaged', label: 'Medio (quiero entender y participar)'),
      OnboardingOption(value: 'full_control', label: 'Alto (quiero control total)'),
    ],
  ),
  OnboardingQuestion(
    column: 'lifestyle_interests',
    question: 'Más allá de invertir, ¿qué te interesa?',
    type: QuestionType.multi,
    options: [
      OnboardingOption(value: 'lifestyle', label: 'Estilo de vida / experiencias'),
      OnboardingOption(value: 'design_architecture', label: 'Diseño / arquitectura'),
      OnboardingOption(value: 'art_collecting', label: 'Arte / coleccionismo'),
      OnboardingOption(value: 'tax_estate', label: 'Optimización fiscal / estructura patrimonial'),
      OnboardingOption(value: 'financial_freedom', label: 'Libertad financiera'),
      OnboardingOption(value: 'community_networking', label: 'Acceso a comunidad / networking'),
    ],
  ),
];
