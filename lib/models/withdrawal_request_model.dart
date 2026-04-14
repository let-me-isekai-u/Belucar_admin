class WithdrawalRequestModel {
  final int withdrawalId;
  final String driverName;
  final String phoneNumber;
  final double amount;
  final DateTime createdDate;
  // 3 trường bổ sung mới
  final String bankCode;
  final String bankNumber;
  final String accountName;

  WithdrawalRequestModel({
    required this.withdrawalId,
    required this.driverName,
    required this.phoneNumber,
    required this.amount,
    required this.createdDate,
    required this.bankCode,
    required this.bankNumber,
    required this.accountName,
  });

  factory WithdrawalRequestModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalRequestModel(
      withdrawalId: json['withdrawalId'] ?? 0,
      driverName: json['driverName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      createdDate: json['createdDate'] != null
          ? DateTime.parse(json['createdDate'])
          : DateTime.now(),
      // Parse 3 trường mới từ JSON
      bankCode: json['bankCode'] ?? '',
      bankNumber: json['bankNumber'] ?? '',
      accountName: json['accountName'] ?? '',
    );
  }
}