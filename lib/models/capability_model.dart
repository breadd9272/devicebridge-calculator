class CapabilityModel {
  final String id;
  final String name;
  final String description;
  bool isAvailable;
  bool hasPermission;

  CapabilityModel({
    required this.id,
    required this.name,
    required this.description,
    this.isAvailable = true,
    this.hasPermission = true,
  });
}