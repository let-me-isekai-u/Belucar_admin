import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/statistical_model.dart';
import '../services/api_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _filterType = 'Tháng';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // Sử dụng Model để quản lý dữ liệu tập trung
  StatisticalModel _data = StatisticalModel.empty();
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _fetchData(); // Tải dữ liệu mặc định khi vào màn hình
  }

  // Hàm gọi API dựa trên loại bộ lọc đang chọn
  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      dynamic response;
      if (_filterType == 'Ngày') {
        String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
        response = await ApiService.getStatisticalDay(date: formattedDate);
      } else if (_filterType == 'Tháng') {
        response = await ApiService.getStatisticalMonth(
            month: _selectedDate.month,
            year: _selectedDate.year
        );
      } else {
        response = await ApiService.getStatisticalYear(year: _selectedDate.year);
      }

      // Log để kiểm tra URL và kết quả
      debugPrint("Đang gọi: ${response.request?.url}");

      if (response.statusCode == 200) {
        debugPrint("Dữ liệu: ${response.body}");
        final body = jsonDecode(response.body);
        setState(() {
          _data = StatisticalModel.fromJson(body);
        });
      } else {
        debugPrint("Lỗi ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      debugPrint("Lỗi ngoại lệ: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thống kê doanh thu"),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildFilterButtons(),
              const SizedBox(height: 20),
              _buildCurrentSelectionHeader(),
              const SizedBox(height: 20),

              if (_isLoading)
                const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()))
              else ...[
                AspectRatio(
                  aspectRatio: 1.5,
                  child: _buildBarChart(),
                ),
                const SizedBox(height: 30),

                // Hiển thị số lượng đơn hàng
                Row(
                  children: [
                    _buildSmallInfoCard("Tổng đơn", "${_data.totalRide}", Colors.blueGrey),
                    const SizedBox(width: 10),
                    _buildSmallInfoCard("Đơn hủy", "${_data.totalCanceled}", Colors.red),
                  ],
                ),
                const SizedBox(height: 20),

                // Các dòng thông số tiền tệ
                _buildStatRow("Tiền chưa về", _data.pendingAmount, Colors.orange),
                _buildStatRow("Doanh thu", _data.totalRevenue, Colors.blue),
                _buildStatRow("Lợi nhuận", _data.totalProfit, Colors.green),
              ]
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget: Nút chọn Ngày/Tháng/Năm ---
  Widget _buildFilterButtons() {
    return ToggleButtons(
      isSelected: [_filterType == 'Ngày', _filterType == 'Tháng', _filterType == 'Năm'],
      onPressed: (index) {
        setState(() {
          if (index == 0) _filterType = 'Ngày';
          if (index == 1) _filterType = 'Tháng';
          if (index == 2) _filterType = 'Năm';
        });
        _pickDate(); // Mở hộp thoại chọn ngay khi bấm chuyển tab
      },
      borderRadius: BorderRadius.circular(10),
      selectedColor: Colors.white,
      fillColor: Colors.blueAccent,
      constraints: const BoxConstraints(minHeight: 40, minWidth: 100),
      children: const [Text("Ngày"), Text("Tháng"), Text("Năm")],
    );
  }

  // --- Logic: Chọn thời gian và Gọi lại API ---
  Future<void> _pickDate() async {
    if (_filterType == 'Ngày') {
      DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      );
      if (picked != null) {
        setState(() => _selectedDate = picked);
        _fetchData();
      }
    } else if (_filterType == 'Tháng') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Chọn tháng"),
          content: SizedBox(
            width: 300,
            height: 250,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
              ),
              itemCount: 12,
              itemBuilder: (context, i) => TextButton(
                onPressed: () {
                  setState(() => _selectedDate = DateTime(_selectedDate.year, i + 1));
                  Navigator.pop(context);
                  _fetchData();
                },
                child: Text("${i + 1}", style: const TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ),
      );
    } else {
      // Chọn năm
      TextEditingController yearController = TextEditingController(text: _selectedDate.year.toString());
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Nhập năm"),
          content: TextField(
            controller: yearController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "Ví dụ: 2025"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),
            TextButton(
              onPressed: () {
                setState(() => _selectedDate = DateTime(int.parse(yearController.text), 1));
                Navigator.pop(context);
                _fetchData();
              },
              child: const Text("Đồng ý"),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildCurrentSelectionHeader() {
    String text = "";
    if (_filterType == 'Ngày') text = DateFormat('dd/MM/yyyy').format(_selectedDate);
    if (_filterType == 'Tháng') text = "Tháng ${_selectedDate.month}/${_selectedDate.year}";
    if (_filterType == 'Năm') text = "Năm ${_selectedDate.year}";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
      ),
    );
  }

  // --- Widget: Biểu đồ cột sử dụng dữ liệu từ API ---
  Widget _buildBarChart() {
    // Tính toán giới hạn trục Y tự động để biểu đồ không bị "chạm trần"
    double maxVal = _data.totalRevenue > _data.totalProfit ? _data.totalRevenue : _data.totalProfit;
    double topLimit = maxVal == 0 ? 100000 : maxVal * 1.2;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: topLimit,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                currencyFormat.format(rod.toY),
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: const FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: _data.totalRevenue,
                color: Colors.blue,
                width: 35,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
              BarChartRodData(
                toY: _data.totalProfit,
                color: Colors.green,
                width: 35,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallInfoCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, double amount, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}