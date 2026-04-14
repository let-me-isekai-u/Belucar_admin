import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/paged_response_model.dart';
import '../../models/ride_model.dart';
import '../../services/api_service.dart';

class StatusOneScreen extends StatefulWidget {
  const StatusOneScreen({super.key});

  @override
  State<StatusOneScreen> createState() => _StatusOneScreenState();
}

class _StatusOneScreenState extends State<StatusOneScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<RideModel> _rides = [];

  int _currentPage = 1;
  bool _hasNext = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoading && _hasNext) {
          _loadData();
        }
      }
    });
  }

  Future<void> _loadData({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _hasNext = true;
      _rides.clear();
    }

    if (_isLoading || !_hasNext) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';

      final response = await ApiService.getPendingRides(
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

        if (!mounted) return;

        setState(() {
          _rides.addAll(pagedData.data);
          _hasNext = pagedData.hasNext;
          _currentPage++;
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải chuyến chờ tài xế: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chưa có tài xế nhận"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadData(isRefresh: true),
        child: _isLoading && _rides.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _rides.isEmpty
            ? const Center(child: Text("Không có chuyến xe nào đang chờ"))
            : ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(12),
          itemCount: _rides.length + (_hasNext ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < _rides.length) {
              return _buildRideCard(_rides[index]);
            } else {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildRideCard(RideModel ride) {
    final currencyFormat =
    NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ride.code,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    "Chờ nhận",
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildLocationRow(Icons.radio_button_checked, Colors.green,
                "Điểm đón", ride.fromAddress),
            const SizedBox(height: 8),
            _buildLocationRow(
                Icons.location_on, Colors.red, "Điểm đến", ride.toAddress),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Giá cước",
                        style:
                        TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      currencyFormat.format(ride.price),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Thời gian đón",
                        style:
                        TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      ride.pickupTime,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(
      IconData icon, Color color, String label, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style:
              const TextStyle(color: Colors.black, fontSize: 13),
              children: [
                TextSpan(
                    text: "$label: ",
                    style:
                    const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: address),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
