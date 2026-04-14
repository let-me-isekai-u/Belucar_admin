import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/paged_response_model.dart';
import '../../models/witdrawal_confirm_history.dart';
import '../../services/api_service.dart';
import '../home_screen.dart';

class WithdrawalHistoryScreen extends StatefulWidget {
  const WithdrawalHistoryScreen({super.key});

  @override
  State<WithdrawalHistoryScreen> createState() =>
      _WithdrawalHistoryScreenState();
}

class _WithdrawalHistoryScreenState extends State<WithdrawalHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<WithdrawalHistoryModel> _historyData = [];

  int _currentPage = 1;
  bool _hasNext = true;
  bool _isLoading = false;

  int _userRole = 0;

  @override
  void initState() {
    super.initState();
    _checkRoleAndLoadData();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoading && _hasNext) {
          _loadData();
        }
      }
    });
  }

  Future<void> _checkRoleAndLoadData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userRole = prefs.getInt('role') ?? 0;
      });
    }
    _loadData();
  }

  Future<void> _loadData({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _hasNext = true;
      _historyData.clear();
    }

    if (_isLoading || !_hasNext) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';

      final response = await ApiService.getWithdrawalConfirmHistory(
        accessToken: token,
        page: _currentPage,
        pageSize: 15,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        final pagedData = PagedResponse<WithdrawalHistoryModel>.fromJson(
          body,
              (item) =>
              WithdrawalHistoryModel.fromJson(item as Map<String, dynamic>),
        );

        if (!mounted) return;

        setState(() {
          _historyData.addAll(pagedData.data);

          // 🔽 SORT: mới → cũ theo createdDate
          _historyData.sort(
                (a, b) => b.createdDate.compareTo(a.createdDate),
          );

          _hasNext = pagedData.hasNext;
          _currentPage++;
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải lịch sử duyệt rút tiền: $e");
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

  /// 🔽 BUILD LIST ĐÃ GROUP THEO NGÀY
  List<dynamic> _buildGroupedList() {
    final List<dynamic> result = [];
    String? currentDate;

    for (final item in _historyData) {
      final dateKey =
      DateFormat('dd/MM/yyyy').format(item.createdDate);

      if (currentDate != dateKey) {
        currentDate = dateKey;
        result.add(dateKey); // header ngày
      }

      result.add(item);
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final groupedList = _buildGroupedList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch sử duyệt"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: _userRole == 1
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => const HomeScreen()),
                    (route) => false,
              ),
        )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadData(isRefresh: true),
        child: _isLoading && _historyData.isEmpty
            ? const Center(
            child:
            CircularProgressIndicator(color: Colors.orange))
            : _historyData.isEmpty
            ? const Center(
            child: Text("Không có lịch sử nào"))
            : ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(12),
          itemCount:
          groupedList.length + (_hasNext ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= groupedList.length) {
              return const Padding(
                padding:
                EdgeInsets.symmetric(vertical: 16),
                child: Center(
                    child:
                    CircularProgressIndicator()),
              );
            }

            final item = groupedList[index];

            // 🟧 HEADER NGÀY
            if (item is String) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 8),
                child: Text(
                  "📅 $item",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              );
            }

            // 🟩 CARD DATA
            return _buildHistoryCard(
                item as WithdrawalHistoryModel);
          },
        ),
      ),
    );
  }

  Widget _buildHistoryCard(WithdrawalHistoryModel item) {
    final currencyFormat =
    NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    final bool hasReason = item.reasonCancel != null &&
        item.reasonCancel!.trim().isNotEmpty;
    final String statusLower = item.status.toLowerCase();
    final bool isRejected = hasReason ||
        statusLower.contains("từ chối") ||
        statusLower.contains("reject");
    final bool isSuccess = !isRejected &&
        (statusLower.contains("thành công") ||
            statusLower.contains("hoàn thành") ||
            statusLower.contains("approve"));

    Color mainColor = Colors.orange;
    if (isSuccess) mainColor = Colors.green;
    if (isRejected) mainColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "WD-${item.withdrawalId}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: mainColor.withOpacity(0.1),
                    borderRadius:
                    BorderRadius.circular(5),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(
                        fontSize: 12,
                        color: mainColor,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow(Icons.person_outline,
                Colors.blue, "Tài xế", item.driverName),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone_android,
                Colors.green, "SĐT", item.phoneNumber),
            if (hasReason) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.error_outline,
                Colors.red,
                "Lý do",
                item.reasonCancel!,
                valueColor: Colors.red[700],
              ),
            ],
            const Divider(),
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text("Số tiền đã xử lý",
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey)),
                    Text(
                      currencyFormat.format(item.amount),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: mainColor),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.end,
                  children: [
                    const Text("Ngày xử lý",
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey)),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm')
                          .format(item.createdDate),
                      style: const TextStyle(
                          fontWeight: FontWeight.w500),
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

  Widget _buildInfoRow(
      IconData icon,
      Color color,
      String label,
      String value, {
        Color? valueColor,
      }) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                  color: Colors.black, fontSize: 13),
              children: [
                TextSpan(
                    text: "$label: ",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold)),
                TextSpan(
                    text: value,
                    style: TextStyle(
                        color:
                        valueColor ?? Colors.black87)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
