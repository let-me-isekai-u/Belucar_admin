import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/paged_response_model.dart';
import '../../models/ride_model.dart';
import '../../services/api_service.dart';
import '../../providers/role1/ride_detail_role1_provider.dart';
import '../role1/ride_detail_view.dart';

class StatusThreeScreen extends StatefulWidget {
  const StatusThreeScreen({super.key});

  @override
  State<StatusThreeScreen> createState() => _StatusThreeScreenState();
}

class _StatusThreeScreenState extends State<StatusThreeScreen> {
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
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoading && _hasNext) {
          _loadData();
        }
      }
    });
  }

  void _groupData() {
    final Map<String, List<RideModel>> tempGroups = LinkedHashMap();

    for (var ride in _allRides) {
      try {
        final dateTime = DateTime.parse(ride.createdDate);
        final dateKey = DateFormat('dd/MM/yyyy').format(dateTime);

        tempGroups.putIfAbsent(dateKey, () => []);
        tempGroups[dateKey]!.add(ride);
      } catch (_) {
        tempGroups.putIfAbsent("Khác", () => []);
        tempGroups["Khác"]!.add(ride);
      }
    }

    _groupedRides = tempGroups;
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

      final response = await ApiService.getProcessingRides(
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
          _allRides.addAll(pagedData.data);
          _hasNext = pagedData.hasNext;
          _currentPage++;
          _groupData();
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải đơn hàng Status 3: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _goToRideDetail(RideModel ride) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => RideDetailRole1Provider(),
          child: RideDetailView(
            accessToken: token,
            rideId: ride.rideId,
            rideSource: ride.rideSource == 2 ? 2 : 1,
          ),
        ),
      ),
    );
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
        title: const Text("Đang di chuyển"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadData(isRefresh: true),
        child: _isLoading && _allRides.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _allRides.isEmpty
            ? const Center(
          child: Text("Hiện không có chuyến xe nào đang di chuyển"),
        )
            : ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: dateKeys.length + (_hasNext ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < dateKeys.length) {
              final date = dateKeys[index];
              final ridesOfDate = _groupedRides[date]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                    const EdgeInsets.only(top: 45, bottom: 5),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[700],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Ngày $date",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Divider(
                            thickness: 1,
                            color: Colors.green[200],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${ridesOfDate.length} đơn",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.green[300],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...ridesOfDate.map((ride) => _buildRideCard(ride)),
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
    final currencyFormat =
    NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return InkWell(
      onTap: () => _goToRideDetail(ride),
      borderRadius: BorderRadius.circular(10),
      child: Card(
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
                  Expanded(
                    child: Text(
                      ride.code,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow,
                          size: 14,
                          color: Colors.green,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "Đang chạy",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(),
              _buildLocationRow(
                Icons.radio_button_checked,
                Colors.green,
                "Điểm đón",
                ride.fromAddress,
              ),
              const SizedBox(height: 8),
              _buildLocationRow(
                Icons.location_on,
                Colors.red,
                "Điểm đến",
                ride.toAddress,
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Giá cước",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      Text(
                        currencyFormat.format(ride.price),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "Thời gian đặt chuyến",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      Text(
                        ride.pickupTime,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRow(
      IconData icon,
      Color color,
      String label,
      String address,
      ) {
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
                TextSpan(
                  text: "$label: ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: address),
              ],
            ),
          ),
        ),
      ],
    );
  }
}