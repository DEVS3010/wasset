import 'package:equatable/equatable.dart';
import 'package:waseet/features/user/domain/entities/cities_entity.dart';

class CitiesModel extends Equatable {
  const CitiesModel({this.id, this.name, this.image, this.createdAt});

  factory CitiesModel.fromJson(Map<String, dynamic> json) => CitiesModel(
        id: json['id'] as int?,
        name: json['name'] as String?,
        image: json['image'] as String?,
        createdAt: json['created_at'] == null
            ? null
            : DateTime.tryParse(json['created_at'].toString()),
      );
  final int? id;
  final String? name;
  final String? image;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image': image,
        'created_at': createdAt?.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        name,
        image,
      ];

  CitiesEntity toEntity() {
    return CitiesEntity(
      id: id!,
      name: name!,
      image: image!,
    );
  }
}
