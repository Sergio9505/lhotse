import '../../domain/project_data.dart';

const _kProjectImages = [
  'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800&q=80',
  'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=800&q=80',
  'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&q=80',
  'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&q=80',
  'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=800&q=80',
  'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800&q=80',
];

const _kGalleryImages = [
  'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=600&q=80',
  'https://images.unsplash.com/photo-1600585154526-990dced4db0d?w=600&q=80',
  'https://images.unsplash.com/photo-1600573472592-401b489a3cdc?w=600&q=80',
];

final mockProjects = [
  ProjectData(
    id: '1',
    name: 'Allegro',
    brand: 'Lacomb & Bos',
    architect: 'Studio Lamela',
    location: 'Marbella, ES',
    address: 'Ayala 96, Madrid',
    imageUrl: _kProjectImages[0],
    tagline:
        'Sustainable luxury retreat blending seamlessly into the forest topography.',
    description:
        'Un activo gestionado bajo el modelo **Compra-Venta**. La fusión de ubicación privilegiada y diseño de autor garantiza la solidez de la inversión.\n\nUn activo gestionado bajo el modelo **Compra-Venta**. La fusión de ubicación privilegiada y diseño de autor garantiza la solidez de la inversión.',
    galleryImages: _kGalleryImages,
    status: ProjectStatus.enDesarrollo,
  ),
  ProjectData(
    id: '2',
    name: 'Allegro 2',
    brand: 'Lacomb & Bos',
    architect: 'Studio Lamela',
    location: 'Madrid, ES',
    address: 'Paseo de la Castellana 45, Madrid',
    imageUrl: _kProjectImages[1],
    tagline:
        'Oceanfront villas designed for effortless living and long-term value.',
    description:
        'Un activo gestionado bajo el modelo **Alquiler Vacacional**. Ubicación frente al mar con rentabilidad demostrada en el corredor turístico de la Costa del Sol.\n\nEl proyecto combina arquitectura contemporánea con materiales locales, creando un producto de inversión con identidad propia.',
    galleryImages: [_kGalleryImages[0], _kGalleryImages[1]],
    isVip: true,
    status: ProjectStatus.firmas,
  ),
  ProjectData(
    id: '3',
    name: 'Cabriole',
    brand: 'Myttas',
    architect: 'Despacho Norte',
    location: 'Monterrey, MX',
    address: 'Av. Vasconcelos 1450, San Pedro',
    imageUrl: _kProjectImages[2],
    tagline:
        'Mountain living redefined with panoramic views and urban connectivity.',
    description:
        'Un activo gestionado bajo el modelo **Renta Fija**. Proyecto residencial premium en la zona de mayor plusvalía de Monterrey.\n\nLa proximidad al centro financiero y las vistas a la Sierra Madre lo posicionan como referente en el mercado de lujo regiomontano.',
    galleryImages: [_kGalleryImages[1], _kGalleryImages[2]],
    status: ProjectStatus.enDesarrollo,
  ),
  ProjectData(
    id: '4',
    name: 'Cabriole 2',
    brand: 'Vellte',
    architect: 'Arq. Fernanda Ruiz',
    location: 'Tulum, MX',
    address: 'Carretera Tulum-Boca Paila Km 7',
    imageUrl: _kProjectImages[3],
    tagline:
        'A biophilic sanctuary where nature and architecture become one.',
    description:
        'Un activo gestionado bajo el modelo **Compra-Venta**. Integración total con el entorno natural de la Riviera Maya, respetando los cenotes y la vegetación nativa.\n\nDiseño biofílico que maximiza la conexión con la naturaleza sin comprometer el confort ni la exclusividad.',
    galleryImages: [_kGalleryImages[0]],
    status: ProjectStatus.cerrado,
  ),
  ProjectData(
    id: '5',
    name: 'SISONE',
    brand: 'NUVE',
    architect: 'Colectivo MX',
    location: 'Guadalajara, MX',
    address: 'Av. Américas 1500, Providencia',
    imageUrl: _kProjectImages[4],
    tagline:
        'Mixed-use development at the heart of Mexico\'s innovation corridor.',
    description:
        'Un activo gestionado bajo el modelo **Compra-Venta**. Desarrollo de uso mixto en el epicentro tecnológico de Guadalajara.\n\nCombina espacios residenciales, comerciales y de coworking en un concepto integrado orientado a la nueva economía digital.',
    galleryImages: [_kGalleryImages[2], _kGalleryImages[0]],
    status: ProjectStatus.firmas,
  ),
  ProjectData(
    id: '6',
    name: 'SISONE II',
    brand: 'Domorato',
    architect: 'Studio Volta',
    location: 'Los Cabos, MX',
    address: 'Paseo del Mar 12, Los Cabos',
    imageUrl: _kProjectImages[5],
    tagline:
        'Coastal architecture that captures the essence of Baja California.',
    description:
        'Un activo gestionado bajo el modelo **Alquiler Vacacional**. Ubicación estratégica en el corredor turístico de Los Cabos con alta demanda internacional.\n\nArquitectura costera que respeta el paisaje desértico y maximiza las vistas al Pacífico, generando un activo de alto rendimiento.',
    galleryImages: [_kGalleryImages[1], _kGalleryImages[2]],
    isVip: true,
    status: ProjectStatus.enDesarrollo,
  ),
  // Extra projects for brands with only 1
  ProjectData(
    id: '7',
    name: 'Velorum',
    brand: 'Myttas',
    architect: 'Estudio Barclay',
    location: 'Madrid, ES',
    address: 'Serrano 78, Madrid',
    imageUrl: _kProjectImages[1],
    tagline: 'Urban elegance in the heart of the Salamanca district.',
    description:
        'Un activo gestionado bajo el modelo **Compra-Venta**. Ubicación prime en el distrito de Salamanca con demanda sostenida.\n\nDiseño interior de firma con acabados de alta gama y domótica integrada.',
    galleryImages: [_kGalleryImages[0]],
    status: ProjectStatus.enDesarrollo,
  ),
  ProjectData(
    id: '8',
    name: 'Arcadia',
    brand: 'Vellte',
    architect: 'Zaha Hadid Architects',
    location: 'Dubai, AE',
    address: 'Palm Jumeirah, Dubai',
    imageUrl: _kProjectImages[3],
    tagline: 'Iconic waterfront living on the Palm.',
    description:
        'Un activo gestionado bajo el modelo **Alquiler Vacacional**. Posición estratégica en Palm Jumeirah con vistas panorámicas al skyline de Dubai.\n\nArquitectura de autor que combina líneas orgánicas con funcionalidad residencial de ultra-lujo.',
    galleryImages: [_kGalleryImages[1], _kGalleryImages[2]],
    isVip: true,
    status: ProjectStatus.firmas,
  ),
  ProjectData(
    id: '9',
    name: 'Luminar',
    brand: 'NUVE',
    architect: 'Foster + Partners',
    location: 'Barcelona, ES',
    address: 'Passeig de Gràcia 112, Barcelona',
    imageUrl: _kProjectImages[0],
    tagline: 'Where Catalan heritage meets contemporary vision.',
    description:
        'Un activo gestionado bajo el modelo **Compra-Venta**. Rehabilitación integral de un edificio histórico en el Eixample con certificación LEED Platinum.\n\nCada unidad preserva elementos arquitectónicos originales junto con instalaciones de última generación.',
    galleryImages: [_kGalleryImages[0], _kGalleryImages[1]],
    status: ProjectStatus.enDesarrollo,
  ),
  ProjectData(
    id: '10',
    name: 'Terracota',
    brand: 'Domorato',
    architect: 'David Chipperfield',
    location: 'Mallorca, ES',
    address: 'Carrer de la Mar 23, Deià',
    imageUrl: _kProjectImages[2],
    tagline: 'Mediterranean serenity carved into the Tramuntana.',
    description:
        'Un activo gestionado bajo el modelo **Alquiler Vacacional**. Enclave exclusivo en Deià con acceso privado al mar y vistas a la Sierra de Tramuntana.\n\nMateriales locales (piedra de marès, madera de olivo) integran cada villa en el paisaje mallorquín.',
    galleryImages: [_kGalleryImages[2]],
    status: ProjectStatus.firmas,
  ),
  // New brands projects
  ProjectData(
    id: '11',
    name: 'Andhy I',
    brand: 'Andhy',
    architect: 'BIG Architects',
    location: 'Madrid, ES',
    address: 'Calle Velázquez 34, Madrid',
    imageUrl: _kProjectImages[4],
    tagline: 'A bold reimagining of urban wealth creation.',
    description:
        'Un activo gestionado bajo el modelo **Compra-Venta**. Desarrollo residencial de alta gama en el corazón de Madrid con rentabilidad demostrada.\n\nConcepto arquitectónico innovador que maximiza la eficiencia energética y la experiencia del residente.',
    galleryImages: [_kGalleryImages[0], _kGalleryImages[1]],
    status: ProjectStatus.enDesarrollo,
  ),
  ProjectData(
    id: '12',
    name: 'Andhy II',
    brand: 'Andhy',
    architect: 'BIG Architects',
    location: 'Marbella, ES',
    address: 'Urb. Sierra Blanca, Marbella',
    imageUrl: _kProjectImages[5],
    tagline: 'Exclusive villas where the mountains meet the sea.',
    description:
        'Un activo gestionado bajo el modelo **Compra-Venta**. Villas exclusivas en Sierra Blanca con vistas al Mediterráneo y total privacidad.\n\nCada villa es una pieza única diseñada para el inversor que busca un activo tangible de alta revalorización.',
    galleryImages: [_kGalleryImages[1]],
    isVip: true,
    status: ProjectStatus.firmas,
  ),
  ProjectData(
    id: '13',
    name: 'Miami Shores',
    brand: 'Ciclo',
    architect: 'OMA',
    location: 'Miami, US',
    address: '1200 Brickell Ave, Miami',
    imageUrl: _kProjectImages[1],
    tagline: 'Cyclical returns in America\'s gateway city.',
    description:
        'Un activo gestionado bajo el modelo **Ciclo**. Desarrollo residencial en Brickell con horizonte de inversión de 36 meses y rentabilidad objetivo del 18%.\n\nMercado con alta demanda de alquiler y revalorización sostenida en el corredor financiero de Miami.',
    galleryImages: [_kGalleryImages[2], _kGalleryImages[0]],
    status: ProjectStatus.enDesarrollo,
  ),
  ProjectData(
    id: '14',
    name: 'Miami Bay',
    brand: 'Ciclo',
    architect: 'OMA',
    location: 'Miami, US',
    address: '800 NE 1st Ave, Miami',
    imageUrl: _kProjectImages[3],
    tagline: 'Premium waterfront development in the Arts District.',
    description:
        'Un activo gestionado bajo el modelo **Ciclo**. Segundo proyecto Ciclo en Miami, enfocado en el distrito de artes con potencial de revalorización acelerada.\n\nUbicación estratégica junto al Pérez Art Museum y el Adrienne Arsht Center.',
    galleryImages: [_kGalleryImages[1]],
    status: ProjectStatus.enDesarrollo,
  ),
  ProjectData(
    id: '15',
    name: 'RF Capital I',
    brand: 'Renta Fija',
    architect: '',
    location: 'Madrid, ES',
    address: '',
    imageUrl: _kProjectImages[0],
    tagline: 'Stable returns backed by prime real estate assets.',
    description:
        'Producto de **Renta Fija** respaldado por activos inmobiliarios prime en Madrid. Rentabilidad fija del 5% anual con capital garantizado.\n\nIdeal para el inversor que busca estabilidad y predictibilidad en su cartera patrimonial.',
    galleryImages: [],
    status: ProjectStatus.enDesarrollo,
  ),
  ProjectData(
    id: '16',
    name: 'RF Capital II',
    brand: 'Renta Fija',
    architect: '',
    location: 'Barcelona, ES',
    address: '',
    imageUrl: _kProjectImages[2],
    tagline: 'Fixed income with real estate security.',
    description:
        'Producto de **Renta Fija** respaldado por cartera diversificada de activos en Barcelona. Rentabilidad fija del 4,5% anual.\n\nEstructura de inversión conservadora con horizonte de 24 meses y liquidez trimestral.',
    galleryImages: [],
    status: ProjectStatus.enDesarrollo,
  ),
  // Available opportunities (no investments yet)
  ProjectData(
    id: '17',
    name: 'Azura',
    brand: 'Vellte',
    architect: 'Tadao Ando',
    location: 'Ibiza, ES',
    address: 'Cala Conta, Sant Josep',
    imageUrl: _kProjectImages[5],
    tagline: 'Minimalist luxury where land meets the Mediterranean.',
    description:
        'Un activo gestionado bajo el modelo **Alquiler Vacacional**. Ubicación premium en la costa oeste de Ibiza con vistas al atardecer.\n\nArquitectura brutalista japonesa fusionada con la tradición ibicenca, creando un activo único en el mercado.',
    galleryImages: [_kGalleryImages[0], _kGalleryImages[2]],
    status: ProjectStatus.enDesarrollo,
  ),
  ProjectData(
    id: '18',
    name: 'Onyx',
    brand: 'Andhy',
    architect: 'Herzog & de Meuron',
    location: 'Lisboa, PT',
    address: 'Av. da Liberdade 180, Lisboa',
    imageUrl: _kProjectImages[1],
    tagline: 'A golden visa gateway in Europe\'s hottest capital.',
    description:
        'Un activo gestionado bajo el modelo **Compra-Venta**. Rehabilitación de palacete en la Avenida da Liberdade, la arteria más exclusiva de Lisboa.\n\nAcceso al programa Golden Visa y rentabilidad estimada del 20% en un mercado en plena expansión.',
    galleryImages: [_kGalleryImages[1]],
    isVip: true,
    status: ProjectStatus.enDesarrollo,
  ),
  ProjectData(
    id: '19',
    name: 'Zenith',
    brand: 'Myttas',
    architect: 'Renzo Piano',
    location: 'Málaga, ES',
    address: 'Paseo Marítimo Pablo Ruiz Picasso, Málaga',
    imageUrl: _kProjectImages[3],
    tagline: 'Waterfront towers redefining the Costa del Sol skyline.',
    description:
        'Un activo gestionado bajo el modelo **Compra-Venta**. Torres residenciales de alta gama en primera línea de playa con marina privada.\n\nMálaga se consolida como destino de inversión premium con conectividad internacional y calidad de vida mediterránea.',
    galleryImages: [_kGalleryImages[0], _kGalleryImages[1]],
    status: ProjectStatus.firmas,
  ),
  ProjectData(
    id: '20',
    name: 'Nómada',
    brand: 'Ciclo',
    architect: 'Bjarke Ingels Group',
    location: 'Ciudad de México, MX',
    address: 'Polanco, Ciudad de México',
    imageUrl: _kProjectImages[4],
    tagline: 'Cyclical returns in Latin America\'s financial capital.',
    description:
        'Un activo gestionado bajo el modelo **Ciclo**. Desarrollo residencial premium en Polanco con horizonte de inversión de 30 meses.\n\nMercado con demanda sostenida de vivienda de lujo y revalorización acelerada en la zona financiera.',
    galleryImages: [_kGalleryImages[2]],
    status: ProjectStatus.enDesarrollo,
  ),
];

ProjectData? findProjectById(String id) {
  for (final project in mockProjects) {
    if (project.id == id) return project;
  }
  return null;
}
