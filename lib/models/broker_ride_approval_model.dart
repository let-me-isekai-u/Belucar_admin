class BrokerRideApprovalModel {
  final int id;
  final String code;
  final int status;
  final String statusText;
  final DateTime? createdAt;
  final DateTime? pickupTime;
  final int createdDriverId;
  final String createdDriverName;
  final int fromDistrictId;
  final String fromDistrictName;
  final String fromProvinceName;
  final String fromAddress;
  final int toDistrictId;
  final String toDistrictName;
  final String toProvinceName;
  final String toAddress;
  final String customerPhone;
  final int type;
  final int quantity;
  final double offerPrice;
  final double creatorEarn;
  final double acceptedPrice;
  final int routeId;
  final int groupId;
  final String groupName;
  final String note;
  final int? reviewedByAdminId;
  final DateTime? reviewedAt;
  final String? rejectionReason;

  const BrokerRideApprovalModel({
    required this.id,
    required this.code,
    required this.status,
    required this.statusText,
    required this.createdAt,
    required this.pickupTime,
    required this.createdDriverId,
    required this.createdDriverName,
    required this.fromDistrictId,
    required this.fromDistrictName,
    required this.fromProvinceName,
    required this.fromAddress,
    required this.toDistrictId,
    required this.toDistrictName,
    required this.toProvinceName,
    required this.toAddress,
    required this.customerPhone,
    required this.type,
    required this.quantity,
    required this.offerPrice,
    required this.creatorEarn,
    required this.acceptedPrice,
    required this.routeId,
    required this.groupId,
    required this.groupName,
    required this.note,
    required this.reviewedByAdminId,
    required this.reviewedAt,
    required this.rejectionReason,
  });

  bool get isPendingApproval => status == 0;

  factory BrokerRideApprovalModel.fromJson(Map<String, dynamic> json) {
    return BrokerRideApprovalModel(
      id: _asInt(json['id']),
      code: _asString(json['code']),
      status: _asInt(json['status']),
      statusText: _asString(json['statusText']),
      createdAt: _asDateTime(json['createdAt']),
      pickupTime: _asDateTime(json['pickupTime']),
      createdDriverId: _asInt(json['createdDriverId']),
      createdDriverName: _asString(json['createdDriverName']),
      fromDistrictId: _asInt(json['fromDistrictId']),
      fromDistrictName: _asString(json['fromDistrictName']),
      fromProvinceName: _asString(json['fromProvinceName']),
      fromAddress: _asString(json['fromAddress']),
      toDistrictId: _asInt(json['toDistrictId']),
      toDistrictName: _asString(json['toDistrictName']),
      toProvinceName: _asString(json['toProvinceName']),
      toAddress: _asString(json['toAddress']),
      customerPhone: _asString(json['customerPhone']),
      type: _asInt(json['type']),
      quantity: _asInt(json['quantity']),
      offerPrice: _asDouble(json['offerPrice']),
      creatorEarn: _asDouble(json['creatorEarn']),
      acceptedPrice: _asDouble(json['acceptedPrice']),
      routeId: _asInt(json['routeId']),
      groupId: _asInt(json['groupId']),
      groupName: _asString(json['groupName']),
      note: _asString(json['note']),
      reviewedByAdminId: json['reviewedByAdminId'] == null
          ? null
          : _asInt(json['reviewedByAdminId']),
      reviewedAt: _asDateTime(json['reviewedAt']),
      rejectionReason: json['rejectionReason']?.toString(),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _asString(dynamic value) {
    return value?.toString() ?? '';
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class BrokerRideApprovalPage {
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool hasNext;
  final List<BrokerRideApprovalModel> items;

  const BrokerRideApprovalPage({
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
    required this.hasNext,
    required this.items,
  });

  factory BrokerRideApprovalPage.fromApiJson(Map<String, dynamic> json) {
    final dynamic rawData = json['data'];
    final Map<String, dynamic> data = rawData is Map<String, dynamic>
        ? rawData
        : <String, dynamic>{};

    final dynamic rawItems = data['items'];
    final List<dynamic> items = rawItems is List ? rawItems : <dynamic>[];

    return BrokerRideApprovalPage(
      page: BrokerRideApprovalModel._asInt(data['page']),
      pageSize: BrokerRideApprovalModel._asInt(data['pageSize']),
      totalItems: BrokerRideApprovalModel._asInt(data['totalItems']),
      totalPages: BrokerRideApprovalModel._asInt(data['totalPages']),
      hasNext: data['hasNext'] == true,
      items: items
          .whereType<Map<String, dynamic>>()
          .map(BrokerRideApprovalModel.fromJson)
          .toList(),
    );
  }
}
