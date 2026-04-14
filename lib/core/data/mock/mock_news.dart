enum NewsType { proyectos, prensa }

class NewsItemData {
  const NewsItemData({
    required this.id,
    required this.title,
    required this.brand,
    required this.region,
    required this.subtitle,
    required this.imageUrl,
    required this.date,
    required this.type,
    this.hasPlayButton = false,
    this.body = '',
  });

  final String id;
  final String title;
  final String brand;
  final String region;
  final String subtitle;
  final String imageUrl;
  final String date;
  final NewsType type;
  final bool hasPlayButton;
  final String body;
}

NewsItemData? findNewsById(String id) {
  for (final news in mockNews) {
    if (news.id == id) return news;
  }
  return null;
}

const _kNewsImages = [
  'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=600&q=80',
  'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=600&q=80',
  'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=600&q=80',
  'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=600&q=80',
  'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=600&q=80',
];

final mockNews = [
  NewsItemData(
    id: 'n1',
    title: 'Visión 2025: Carta del CEO',
    brand: 'Lhotse Group',
    region: 'España',
    subtitle: 'Video Brief — 3:45',
    imageUrl: _kNewsImages[0],
    date: '28 MAR. 2026',
    type: NewsType.prensa,
    hasPlayButton: true,
    body:
        'El CEO de Lhotse Group presenta la visión estratégica para 2025, un año marcado por la consolidación internacional del grupo y la apertura de nuevos mercados en la región del Golfo.\n\n'
        'Con un portfolio que supera los 200 millones de euros en activos gestionados, la compañía refuerza su compromiso con la inversión inmobiliaria de autor, donde la arquitectura y la ubicación se convierten en los pilares de la rentabilidad a largo plazo.\n\n'
        'En esta carta anual, se detallan los hitos alcanzados durante el ejercicio anterior y las líneas estratégicas que guiarán la actividad del grupo en los próximos doce meses.',
  ),
  NewsItemData(
    id: 'n2',
    title: 'Avance de Obra: Allegro',
    brand: 'Lacomb & Bos',
    region: 'España',
    subtitle: 'Marbella, ES',
    imageUrl: _kNewsImages[2],
    date: '25 MAR. 2026',
    type: NewsType.proyectos,
    body:
        'Las obras de Allegro avanzan según el calendario previsto. La estructura principal se encuentra finalizada al cien por cien y se ha iniciado la fase de cerramientos exteriores con los materiales de primera calidad seleccionados por el estudio de arquitectura a cargo del proyecto.\n\n'
        'La fachada ventilada de piedra natural, seña de identidad del edificio, comenzará a instalarse en las próximas semanas. El equipo técnico confirma que los plazos de entrega se mantienen dentro de las previsiones iniciales acordadas con los inversores.\n\n'
        'Los avances fotográficos del proyecto están disponibles en el área privada. El siguiente informe de obra se publicará el próximo mes.',
  ),
  NewsItemData(
    id: 'n3',
    title: 'Nuevo proyecto Azura en Ibiza',
    brand: 'Vellte',
    region: 'España',
    subtitle: 'Ibiza, ES',
    imageUrl: _kNewsImages[4],
    date: '20 MAR. 2026',
    type: NewsType.proyectos,
    body:
        'Vellte presenta Azura, su nuevo proyecto residencial en primera línea de mar en Ibiza. Un conjunto de ocho villas de autor diseñadas por el estudio Marcio Kogan, con vistas panorámicas al Mediterráneo y acceso directo a playa privada.\n\n'
        'El proyecto, con una inversión total estimada en 45 millones de euros, está previsto para su entrega en el tercer trimestre de 2027. Las unidades disponibles oscilan entre los 280 y los 450 metros cuadrados construidos, con acabados de máxima calidad y domótica integrada.\n\n'
        'La comercialización exclusiva se realizará entre inversores cualificados del grupo durante las próximas semanas. Contacte con su asesor para obtener el dossier completo del proyecto.',
  ),
  NewsItemData(
    id: 'n4',
    title: 'Miami Shores: fase 4 completada',
    brand: 'Ciclo',
    region: 'EE.UU.',
    subtitle: 'Miami, US',
    imageUrl: _kNewsImages[1],
    date: '15 MAR. 2026',
    type: NewsType.proyectos,
    body:
        'El proyecto Miami Shores alcanza un nuevo hito con la finalización de la cuarta y última fase de construcción. Los 32 apartamentos de esta etapa han obtenido el certificado de fin de obra por parte de las autoridades municipales del condado de Miami-Dade.\n\n'
        'La entrega de llaves a los inversores está programada para el próximo mes de mayo, en un acto que reunirá a los principales socios del proyecto en las instalaciones del complejo.\n\n'
        'El retorno acumulado del proyecto supera en un 3,2% las proyecciones iniciales, consolidando a Miami Shores como uno de los activos de mayor rendimiento en el portfolio de Ciclo durante el ejercicio 2025.',
  ),
  NewsItemData(
    id: 'n5',
    title: 'Myttas presenta Casa Poema',
    brand: 'Myttas',
    region: 'España',
    subtitle: 'Madrid, ES',
    imageUrl: _kNewsImages[3],
    date: '10 MAR. 2026',
    type: NewsType.proyectos,
    hasPlayButton: true,
    body:
        'Myttas presenta Casa Poema, un proyecto residencial singular en el corazón del barrio de Salamanca de Madrid. La propuesta, firmada por el arquitecto Rafael de La-Hoz, recupera un edificio de principios del siglo XX con una intervención que respeta la arquitectura original y la dota de todos los estándares del lujo contemporáneo.\n\n'
        'Con tan solo cinco viviendas únicas de entre 300 y 600 metros cuadrados, Casa Poema representa la apuesta más selectiva de Myttas hasta la fecha. La comercialización se realiza en exclusiva a través del canal de inversores del grupo.\n\n'
        'El vídeo de presentación del proyecto está disponible a continuación. Para solicitar información detallada, contacte con su asesor personal.',
  ),
  NewsItemData(
    id: 'n6',
    title: 'Cabriole Monterrey: avance de obra',
    brand: 'Myttas',
    region: 'México',
    subtitle: 'Monterrey, MX',
    imageUrl: _kNewsImages[0],
    date: '05 MAR. 2026',
    type: NewsType.proyectos,
    body:
        'Las obras de Cabriole Monterrey siguen su curso favorable. En el último periodo se ha concluido la cimentación profunda y se ha iniciado la elevación de la estructura de hormigón armado, que alcanzará los doce pisos sobre rasante.\n\n'
        'El proyecto, ubicado en la zona de Valle Oriente de Monterrey, incorpora tecnología antisísmica de última generación y sistemas de eficiencia energética certificados bajo el estándar LEED Gold. La entrega está prevista para el segundo trimestre de 2027.\n\n'
        'La ocupación proyectada de las unidades residenciales supera el 85% antes del inicio de la fase de comercialización formal, lo que refleja el interés del mercado local por la propuesta de Myttas en la región.',
  ),
  NewsItemData(
    id: 'n7',
    title: 'Andhy: nueva promoción en Marbella',
    brand: 'Andhy',
    region: 'España',
    subtitle: 'Marbella, ES',
    imageUrl: _kNewsImages[2],
    date: '28 FEB. 2026',
    type: NewsType.proyectos,
    body:
        'Andhy lanza una nueva promoción residencial en la Milla de Oro de Marbella, consolidando su presencia en uno de los mercados de lujo más dinámicos del sur de Europa. El proyecto contempla 18 apartamentos de dos y tres dormitorios con amplias terrazas y vistas al mar.\n\n'
        'El diseño corre a cargo del reconocido estudio malagueño Proyecto Larena, que ha diseñado un conjunto que dialoga con el entorno mediterráneo a través del uso del blanco, la piedra local y la vegetación autóctona.\n\n'
        'La inversión mínima para participar en esta promoción es de 250.000 euros. Las condiciones completas están disponibles en el dossier de inversión, accesible a través de su área privada.',
  ),
  NewsItemData(
    id: 'n8',
    title: 'Arcadia Dubai: hito de construcción',
    brand: 'Vellte',
    region: 'EAU',
    subtitle: 'Dubai, AE',
    imageUrl: _kNewsImages[1],
    date: '20 FEB. 2026',
    type: NewsType.proyectos,
    body:
        'El proyecto Arcadia Dubai alcanza un hito significativo con la finalización de la estructura de la torre principal, que se eleva ya a sus 47 pisos de altura sobre el skyline de Dubai Marina. El evento ha sido celebrado con una ceremonia de topping out a la que asistieron los principales inversores del proyecto.\n\n'
        'Arcadia Dubai es el proyecto de mayor envergadura de Vellte hasta la fecha, con una inversión total de 180 millones de dólares y una superficie construida superior a los 45.000 metros cuadrados. Las unidades residenciales de las últimas quince plantas cuentan con vistas garantizadas al Golfo Pérsico.\n\n'
        'La entrega de las primeras unidades está prevista para el primer trimestre de 2027, en línea con las previsiones iniciales del proyecto.',
  ),
  NewsItemData(
    id: 'n9',
    title: 'NUVE obtiene licencia en Barcelona',
    brand: 'NUVE',
    region: 'España',
    subtitle: 'Barcelona, ES',
    imageUrl: _kNewsImages[4],
    date: '15 FEB. 2026',
    type: NewsType.prensa,
    body:
        'NUVE ha obtenido la licencia de obras del Ayuntamiento de Barcelona para su proyecto en el Eixample, un hito que abre el camino al inicio de los trabajos de construcción previstos para el próximo mes de junio.\n\n'
        'La aprobación, que ha requerido un proceso administrativo de dieciséis meses, supone el respaldo institucional a un proyecto que respeta los criterios urbanísticos del Plan Especial de Reforma Interior del Eixample y contribuye a la rehabilitación del tejido edificatorio del distrito.\n\n'
        'Con esta licencia, NUVE confirma su capacidad para operar en los mercados regulados más exigentes de Europa, reforzando su posicionamiento como promotora de referencia en el segmento residencial de alta gama en España.',
  ),
  NewsItemData(
    id: 'n10',
    title: 'Onyx Lisboa: presentación a inversores',
    brand: 'Andhy',
    region: 'Portugal',
    subtitle: 'Lisboa, PT',
    imageUrl: _kNewsImages[3],
    date: '10 FEB. 2026',
    type: NewsType.prensa,
    body:
        'Andhy presentó en exclusiva el proyecto Onyx Lisboa a un grupo selecto de inversores cualificados en un evento celebrado en el Hotel Bairro Alto de Lisboa. La velada, que contó con la presencia del equipo directivo de Andhy y del arquitecto responsable del proyecto, reunió a más de cuarenta inversores del grupo.\n\n'
        'Onyx Lisboa es un conjunto residencial de doce unidades ubicado en el barrio histórico de Príncipe Real, con vistas al Tajo y a la colina de São Jorge. El proyecto recupera un palacete del siglo XVIII dotándolo de los más altos estándares residenciales, en línea con la filosofía de intervención cuidadosa que caracteriza a Andhy.\n\n'
        'La comercialización de las unidades restantes se realizará en los próximos meses, en exclusiva entre inversores del grupo. Para solicitar el dossier, contacte con su asesor.',
  ),
];

List<String> get newsRegions =>
    mockNews.map((n) => n.region).toSet().toList()..sort();

List<String> get newsBrands =>
    mockNews.map((n) => n.brand).toSet().toList()..sort();
