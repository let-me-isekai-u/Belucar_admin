class VoucherStatisticModel {
  final int voucherId;
  final String code;
  final String name;
  final int discountPercent;
  final int totalRides;
  final double totalRevenue;
  final bool isActive;
  final DateTime createdDate;

  VoucherStatisticModel({
    required this.voucherId,
    required this.code,
    required this.name,
    required this.discountPercent,
    required this.totalRides,
    required this.totalRevenue,
    required this.isActive,
    required this.createdDate,
  });

  factory VoucherStatisticModel.fromJson(Map<String, dynamic> json) {
    return VoucherStatisticModel(
      voucherId: json['voucherId'],
      code: json['code'],
      name: json['name'],
      discountPercent: json['discountPercent'],
      totalRides: json['totalRides'],
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      isActive: json['isActive'],
      createdDate: DateTime.parse(json['createdDate']),
    );
  }
}
