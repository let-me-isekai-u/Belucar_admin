import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'withdrawal_history_screen.dart';
import '../../models/withdrawal_request_model.dart';
import '../../models/paged_response_model.dart';
import '../../services/api_service.dart';
import '../login_screen.dart';

class WithdrawalConfirmList extends StatefulWidget {
  const WithdrawalConfirmList({super.key});

  @override
  State<WithdrawalConfirmList> createState() => _WithdrawalConfirmListState();
}

class _WithdrawalConfirmListState extends State<WithdrawalConfirmList> {
  int _selectedIndex = 0;
  final List<WithdrawalRequestModel> _withdrawals = [];
  bool _isLoading = false;
  int _page = 1;
  bool _hasNext = true;

  // Biến dùng để quản lý việc ẩn hiện thông tin ngân hàng
  int? _expandedId;

  @override
  void initState() {
    super.initState();
    _loadWithdrawals();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Đã sao chép số tài khoản"),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // ... (Giữ nguyên các hàm _logout, _loadWithdrawals, _accept, _reject) ...
  Future<void> _loadWithdrawals({bool loadMore = false}) async {
    if (_isLoading || (!_hasNext && loadMore)) return;
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) return;

    try {
      final response = await ApiService.getWithdrawalRequest(
        accessToken: token,
        page: loadMore ? _page + 1 : 1,
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final paged = PagedResponse<WithdrawalRequestModel>.fromJson(
          json,
              (e) => WithdrawalRequestModel.fromJson(e as Map<String, dynamic>),
        );
        setState(() {
          if (loadMore) {
            _withdrawals.addAll(paged.data);
            _page++;
          } else {
            _withdrawals..clear()..addAll(paged.data);
            _page = 1;
          }
          _hasNext = paged.hasNext;
        });
      }
    } catch (e) { debugPrint("Lỗi: $e"); }
    setState(() => _isLoading = false);
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  Future<void> _acceptWithdrawalReques(int withdrawalId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';
    final res = await ApiService.acceptWithdrawalRequest(accessToken: token, withdrawalId: withdrawalId);
    if (res.statusCode == 200) {
      setState(() => _withdrawals.removeWhere((e) => e.withdrawalId == withdrawalId));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã duyệt thành công"), backgroundColor: Colors.green));
    }
  }

  Future<void> _rejectWithdrawalRequest({required int withdrawalId, required String reasonCancel}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';
    final res = await ApiService.rejectWithdrawalRequest(accessToken: token, withdrawalId: withdrawalId, reasonCancel: reasonCancel);
    if (res.statusCode == 200) {
      setState(() => _withdrawals.removeWhere((e) => e.withdrawalId == withdrawalId));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã từ chối"), backgroundColor: Colors.orange));
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [_buildMainListBody(), const WithdrawalHistoryScreen()];
    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.orange,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.playlist_add_check_rounded), label: 'Xác nhận'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Lịch sử'),
        ],
      ),
    );
  }

  Widget _buildMainListBody() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Xác nhận rút tiền"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () => _logout(context),
          )
        ],
      ),
      body: _withdrawals.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () => _loadWithdrawals(),
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _withdrawals.length + (_hasNext ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _withdrawals.length) {
              _loadWithdrawals(loadMore: true);
              return const Center(child: CircularProgressIndicator());
            }
            return _buildWithdrawalCard(context, _withdrawals[index]);
          },
        ),
      ),
    );
  }

  Widget _buildWithdrawalCard(BuildContext context, WithdrawalRequestModel item) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final bool isExpanded = _expandedId == item.withdrawalId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: InkWell( // Bọc vào InkWell để bắt sự kiện nhấn vào toàn bộ Card
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() {
            _expandedId = isExpanded ? null : item.withdrawalId;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('WD-${item.withdrawalId}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 16)),
                  Row(
                    children: [
                      _statusChip("Chờ duyệt"),
                      const SizedBox(width: 8),
                      // Mũi tên hướng lên/xuống dựa vào trạng thái ẩn hiện
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(),
              _buildInfoRow(Icons.person, Colors.blue, "Tài xế", item.driverName),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.phone, Colors.green, "SĐT", item.phoneNumber),

              // --- PHẦN THÔNG TIN NGÂN HÀNG (ẨN/HIỆN CÓ HIỆU ỨNG) ---
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity), // Khi ẩn là rỗng
                secondChild: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blueGrey[100]!),
                      ),
                      child: Column(
                        children: [
                          _buildBankDetailRow("Ngân hàng", item.bankCode, isBold: true),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _buildBankDetailRow("Số TK", item.bankNumber)),
                              InkWell(
                                onTap: () => _copyToClipboard(item.bankNumber),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.copy, size: 18, color: Colors.blue),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildBankDetailRow("Chủ tài khoản", item.accountName.toUpperCase()),
                        ],
                      ),
                    ),
                  ],
                ),
                crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),

              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Số tiền rút", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(currencyFormat.format(item.amount),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("Ngày yêu cầu", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(DateFormat('dd/MM/yyyy HH:mm').format(item.createdDate)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _confirmDialog(context, isApprove: true, driverName: item.driverName, withdrawalId: item.withdrawalId),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      child: const Text("DUYỆT"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _confirmDialog(context, isApprove: false, driverName: item.driverName, withdrawalId: item.withdrawalId),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                      child: const Text("TỪ CHỐI"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ... (Giữ nguyên các widget bổ trợ _buildBankDetailRow, _statusChip, _buildInfoRow, _confirmDialog) ...
  Widget _buildBankDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 85, child: Text("$label:", style: const TextStyle(fontSize: 13, color: Colors.blueGrey))),
        Expanded(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: Colors.black87))),
      ],
    );
  }

  Widget _statusChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
      child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoRow(IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black, fontSize: 13),
              children: [
                TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDialog(BuildContext context, {required bool isApprove, required String driverName, required int withdrawalId}) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(isApprove ? "Xác nhận duyệt" : "Xác nhận từ chối"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hành động cho tài xế: $driverName"),
            if (!isApprove) ...[
              const SizedBox(height: 16),
              TextField(controller: reasonController, decoration: const InputDecoration(labelText: "Lý do từ chối", border: OutlineInputBorder()), maxLines: 2),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Huỷ", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isApprove ? Colors.green : Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              if (!isApprove && reasonController.text.trim().isEmpty) return;
              Navigator.pop(dialogContext);
              if (isApprove) await _acceptWithdrawalReques(withdrawalId);
              else await _rejectWithdrawalRequest(withdrawalId: withdrawalId, reasonCancel: reasonController.text.trim());
            },
            child: const Text("Xác nhận"),
          ),
        ],
      ),
    );
  }
}