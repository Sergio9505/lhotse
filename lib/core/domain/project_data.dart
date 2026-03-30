enum ProjectStatus { enDesarrollo, firmas, cerrado }

class ProjectData {
  const ProjectData({
    required this.id,
    required this.name,
    required this.brand,
    required this.architect,
    required this.location,
    required this.address,
    required this.imageUrl,
    required this.tagline,
    required this.description,
    this.galleryImages = const [],
    this.isVip = false,
    this.status = ProjectStatus.enDesarrollo,
  });

  final String id;
  final String name;
  final String brand;
  final String architect;
  final String location;
  final String address;
  final String imageUrl;
  final String tagline;
  final String description;
  final List<String> galleryImages;
  final bool isVip;
  final ProjectStatus status;
}
