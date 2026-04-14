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
  ),
];

List<String> get newsRegions =>
    mockNews.map((n) => n.region).toSet().toList()..sort();

List<String> get newsBrands =>
    mockNews.map((n) => n.brand).toSet().toList()..sort();
