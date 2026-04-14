import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../models/voucher_statistic_model.dart';
import '../services/api_service.dart';

class VoucherUsedScreen extends StatefulWidget {
  const VoucherUsedScreen({super.key});

  @override
  State<VoucherUsedScreen> createState() => _VoucherUsedScreenState();
}

class _VoucherUsedScreenState extends State<VoucherUsedScreen> {
  late Future<List<VoucherStatisticModel>> _futureStatistics;

  // Định nghĩa màu sắc chủ đạo Tết
  final Color tetRed = const Color(0xFFD32F2F);
  final Color tetGold = const Color(0xFFFFD700);
  final Color bgLight = const Color(0xFFFFF9F9);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _futureStatistics = ApiService.getVoucherStatistics();
    });
  }

  String formatCurrency(double amount) {
    return NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: FutureBuilder<List<VoucherStatisticModel>>(
        future: _futureStatistics,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingSkeleton();
          }

          if (snapshot.hasError) return _buildErrorState(snapshot.error.toString());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState();

          final listVouchers = snapshot.data!;
          double totalRev = listVouchers.fold(0, (sum, item) => sum + item.totalRevenue);
          int totalUsed = listVouchers.fold(0, (sum, item) => sum + item.totalRides);

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: CustomScrollView(
              slivers: [
                // AppBar với phong cách Tết
                SliverAppBar(
                  expandedHeight: 120.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: tetRed,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'Lộc Xuân Voucher',
                      style: GoogleFonts.lexend(fontWeight: FontWeight.bold, color: tetGold),
                    ),
                    centerTitle: true,
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [tetRed, const Color(0xFFB71C1C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      // Có thể thêm hình ảnh hoa mai/đào mờ ở đây
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.refresh_rounded, color: tetGold),
                      onPressed: _loadData,
                    )
                  ],
                ),

                // Phần Tổng Quan (Quick Stats)
                SliverToBoxAdapter(
                  child: _buildHeaderStats(totalRev, totalUsed, listVouchers.length),
                ),

                // Danh sách Voucher
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildVoucherCard(listVouchers[index]),
                      childCount: listVouchers.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderStats(double totalRev, int totalUsed, int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Thống kê Doanh Thu nổi bật với icon Lixi
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: tetRed.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Row(
              children: [
                Image.asset('lib/assets/icons/Lixi.png', width: 60, height: 60),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Tổng Lộc Xuân", style: GoogleFonts.lexend(color: Colors.grey[600], fontSize: 14)),
                      Text(formatCurrency(totalRev),
                          style: GoogleFonts.lexend(fontSize: 22, fontWeight: FontWeight.bold, color: tetRed)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSmallStatCard("Sử dụng", totalUsed.toString(), Icons.confirmation_number_outlined, Colors.orange),
              const SizedBox(width: 12),
              _buildSmallStatCard("Số lượng", count.toString(), Icons.grid_view_rounded, Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey)),
                Text(value, style: GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherCard(VoucherStatisticModel voucher) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tetRed.withOpacity(0.1)),
        image: const DecorationImage(
          image: AssetImage('lib/assets/icons/voucher.png'),
          alignment: Alignment.centerRight,
          opacity: 0.05, // Làm mờ icon voucher làm background card
        ),
      ),
      child: Stack(
        children: [
          // Hiệu ứng răng cưa giả lập voucher ở mép trái
          // Hiệu ứng răng cưa giả lập voucher ở mép trái (fix overflow)
          Positioned(
            left: -10,
            top: 0,
            bottom: 0,
            child: SizedBox(
              width: 20,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int dotCount = (constraints.maxHeight / 24).floor(); // 24 là khoảng cách dọc
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(dotCount, (_) =>
                        Container(
                          width: 20, height: 20,
                          decoration: BoxDecoration(color: bgLight, shape: BoxShape.circle),
                        )
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset('lib/assets/icons/voucher.png', width: 24, height: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(voucher.name, style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    _buildStatusChip(voucher.isActive),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: tetGold.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                  child: Text(voucher.code, style: GoogleFonts.lexend(color: Colors.brown, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: DashLineSeparator(color: Colors.grey),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSmallInfo(Icons.auto_graph_rounded, '${voucher.totalRides} lượt'),
                    _buildSmallInfo(Icons.calendar_month_outlined, DateFormat('dd/MM').format(voucher.createdDate)),
                    Text(
                      formatCurrency(voucher.totalRevenue),
                      style: GoogleFonts.lexend(color: tetRed, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Giữ nguyên các hàm bổ trợ cũ nhưng cập nhật Style ---

  Widget _buildSmallInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 4),
        Text(text, style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildStatusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive ? Colors.green[200]! : Colors.grey[300]!),
      ),
      child: Text(
        isActive ? 'Hoạt động' : 'Tạm ngưng',
        style: TextStyle(color: isActive ? Colors.green[700] : Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          height: 140,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('lib/assets/icons/Lixi.png', width: 100, opacity: const AlwaysStoppedAnimation(0.5)),
          const SizedBox(height: 16),
          Text('Chưa có lộc voucher nào!', style: GoogleFonts.lexend(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text('Có lỗi xảy ra, thử lại sau nhé!'),
          TextButton(onPressed: _loadData, child: Text('Tải lại', style: TextStyle(color: tetRed))),
        ],
      ),
    );
  }
}

// Widget vẽ đường gạch đứt đoạn cho Voucher
class DashLineSeparator extends StatelessWidget {
  final Color color;
  const DashLineSeparator({super.key, this.color = Colors.grey});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(width: dashWidth, height: 1, child: DecoratedBox(decoration: BoxDecoration(color: color.withOpacity(0.3))));
          }),
        );
      },
    );
  }
}