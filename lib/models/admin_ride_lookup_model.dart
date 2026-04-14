class AdminRideLookupModel {
  final int rideId;
  final String code;
  final DateTime? createdDate;
  final DateTime? pickupTime;
  final double price;
  final String fromAddress;
  final String toAddress;
  final String paymentMethod;
  final String type;

  AdminRideLookupModel({
    required this.rideId,
    required this.code,
    required this.createdDate,
    required this.pickupTime,
    required this.price,
    required this.fromAddress,
    required this.toAddress,
    required this.paymentMethod,
    required this.type,
  });

  factory AdminRideLookupModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    return AdminRideLookupModel(
      rideId: json['rideId'] is int ? json['rideId'] : int.tryParse('${json['rideId']}') ?? 0,
      code: json['code']?.toString() ?? '',
      createdDate: json['createdDate'] == null ? null : DateTime.tryParse(json['createdDate'].toString()),
      pickupTime: json['pickupTime'] == null ? null : DateTime.tryParse(json['pickupTime'].toString()),
      price: parseDouble(json['price']),
      fromAddress: json['fromAddress']?.toString() ?? '',
      toAddress: json['toAddress']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
    );
  }
}