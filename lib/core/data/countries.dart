/// Country directory for the phone field selector.
///
/// Curated list (~60 entries) covering Spain (default), Western Europe,
/// North & Latin America, major Asian and Middle-Eastern markets, and a
/// few Oceania / Africa entries — the realistic surface for Lhotse Group
/// investors. Names in Spanish, alphabetically sorted at render time.
library;

class Country {
  const Country({
    required this.code,
    required this.name,
    required this.dialCode,
    required this.flag,
  });

  /// ISO 3166-1 alpha-2 ('ES', 'FR', 'GB').
  final String code;

  /// Display name in Spanish ('España', 'Reino Unido').
  final String name;

  /// E.164 country dial code with leading '+' ('+34', '+1', '+44').
  final String dialCode;

  /// Unicode flag emoji ('🇪🇸').
  final String flag;
}

const kDefaultCountry = Country(
  code: 'ES',
  name: 'España',
  dialCode: '+34',
  flag: '🇪🇸',
);

/// Curated list. Order here doesn't matter — the picker sorts by name at
/// render time and places [kDefaultCountry] at the top of the list.
const kCountries = <Country>[
  // ── Europe ────────────────────────────────────────────────────────────
  Country(code: 'ES', name: 'España', dialCode: '+34', flag: '🇪🇸'),
  Country(code: 'FR', name: 'Francia', dialCode: '+33', flag: '🇫🇷'),
  Country(code: 'GB', name: 'Reino Unido', dialCode: '+44', flag: '🇬🇧'),
  Country(code: 'DE', name: 'Alemania', dialCode: '+49', flag: '🇩🇪'),
  Country(code: 'IT', name: 'Italia', dialCode: '+39', flag: '🇮🇹'),
  Country(code: 'PT', name: 'Portugal', dialCode: '+351', flag: '🇵🇹'),
  Country(code: 'CH', name: 'Suiza', dialCode: '+41', flag: '🇨🇭'),
  Country(code: 'NL', name: 'Países Bajos', dialCode: '+31', flag: '🇳🇱'),
  Country(code: 'BE', name: 'Bélgica', dialCode: '+32', flag: '🇧🇪'),
  Country(code: 'LU', name: 'Luxemburgo', dialCode: '+352', flag: '🇱🇺'),
  Country(code: 'AT', name: 'Austria', dialCode: '+43', flag: '🇦🇹'),
  Country(code: 'IE', name: 'Irlanda', dialCode: '+353', flag: '🇮🇪'),
  Country(code: 'DK', name: 'Dinamarca', dialCode: '+45', flag: '🇩🇰'),
  Country(code: 'SE', name: 'Suecia', dialCode: '+46', flag: '🇸🇪'),
  Country(code: 'NO', name: 'Noruega', dialCode: '+47', flag: '🇳🇴'),
  Country(code: 'FI', name: 'Finlandia', dialCode: '+358', flag: '🇫🇮'),
  Country(code: 'IS', name: 'Islandia', dialCode: '+354', flag: '🇮🇸'),
  Country(code: 'PL', name: 'Polonia', dialCode: '+48', flag: '🇵🇱'),
  Country(code: 'CZ', name: 'República Checa', dialCode: '+420', flag: '🇨🇿'),
  Country(code: 'GR', name: 'Grecia', dialCode: '+30', flag: '🇬🇷'),
  Country(code: 'HU', name: 'Hungría', dialCode: '+36', flag: '🇭🇺'),
  Country(code: 'RO', name: 'Rumanía', dialCode: '+40', flag: '🇷🇴'),
  Country(code: 'MC', name: 'Mónaco', dialCode: '+377', flag: '🇲🇨'),
  Country(code: 'AD', name: 'Andorra', dialCode: '+376', flag: '🇦🇩'),
  Country(code: 'LI', name: 'Liechtenstein', dialCode: '+423', flag: '🇱🇮'),
  Country(code: 'MT', name: 'Malta', dialCode: '+356', flag: '🇲🇹'),
  Country(code: 'EE', name: 'Estonia', dialCode: '+372', flag: '🇪🇪'),
  Country(code: 'LV', name: 'Letonia', dialCode: '+371', flag: '🇱🇻'),
  Country(code: 'LT', name: 'Lituania', dialCode: '+370', flag: '🇱🇹'),

  // ── Americas ──────────────────────────────────────────────────────────
  Country(code: 'US', name: 'Estados Unidos', dialCode: '+1', flag: '🇺🇸'),
  Country(code: 'CA', name: 'Canadá', dialCode: '+1', flag: '🇨🇦'),
  Country(code: 'MX', name: 'México', dialCode: '+52', flag: '🇲🇽'),
  Country(code: 'AR', name: 'Argentina', dialCode: '+54', flag: '🇦🇷'),
  Country(code: 'BR', name: 'Brasil', dialCode: '+55', flag: '🇧🇷'),
  Country(code: 'CL', name: 'Chile', dialCode: '+56', flag: '🇨🇱'),
  Country(code: 'CO', name: 'Colombia', dialCode: '+57', flag: '🇨🇴'),
  Country(code: 'PE', name: 'Perú', dialCode: '+51', flag: '🇵🇪'),
  Country(code: 'UY', name: 'Uruguay', dialCode: '+598', flag: '🇺🇾'),
  Country(code: 'VE', name: 'Venezuela', dialCode: '+58', flag: '🇻🇪'),
  Country(code: 'DO', name: 'República Dominicana', dialCode: '+1', flag: '🇩🇴'),
  Country(code: 'CR', name: 'Costa Rica', dialCode: '+506', flag: '🇨🇷'),
  Country(code: 'PA', name: 'Panamá', dialCode: '+507', flag: '🇵🇦'),
  Country(code: 'EC', name: 'Ecuador', dialCode: '+593', flag: '🇪🇨'),
  Country(code: 'BO', name: 'Bolivia', dialCode: '+591', flag: '🇧🇴'),
  Country(code: 'PY', name: 'Paraguay', dialCode: '+595', flag: '🇵🇾'),
  Country(code: 'GT', name: 'Guatemala', dialCode: '+502', flag: '🇬🇹'),

  // ── Asia ──────────────────────────────────────────────────────────────
  Country(code: 'CN', name: 'China', dialCode: '+86', flag: '🇨🇳'),
  Country(code: 'JP', name: 'Japón', dialCode: '+81', flag: '🇯🇵'),
  Country(code: 'IN', name: 'India', dialCode: '+91', flag: '🇮🇳'),
  Country(code: 'SG', name: 'Singapur', dialCode: '+65', flag: '🇸🇬'),
  Country(code: 'HK', name: 'Hong Kong', dialCode: '+852', flag: '🇭🇰'),
  Country(code: 'KR', name: 'Corea del Sur', dialCode: '+82', flag: '🇰🇷'),
  Country(code: 'TH', name: 'Tailandia', dialCode: '+66', flag: '🇹🇭'),
  Country(code: 'PH', name: 'Filipinas', dialCode: '+63', flag: '🇵🇭'),
  Country(code: 'ID', name: 'Indonesia', dialCode: '+62', flag: '🇮🇩'),
  Country(code: 'VN', name: 'Vietnam', dialCode: '+84', flag: '🇻🇳'),
  Country(code: 'MY', name: 'Malasia', dialCode: '+60', flag: '🇲🇾'),
  Country(code: 'TW', name: 'Taiwán', dialCode: '+886', flag: '🇹🇼'),

  // ── Middle East ───────────────────────────────────────────────────────
  Country(code: 'AE', name: 'Emiratos Árabes Unidos', dialCode: '+971', flag: '🇦🇪'),
  Country(code: 'SA', name: 'Arabia Saudí', dialCode: '+966', flag: '🇸🇦'),
  Country(code: 'QA', name: 'Catar', dialCode: '+974', flag: '🇶🇦'),
  Country(code: 'IL', name: 'Israel', dialCode: '+972', flag: '🇮🇱'),
  Country(code: 'TR', name: 'Turquía', dialCode: '+90', flag: '🇹🇷'),
  Country(code: 'KW', name: 'Kuwait', dialCode: '+965', flag: '🇰🇼'),
  Country(code: 'BH', name: 'Baréin', dialCode: '+973', flag: '🇧🇭'),

  // ── Oceania ───────────────────────────────────────────────────────────
  Country(code: 'AU', name: 'Australia', dialCode: '+61', flag: '🇦🇺'),
  Country(code: 'NZ', name: 'Nueva Zelanda', dialCode: '+64', flag: '🇳🇿'),

  // ── Africa ────────────────────────────────────────────────────────────
  Country(code: 'ZA', name: 'Sudáfrica', dialCode: '+27', flag: '🇿🇦'),
  Country(code: 'MA', name: 'Marruecos', dialCode: '+212', flag: '🇲🇦'),
  Country(code: 'EG', name: 'Egipto', dialCode: '+20', flag: '🇪🇬'),
  Country(code: 'NG', name: 'Nigeria', dialCode: '+234', flag: '🇳🇬'),
];
