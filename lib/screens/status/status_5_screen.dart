import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/paged_response_model.dart';
import '../../models/ride_model.dart';
import '../../services/api_service.dart';

class StatusFiveScreen extends StatefulWidget {
  const StatusFiveScreen({super.key});

  @override
  State<StatusFiveScreen> createState() => _StatusFiveScreenState();
}

class _StatusFiveScreenState extends State<StatusFiveScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<RideModel> _allRides = [];
  Map<String, List<RideModel>> _groupedRides = LinkedHashMap();

  int _currentPage = 1;
  bool _hasNext = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoading && _hasNext) {
          _loadData();
        }
      }
    });
  }

  // NHÓM THEO createdAt
  void _groupData() {
    Map<String, List<RideModel>> tempGroups = LinkedHashMap();
    for (var ride in _allRides) {
      try {
        // Sử dụng createdAt để làm tiêu đề ngày
        DateTime dateTime = DateTime.parse(ride.createdDate);
        String dateKey = DateFormat('dd/MM/yyyy').format(dateTime);

        if (tempGroups[dateKey] == null) {
          tempGroups[dateKey] = [];
        }
        tempGroups[dateKey]!.add(ride);
      } catch (e) {
        if (tempGroups["Khác"] == null) tempGroups["Khác"] = [];
        tempGroups["Khác"]!.add(ride);
      }
    }
    setState(() {
      _groupedRides = tempGroups;
    });
  }

  Future<void> _loadData({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _hasNext = true;
      _allRides.clear();
    }

    if (!_hasNext || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';

      final response = await ApiService.getCanceledRides(
        accessToken: token,
        page: _currentPage,
        pageSize: 15,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        final pagedData = PagedResponse<RideModel>.fromJson(
          body,
              (item) => RideModel.fromJson(item as Map<String, dynamic>),
        );

        setState(() {
          _allRides.addAll(pagedData.data);
          _hasNext = pagedData.hasNext;
          _currentPage++;
          _groupData();
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải đơn hàng Status 5: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final dateKeys = _groupedRides.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chuyến đã hủy"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadData(isRefresh: true),
        child: _isLoading && _allRides.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _allRides.isEmpty
            ? const Center(child: Text("Không có chuyến xe nào bị hủy"))
            : ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: dateKeys.length + (_hasNext ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < dateKeys.length) {
              String date = dateKeys[index];
              List<RideModel> ridesOfDate = _groupedRides[date]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 45, bottom: 5),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey[800],
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                "Ngày $date",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white, // Chữ trắng trên nền tối
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Divider(
                            thickness: 1,
                            color: Colors.blueGrey[200],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${ridesOfDate.length} đơn",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.blueGrey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...ridesOfDate.map((ride) => _buildRideCard(ride)).toList(),
                ],
              );
            } else {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              );
            }
          },
        ),
      ),
    );
  }


  Widget _buildRideCard(RideModel ride) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(ride.code,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.cancel_outlined, size: 14, color: Colors.red),
                      SizedBox(width: 4),
                      Text("Đã hủy",
                          style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildLocationRow(Icons.radio_button_checked, Colors.green, "Điểm đón", ride.fromAddress),
            const SizedBox(height: 8),
            _buildLocationRow(Icons.location_on, Colors.red, "Điểm đến", ride.toAddress),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Giá cước", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(currencyFormat.format(ride.price),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black54)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Thời gian đặt chuyến", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    // GIỮ LẠI pickupTime TRONG THẺ
                    Text(ride.pickupTime,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.black87)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, Color color, String label, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black, fontSize: 13),
              children: [
                TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: address),
              ],
            ),
          ),
        ),
      ],
    );
  }
}