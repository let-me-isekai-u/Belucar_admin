class StatisticalModel {
  final int totalRide;
  final int totalCanceled;
  final double totalRevenue;
  final double totalProfit;
  final double pendingAmount;

  StatisticalModel({
    required this.totalRide,
    required this.totalCanceled,
    required this.totalRevenue,
    required this.totalProfit,
    required this.pendingAmount,
  });

  factory StatisticalModel.fromJson(Map<String, dynamic> json) {
    return StatisticalModel(
      totalRide: json['totalRide'] ?? 0,
      totalCanceled: json['totalCanceled'] ?? 0,
      // Ép kiểu double vì API có thể trả về số thực
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      totalProfit: (json['totalProfit'] ?? 0).toDouble(),
      pendingAmount: (json['pendingAmount'] ?? 0).toDouble(),
    );
  }

  // Tạo một đối tượng trống để dùng khi chưa có dữ liệu
  factory StatisticalModel.empty() {
    return StatisticalModel(
      totalRide: 0,
      totalCanceled: 0,
      totalRevenue: 0.0,
      totalProfit: 0.0,
      pendingAmount: 0.0,
    );
  }
}