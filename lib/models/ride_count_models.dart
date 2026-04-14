class ProvinceRideCountDto {
  final int id;
  final String name;

  ProvinceRideCountDto({
    required this.id,
    required this.name,
  });

  factory ProvinceRideCountDto.fromJson(Map<String, dynamic> json) {
    return ProvinceRideCountDto(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class DistrictRideCountDto {
  final int id;
  final String name;

  DistrictRideCountDto({
    required this.id,
    required this.name,
  });

  factory DistrictRideCountDto.fromJson(Map<String, dynamic> json) {
    return DistrictRideCountDto(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}