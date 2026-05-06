import 'dart:convert';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/statistical_model.dart';
import '../services/api_service.dart';

// ─── Color Tokens ──────────────────────────────────────────────────
class _C {
  static const bg       = Color(0xFF0A0E1A);
  static const surface  = Color(0xFF111827);
  static const card     = Color(0xFF1A2235);
  static const cardBorder = Color(0xFF243044);

  static const blue     = Color(0xFF3B82F6);
  static const blueGlow = Color(0x333B82F6);
  static const green    = Color(0xFF10B981);
  static const greenGlow= Color(0x3310B981);
  static const orange   = Color(0xFFF59E0B);
  static const orangeGlow= Color(0x33F59E0B);
  static const red      = Color(0xFFEF4444);
  static const redGlow  = Color(0x33EF4444);

  static const textPrimary   = Color(0xFFF1F5F9);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted     = Color(0xFF475569);
}

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with TickerProviderStateMixin {
  String _filterType = 'Tháng';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String _accessToken = '';

  StatisticalModel _data = StatisticalModel.empty();
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  late AnimationController _fadeCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    );
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _initScreen();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _initScreen() async {
    await _loadAccessToken();
    await _fetchData();
  }

  Future<void> _loadAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('accessToken') ?? '';
    debugPrint('StatisticsScreen accessToken empty: ${_accessToken.isEmpty}');
  }

  Future<void> _fetchData() async {
    if (_accessToken.isEmpty) {
      debugPrint("Không có accessToken để gọi API thống kê");
      return;
    }
    if (mounted) setState(() => _isLoading = true);
    _fadeCtrl.reset();

    try {
      dynamic response;
      if (_filterType == 'Ngày') {
        final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
        response = await ApiService.getStatisticalDay(
          accessToken: _accessToken, date: formattedDate,
        );
      } else if (_filterType == 'Tháng') {
        response = await ApiService.getStatisticalMonth(
          accessToken: _accessToken,
          month: _selectedDate.month,
          year: _selectedDate.year,
        );
      } else {
        response = await ApiService.getStatisticalYear(
          accessToken: _accessToken, year: _selectedDate.year,
        );
      }

      debugPrint("Đang gọi: ${response.request?.url}");
      if (response.statusCode == 200) {
        debugPrint("Dữ liệu: ${response.body}");
        final body = jsonDecode(response.body);
        if (mounted) setState(() => _data = StatisticalModel.fromJson(body));
        _fadeCtrl.forward();
      } else {
        debugPrint("Lỗi ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      debugPrint("Lỗi ngoại lệ: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        backgroundColor: _C.bg,
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(),
        body: RefreshIndicator(
          color: _C.blue,
          backgroundColor: _C.card,
          onRefresh: _fetchData,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: _buildTopSpacing()),
              SliverToBoxAdapter(child: _buildFilterRow()),
              SliverToBoxAdapter(child: const SizedBox(height: 24)),
              SliverToBoxAdapter(child: _buildDateHeader()),
              SliverToBoxAdapter(child: const SizedBox(height: 24)),
              if (_isLoading)
                SliverToBoxAdapter(child: _buildSkeleton())
              else
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: _buildContent(),
                  ),
                ),
              SliverToBoxAdapter(child: const SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () {
          Navigator.of(context).maybePop();
        },
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_C.bg, _C.bg.withOpacity(0)],
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_C.blue, Color(0xFF6366F1)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: _C.blueGlow, blurRadius: 12, spreadRadius: 2),
              ],
            ),
            child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Thống kê doanh thu",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                "Revenue Analytics",
                style: TextStyle(
                  fontSize: 11,
                  color: _C.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopSpacing() => const SizedBox(height: 100);

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.cardBorder),
        ),
        child: Row(
          children: ['Ngày', 'Tháng', 'Năm'].asMap().entries.map((e) {
            final isSelected = _filterType == e.value;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _filterType = e.value);
                  _pickDate();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: isSelected
                      ? BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_C.blue, Color(0xFF6366F1)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: _C.blueGlow,
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  )
                      : null,
                  child: Center(
                    child: Text(
                      e.value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected ? Colors.white : _C.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDateHeader() {
    String text = '';
    IconData icon = Icons.calendar_today_rounded;
    if (_filterType == 'Ngày') {
      text = DateFormat('dd/MM/yyyy').format(_selectedDate);
      icon = Icons.today_rounded;
    } else if (_filterType == 'Tháng') {
      text = "Tháng ${_selectedDate.month}  •  ${_selectedDate.year}";
      icon = Icons.calendar_month_rounded;
    } else {
      text = "Năm ${_selectedDate.year}";
      icon = Icons.calendar_today_rounded;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _C.textMuted),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _C.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          _buildLiveDot(),
        ],
      ),
    );
  }

  Widget _buildLiveDot() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _C.green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _C.green.withOpacity(_pulseAnim.value),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Text("Live", style: TextStyle(fontSize: 12, color: _C.textMuted)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildChartCard(),
          const SizedBox(height: 20),
          _buildCountRow(),
          const SizedBox(height: 20),
          _buildStatCard(
            label: "Tiền chưa về",
            sublabel: "Pending",
            amount: _data.pendingAmount.toDouble(),
            color: _C.orange,
            glowColor: _C.orangeGlow,
            icon: Icons.hourglass_top_rounded,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            label: "Doanh thu",
            sublabel: "Revenue",
            amount: _data.totalRevenue.toDouble(),
            color: _C.blue,
            glowColor: _C.blueGlow,
            icon: Icons.trending_up_rounded,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            label: "Lợi nhuận",
            sublabel: "Profit",
            amount: _data.totalProfit.toDouble(),
            color: _C.green,
            glowColor: _C.greenGlow,
            icon: Icons.account_balance_wallet_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    final double maxVal = math.max(
      _data.totalRevenue.toDouble(),
      _data.totalProfit.toDouble(),
    );
    final double topLimit = maxVal == 0 ? 100000.0 : maxVal * 1.25;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildLegendDot(_C.blue, "Doanh thu"),
              const SizedBox(width: 16),
              _buildLegendDot(_C.green, "Lợi nhuận"),
            ],
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1.6,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.center,
                maxY: topLimit,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 10,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        currencyFormat.format(rod.toY),
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: const FlTitlesData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: _C.cardBorder,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    groupVertically: false,
                    barsSpace: 12,
                    barRods: [
                      BarChartRodData(
                        toY: _data.totalRevenue.toDouble(),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), _C.blue],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 52,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: topLimit,
                          color: _C.surface,
                        ),
                      ),
                      BarChartRodData(
                        toY: _data.totalProfit.toDouble(),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), _C.green],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 52,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: topLimit,
                          color: _C.surface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              swapAnimationDuration: const Duration(milliseconds: 500),
              swapAnimationCurve: Curves.easeInOutCubic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)],
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13, color: _C.textSecondary)),
      ],
    );
  }

  Widget _buildCountRow() {
    return Row(
      children: [
        _buildCountCard(
          label: "Tổng đơn",
          value: "${_data.totalRide}",
          icon: Icons.receipt_long_rounded,
          color: _C.blue,
          glowColor: _C.blueGlow,
        ),
        const SizedBox(width: 12),
        _buildCountCard(
          label: "Đơn hủy",
          value: "${_data.totalCanceled}",
          icon: Icons.cancel_rounded,
          color: _C.red,
          glowColor: _C.redGlow,
        ),
      ],
    );
  }

  Widget _buildCountCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color glowColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(color: glowColor, blurRadius: 20, spreadRadius: 0),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: _C.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String sublabel,
    required double amount,
    required Color color,
    required Color glowColor,
    required IconData icon,
  }) {
    final pct = _data.totalRevenue > 0
        ? (amount / _data.totalRevenue * 100).clamp(0, 100).toDouble()
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: glowColor, blurRadius: 16, spreadRadius: 0),
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _C.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        sublabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormat.format(amount),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                _buildMiniProgressBar(pct, color),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniProgressBar(double pct, Color color) {
    return LayoutBuilder(builder: (ctx, constraints) {
      return Stack(
        children: [
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            height: 4,
            width: constraints.maxWidth * (pct / 100),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.6), color],
              ),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.5), blurRadius: 6),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(4, (i) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: i == 0 ? 220 : 80,
            decoration: BoxDecoration(
              color: _C.card,
              borderRadius: BorderRadius.circular(18),
            ),
            child: _ShimmerBox(),
          );
        }),
      ),
    );
  }

  // ─── Date picker (unchanged logic) ──────────────────────────────
  Future<void> _pickDate() async {
    if (_filterType == 'Ngày') {
      final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        builder: (ctx, child) => Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _C.blue,
              surface: _C.card,
            ),
          ),
          child: child!,
        ),
      );
      if (picked != null) {
        setState(() => _selectedDate = picked);
        _fetchData();
      }
    } else if (_filterType == 'Tháng') {
      showDialog(
        context: context,
        builder: (context) => _DarkDialog(
          title: "Chọn tháng",
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.8,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: 12,
            itemBuilder: (context, i) {
              final isSelected = _selectedDate.month == i + 1;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = DateTime(_selectedDate.year, i + 1);
                  });
                  Navigator.pop(context);
                  _fetchData();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                      colors: [_C.blue, Color(0xFF6366F1)],
                    )
                        : null,
                    color: isSelected ? null : _C.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? _C.blue : _C.cardBorder,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "T${i + 1}",
                      style: TextStyle(
                        color: isSelected ? Colors.white : _C.textSecondary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else {
      final yearController = TextEditingController(
        text: _selectedDate.year.toString(),
      );
      showDialog(
        context: context,
        builder: (context) => _DarkDialog(
          title: "Nhập năm",
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: yearController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: _C.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: "2025",
                  hintStyle: const TextStyle(color: _C.textMuted),
                  filled: true,
                  fillColor: _C.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _C.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _C.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _C.blue, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _DarkButton(
                      label: "Hủy",
                      outline: true,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DarkButton(
                      label: "Đồng ý",
                      onTap: () {
                        final year = int.tryParse(yearController.text);
                        if (year == null) return;
                        setState(() => _selectedDate = DateTime(year, 1));
                        Navigator.pop(context);
                        _fetchData();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }
}

// ─── Shimmer ────────────────────────────────────────────────────────
class _ShimmerBox extends StatefulWidget {
  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              _C.card,
              Color.lerp(_C.card, _C.cardBorder, _anim.value)!,
              _C.card,
            ],
            stops: const [0, 0.5, 1],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
      ),
    );
  }
}

// ─── Dark Dialog ────────────────────────────────────────────────────
class _DarkDialog extends StatelessWidget {
  final String title;
  final Widget child;
  const _DarkDialog({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _C.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _C.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

// ─── Dark Button ────────────────────────────────────────────────────
class _DarkButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool outline;
  const _DarkButton({
    required this.label,
    required this.onTap,
    this.outline = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: outline
              ? null
              : const LinearGradient(
            colors: [_C.blue, Color(0xFF6366F1)],
          ),
          color: outline ? Colors.transparent : null,
          borderRadius: BorderRadius.circular(12),
          border: outline ? Border.all(color: _C.cardBorder) : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: outline ? _C.textSecondary : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}