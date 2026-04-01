import '../../domain/brand_data.dart';

const _kBrandCovers = [
  'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?w=800&q=80',
  'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800&q=80',
  'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=800&q=80',
  'https://images.unsplash.com/photo-1600585154526-990dced4db0d?w=800&q=80',
  'https://images.unsplash.com/photo-1600573472592-401b489a3cdc?w=800&q=80',
];

final mockBrands = [
  BrandData(
    id: '1',
    name: 'Myttas',
    logoAsset: 'assets/icons/brands/myttas.svg',
    coverImageUrl: _kBrandCovers[0],
    businessModel: BusinessModel.compraDirecta,
  ),
  BrandData(
    id: '2',
    name: 'Lacomb & Bos',
    logoAsset: 'assets/icons/brands/lacomb_bos.svg',
    coverImageUrl: _kBrandCovers[1],
    businessModel: BusinessModel.coinversion,
  ),
  BrandData(
    id: '3',
    name: 'Vellte',
    logoAsset: 'assets/icons/brands/vellte.svg',
    coverImageUrl: _kBrandCovers[2],
    businessModel: BusinessModel.coinversion,
  ),
  BrandData(
    id: '4',
    name: 'NUVE',
    logoAsset: 'assets/icons/brands/nuve.svg',
    coverImageUrl: _kBrandCovers[3],
    businessModel: BusinessModel.coinversion,
  ),
  BrandData(
    id: '5',
    name: 'Domorato',
    logoAsset: 'assets/icons/brands/domorato.svg',
    coverImageUrl: _kBrandCovers[4],
    businessModel: BusinessModel.coinversion,
  ),
  BrandData(
    id: '6',
    name: 'Andhy',
    coverImageUrl: _kBrandCovers[0],
    businessModel: BusinessModel.compraDirecta,
  ),
  BrandData(
    id: '7',
    name: 'Ciclo',
    coverImageUrl: _kBrandCovers[2],
    businessModel: BusinessModel.coinversion,
  ),
  BrandData(
    id: '8',
    name: 'Renta Fija',
    coverImageUrl: _kBrandCovers[3],
    businessModel: BusinessModel.rentaFija,
  ),
];
