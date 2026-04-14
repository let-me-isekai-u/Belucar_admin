class WithdrawalHistoryModel {
  final int withdrawalId;
  final String driverName;
  final String phoneNumber;
  final double amount;
  final DateTime createdDate;
  final String status;
  final String? reasonCancel;

  WithdrawalHistoryModel({
    required this.withdrawalId,
    required this.driverName,
    required this.phoneNumber,
    required this.amount,
    required this.createdDate,
    required this.status,
    this.reasonCancel,
  });

  factory WithdrawalHistoryModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalHistoryModel(
      withdrawalId: json['withdrawalId'] ?? 0,
      driverName: json['driverName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      createdDate: DateTime.parse(json['createdDate']),
      status: json['status'] ?? '',
      reasonCancel: json['reasonCancel'],
    );
  }
}
