class RideModel {
  final int rideId;
  final int rideSource;
  final String code;
  final String createdDate;
  final String pickupTime;
  final double price;
  final String fromAddress;
  final String toAddress;
  final String paymentMethod;
  final String type;

  RideModel({
    required this.rideId,
    required this.rideSource,
    required this.code,
    required this.createdDate,
    required this.pickupTime,
    required this.price,
    required this.fromAddress,
    required this.toAddress,
    required this.paymentMethod,
    required this.type,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      rideId: json['id'] ?? json['rideId'] ?? 0,
      rideSource: json['rideSource'] ?? 0,
      code: json['code'] ?? '',
      createdDate: json['createdDate'] ?? '',
      pickupTime: json['pickupTime'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      fromAddress: json['fromAddress'] ?? '',
      toAddress: json['toAddress'] ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      type: json['type'] ?? '',
    );
  }
}