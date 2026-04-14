class ChatRideCardDto {
  final int rideId;
  final String code;
  final int status;
  final int type;
  final int? tripId;

  final int? fromDistrictId;
  final String? fromDistrictName;
  final int? toDistrictId;
  final String? toDistrictName;

  final String fromAddress;
  final String toAddress;

  final String customerPhone;
  final DateTime? pickupTime;

  final double basePrice;
  final double surcharge;
  final double discount;
  final double finalPrice;

  final int paymentMethod;
  final String paymentMethodText;

  final int quantity;
  final String? note;

  ChatRideCardDto({
    required this.rideId,
    required this.code,
    required this.status,
    required this.type,
    this.tripId,
    this.fromDistrictId,
    this.fromDistrictName,
    this.toDistrictId,
    this.toDistrictName,
    required this.fromAddress,
    required this.toAddress,
    required this.customerPhone,
    required this.pickupTime,
    required this.basePrice,
    required this.surcharge,
    required this.discount,
    required this.finalPrice,
    required this.paymentMethod,
    required this.paymentMethodText,
    required this.quantity,
    this.note,
  });

  factory ChatRideCardDto.fromJson(Map<String, dynamic> json) {
    return ChatRideCardDto(
      rideId: _toInt(json['rideId']) ?? 0,
      code: (json['code'] ?? '').toString(),
      status: _toInt(json['status']) ?? 0,
      type: _toInt(json['type']) ?? 0,
      tripId: _toInt(json['tripId']),
      fromDistrictId: _toInt(json['fromDistrictId']),
      fromDistrictName: json['fromDistrictName']?.toString(),
      toDistrictId: _toInt(json['toDistrictId']),
      toDistrictName: json['toDistrictName']?.toString(),
      fromAddress: (json['fromAddress'] ?? '').toString(),
      toAddress: (json['toAddress'] ?? '').toString(),
      customerPhone: (json['customerPhone'] ?? '').toString(),
      pickupTime: _toDateTime(json['pickupTime']),
      basePrice: _toDouble(json['basePrice']),
      surcharge: _toDouble(json['surcharge']),
      discount: _toDouble(json['discount']),
      finalPrice: _toDouble(json['finalPrice']),
      paymentMethod: _toInt(json['paymentMethod']) ?? 0,
      paymentMethodText: (json['paymentMethodText'] ?? '').toString(),
      quantity: _toInt(json['quantity']) ?? 1,
      note: json['note']?.toString(),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }
}