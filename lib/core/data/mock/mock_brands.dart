import '../../domain/brand_data.dart';

const _kBrandCovers = [
  'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?w=800&q=80',
  'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800&q=80',
  'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=800&q=80',
  'https://images.unsplash.com/photo-1600585154526-990dced4db0d?w=800&q=80',
  'https://images.unsplash.com/photo-1600573472592-401b489a3cdc?w=800&q=80',
];

final mockBrands = [
  // Existing brands (with investments in strategy)
  BrandData(
    id: '1',
    name: 'Myttas',
    logoAsset: 'assets/icons/brands/mytas.svg',
    coverImageUrl: _kBrandCovers[0],
    businessModel: BusinessModel.directPurchase,
    tagline: 'Residencias de autor en entornos naturales únicos.',
    description:
        'Myttas nace de la convicción de que el hogar más valioso es aquel que fusiona diseño contemporáneo con paisaje. Un activo gestionado bajo el modelo Compra Directa, donde cada ubicación es seleccionada por su potencial de revalorización a largo plazo.\n\nLa marca trabaja con arquitectos de referencia para garantizar que cada proyecto eleve el estándar del mercado premium en el que opera.',
    websiteUrl: 'https://myttas.com',
  ),
  BrandData(
    id: '2',
    name: 'Lacomb & Bos',
    logoAsset: 'assets/icons/brands/L&B.svg',
    coverImageUrl: _kBrandCovers[1],
    businessModel: BusinessModel.coinvestment,
    tagline: 'Inversión colectiva en activos inmobiliarios de alto valor.',
    description:
        'Lacomb & Bos estructura oportunidades de Coinversión en activos residenciales y comerciales con alto potencial de retorno. La firma combina rigor analítico con acceso a operaciones fuera de mercado.\n\nCada proyecto se selecciona bajo criterios estrictos de ubicación, liquidez futura y calidad constructiva, garantizando la solidez de cada posición.',
    websiteUrl: 'https://lacombbos.com',
  ),
  BrandData(
    id: '3',
    name: 'Vellte',
    logoAsset: 'assets/icons/brands/vellte.svg',
    coverImageUrl: _kBrandCovers[2],
    businessModel: BusinessModel.coinvestment,
    tagline: 'Activos premium en destinos de alta demanda global.',
    description:
        'Vellte identifica activos inmobiliarios en destinos con demanda turística consolidada y creciente. Opera bajo un modelo de Coinversión que permite acceder a oportunidades de alta rentabilidad con tickets accesibles.\n\nLa firma gestiona todo el ciclo de la inversión: adquisición, reforma, explotación y desinversión, maximizando el retorno para el inversor.',
    websiteUrl: 'https://vellte.com',
  ),
  BrandData(
    id: '4',
    name: 'NUVE',
    logoAsset: 'assets/icons/brands/nuve.svg',
    coverImageUrl: _kBrandCovers[3],
    businessModel: BusinessModel.coinvestment,
    tagline: 'Donde la arquitectura efímera se convierte en patrimonio.',
    description:
        'NUVE apuesta por un concepto de inversión inmobiliaria ligado al diseño y la experiencia. Sus proyectos de Coinversión se desarrollan en ubicaciones icónicas con narrativa propia, atrayendo a un comprador o usuario de perfil premium.\n\nCada activo NUVE es concebido como una pieza única, con identidad visual y arquitectónica diferenciada del resto del mercado.',
    websiteUrl: 'https://nuve.es',
  ),
  BrandData(
    id: '5',
    name: 'Domorato',
    logoAsset: 'assets/icons/brands/domorato.svg',
    coverImageUrl: _kBrandCovers[4],
    businessModel: BusinessModel.coinvestment,
    tagline: 'Rehabilitación de patrimonio histórico para el inversor moderno.',
    description:
        'Domorato especializa su actividad en la rehabilitación de edificios históricos y su transformación en activos residenciales de alto valor. El modelo de Coinversión permite distribuir el riesgo preservando el potencial de apreciación.\n\nLa experiencia del equipo en edificación histórica garantiza intervenciones que respetan el carácter original del inmueble mientras elevan sus prestaciones contemporáneas.',
    websiteUrl: 'https://domorato.com',
  ),
  BrandData(
    id: '6',
    name: 'Andhy',
    logoAsset: 'assets/icons/brands/andhy.svg',
    coverImageUrl: _kBrandCovers[0],
    businessModel: BusinessModel.directPurchase,
    tagline: 'Sustainable luxury retreat blending seamlessly into the forest.',
    description:
        'Andhy desarrolla residencias de lujo sostenible en entornos naturales privilegiados. Un activo gestionado bajo el modelo Compra Directa, donde la fusión de ubicación privilegiada y diseño de autor garantiza la solidez de la inversión.\n\nCada proyecto Andhy es una declaración de intenciones: arquitectura que no compite con el paisaje, sino que lo celebra, creando activos únicos e irrepetibles.',
    websiteUrl: 'https://andhy.com',
  ),
  BrandData(
    id: '7',
    name: 'Ciclo',
    logoAsset: 'assets/icons/brands/ciclo.svg',
    coverImageUrl: _kBrandCovers[2],
    businessModel: BusinessModel.coinvestment,
    tagline: 'El ciclo completo de la inversión inmobiliaria.',
    description:
        'Ciclo aborda la inversión inmobiliaria en su totalidad, desde la identificación del activo hasta la desinversión optimizada. Su modelo de Coinversión ofrece al inversor una visión clara del horizonte temporal y la rentabilidad esperada.\n\nLa disciplina de proceso es la seña de identidad de Ciclo: cada etapa del proyecto está planificada y ejecutada con precisión milimétrica.',
    websiteUrl: 'https://ciclo.es',
  ),
  BrandData(
    id: '8',
    name: 'Renta Fija',
    coverImageUrl: _kBrandCovers[3],
    businessModel: BusinessModel.fixedIncome,
    tagline: 'Rentabilidad predecible respaldada por activos inmobiliarios.',
    description:
        'Renta Fija ofrece instrumentos de deuda inmobiliaria con rentabilidad definida y plazo determinado. El modelo de Renta Fija permite al inversor conocer de antemano su retorno, con la seguridad que aporta el respaldo de activos tangibles.\n\nIdeal para perfiles que buscan complementar su cartera con activos de baja volatilidad y flujo de caja predecible, sin renunciar a la solidez del sector inmobiliario.',
    websiteUrl: 'https://rentafija.lhotsegroup.com',
  ),
  // New brands (firmas only — no investments/projects yet)
  BrandData(
    id: '9',
    name: 'Casa Tessela',
    logoAsset: 'assets/icons/brands/casaTessela.svg',
    coverImageUrl: _kBrandCovers[0],
    businessModel: BusinessModel.directPurchase,
    tagline: 'Vivienda singular en entornos urbanos consolidados.',
    description:
        'Casa Tessela identifica y transforma viviendas singulares en los mejores barrios de las principales capitales. El modelo de Compra Directa garantiza al inversor la propiedad plena de un activo con historia y potencial de revalorización demostrado.\n\nCada intervención de Casa Tessela respeta la identidad del inmueble original mientras introduce las prestaciones que demanda el comprador contemporáneo.',
    websiteUrl: 'https://casatessela.com',
  ),
  BrandData(
    id: '10',
    name: 'Llabe',
    logoAsset: 'assets/icons/brands/llabe.svg',
    coverImageUrl: _kBrandCovers[1],
    businessModel: BusinessModel.coinvestment,
    tagline: 'La llave de acceso a oportunidades inmobiliarias exclusivas.',
    description:
        'Llabe actúa como puerta de acceso a operaciones inmobiliarias que habitualmente quedan fuera del alcance del inversor individual. Su modelo de Coinversión democratiza el acceso a activos prime sin renunciar a la calidad de la operación.\n\nEl equipo de Llabe cuenta con una red de relaciones que le permite identificar oportunidades antes de que salgan al mercado abierto.',
    websiteUrl: 'https://llabe.com',
  ),
  BrandData(
    id: '11',
    name: 'Nytido',
    logoAsset: 'assets/icons/brands/nytido.svg',
    coverImageUrl: _kBrandCovers[2],
    businessModel: BusinessModel.coinvestment,
    tagline: 'Proyectos residenciales de nueva generación.',
    description:
        'Nytido desarrolla proyectos residenciales que integran tecnología, sostenibilidad y diseño en una propuesta coherente y diferenciada. La Coinversión permite a sus socios participar en el ciclo completo de desarrollo desde etapas tempranas.\n\nLa marca tiene una visión clara sobre el futuro del habitar: espacios inteligentes, eficientes y bellos que respondan a las necesidades del residente del siglo XXI.',
    websiteUrl: 'https://nytido.com',
  ),
  BrandData(
    id: '12',
    name: 'Comono',
    logoAsset: 'assets/icons/brands/comono.svg',
    coverImageUrl: _kBrandCovers[3],
    businessModel: BusinessModel.directPurchase,
    tagline: 'Activos comerciales en ubicaciones de máxima visibilidad.',
    description:
        'Comono se especializa en activos de uso comercial situados en ubicaciones de alta afluencia y visibilidad. El modelo de Compra Directa ofrece al inversor la propiedad de un inmueble con rentas estables y locatarios de primer nivel.\n\nLa selección de activos Comono responde a criterios de tráfico peatonal, singularidad arquitectónica y potencial de transformación de uso.',
    websiteUrl: 'https://comono.es',
  ),
  BrandData(
    id: '13',
    name: 'Ammaca',
    logoAsset: 'assets/icons/brands/ammaca.svg',
    coverImageUrl: _kBrandCovers[4],
    businessModel: BusinessModel.coinvestment,
    tagline: 'Inversión alternativa con alma inmobiliaria.',
    description:
        'Ammaca explora la intersección entre el sector inmobiliario y los activos alternativos, creando estructuras de Coinversión innovadoras adaptadas a inversores sofisticados. Su enfoque interdisciplinar combina análisis financiero riguroso con una visión creativa del mercado.\n\nCada operación de Ammaca es diseñada a medida, con estructuras de rentabilidad que responden al perfil y horizonte temporal de sus socios inversores.',
    websiteUrl: 'https://ammaca.com',
  ),
];
