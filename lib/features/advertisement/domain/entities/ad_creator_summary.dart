/// Advertisement creator reference, independent of the authenticated user.
/// Legacy contact presentation fields remain optional.
class AdCreatorSummary {
  const AdCreatorSummary({this.id, this.name, this.phone, this.profile});

  factory AdCreatorSummary.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'];
    return AdCreatorSummary(
      id: json['id'] as int?,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      profile: profile is Map<String, dynamic>
          ? AdCreatorProfile.fromJson(profile)
          : null,
    );
  }

  final int? id;
  final String? name;
  final String? phone;
  final AdCreatorProfile? profile;
}

class AdCreatorProfile {
  const AdCreatorProfile({this.name, this.phone, this.profileImage});

  factory AdCreatorProfile.fromJson(Map<String, dynamic> json) =>
      AdCreatorProfile(
        name: json['name'] as String?,
        phone: json['phone'] as String?,
        profileImage: json['profile_image'] as String?,
      );

  final String? name;
  final String? phone;
  final String? profileImage;
}
