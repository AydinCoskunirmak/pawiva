import 'dart:io';

class PetProfile {
  final String name;
  final String type;
  final File? image;

  PetProfile({
    required this.name,
    required this.type,
    this.image,
  });

  factory PetProfile.fromJson(Map<String, dynamic> json) => PetProfile(
    name: json['name'] as String,
    type: json['type'] as String,
    image: json['imagePath'] != null ? File(json['imagePath'] as String) : null,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'imagePath': image?.path,
  };
}
