class RideDetail {
  final int? id;
  final int? rideSource;
  final String? rideSourceText;
  final String? code;
  final int? type;
  final String? createdAt;
  final int? quantity;
  final int? status;
  final String? statusText;
  final String? note;
  final String? pickupTime;
  final int? paymentMethodValue;
  final String? paymentMethod;
  final String? customerName;
  final String? customerPhone;
  final String? createdDriverName;
  final String? createdDriverPhone;
  final String? acceptedDriverName;
  final String? acceptedDriverPhone;
  final String? acceptedDriverAvatar;
  final String? acceptedDriverLicenseNumber;
  final String? fromProvince;
  final String? fromDistrict;
  final String? fromAddress;
  final String? toProvince;
  final String? toDistrict;
  final String? toAddress;
  final double? price;
  final double? finalPrice;
  final double? discount;
  final double? surcharge;
  final double? netIncome;
  final double? creatorEarn;
  final double? systemCommissionAmount;

  RideDetail({
    this.id,
    this.rideSource,
    this.rideSourceText,
    this.code,
    this.type,
    this.createdAt,
    this.quantity,
    this.status,
    this.statusText,
    this.note,
    this.pickupTime,
    this.paymentMethodValue,
    this.paymentMethod,
    this.customerName,
    this.customerPhone,
    this.createdDriverName,
    this.createdDriverPhone,
    this.acceptedDriverName,
    this.acceptedDriverPhone,
    this.acceptedDriverAvatar,
    this.acceptedDriverLicenseNumber,
    this.fromProvince,
    this.fromDistrict,
    this.fromAddress,
    this.toProvince,
    this.toDistrict,
    this.toAddress,
    this.price,
    this.finalPrice,
    this.discount,
    this.surcharge,
    this.netIncome,
    this.creatorEarn,
    this.systemCommissionAmount,
  });

  factory RideDetail.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return RideDetail(
      id: toInt(json['id']),
      rideSource: toInt(json['rideSource']),
      rideSourceText: json['rideSourceText']?.toString(),
      code: json['code']?.toString(),
      type: toInt(json['type']),
      createdAt: json['createdAt']?.toString(),
      quantity: toInt(json['quantity']),
      status: toInt(json['status']),
      statusText: json['statusText']?.toString(),
      note: json['note']?.toString(),
      pickupTime: json['pickupTime']?.toString(),
      paymentMethodValue: toInt(json['paymentMethodValue']),
      paymentMethod: json['paymentMethod']?.toString(),
      customerName: json['customerName']?.toString(),
      customerPhone: json['customerPhone']?.toString(),
      createdDriverName: json['createdDriverName']?.toString(),
      createdDriverPhone: json['createdDriverPhone']?.toString(),
      acceptedDriverName: json['acceptedDriverName']?.toString(),
      acceptedDriverPhone: json['acceptedDriverPhone']?.toString(),
      acceptedDriverAvatar: json['acceptedDriverAvatar']?.toString(),
      acceptedDriverLicenseNumber:
      json['acceptedDriverLicenseNumber']?.toString(),
      fromProvince: json['fromProvince']?.toString(),
      fromDistrict: json['fromDistrict']?.toString(),
      fromAddress: json['fromAddress']?.toString(),
      toProvince: json['toProvince']?.toString(),
      toDistrict: json['toDistrict']?.toString(),
      toAddress: json['toAddress']?.toString(),
      price: toDouble(json['price']),
      finalPrice: toDouble(json['finalPrice']),
      discount: toDouble(json['discount']),
      surcharge: toDouble(json['surcharge']),
      netIncome: toDouble(json['netIncome']),
      creatorEarn: toDouble(json['creatorEarn']),
      systemCommissionAmount: toDouble(json['systemCommissionAmount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rideSource': rideSource,
      'rideSourceText': rideSourceText,
      'code': code,
      'type': type,
      'createdAt': createdAt,
      'quantity': quantity,
      'status': status,
      'statusText': statusText,
      'note': note,
      'pickupTime': pickupTime,
      'paymentMethodValue': paymentMethodValue,
      'paymentMethod': paymentMethod,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'createdDriverName': createdDriverName,
      'createdDriverPhone': createdDriverPhone,
      'acceptedDriverName': acceptedDriverName,
      'acceptedDriverPhone': acceptedDriverPhone,
      'acceptedDriverAvatar': acceptedDriverAvatar,
      'acceptedDriverLicenseNumber': acceptedDriverLicenseNumber,
      'fromProvince': fromProvince,
      'fromDistrict': fromDistrict,
      'fromAddress': fromAddress,
      'toProvince': toProvince,
      'toDistrict': toDistrict,
      'toAddress': toAddress,
      'price': price,
      'finalPrice': finalPrice,
      'discount': discount,
      'surcharge': surcharge,
      'netIncome': netIncome,
      'creatorEarn': creatorEarn,
      'systemCommissionAmount': systemCommissionAmount,
    };
  }
}