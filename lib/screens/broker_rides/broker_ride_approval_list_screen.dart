import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/broker_ride_approval_model.dart';
import '../../services/kyc_api_admin_service.dart';
import '../login_screen.dart';
import 'broker_ride_approval_detail_screen.dart';

class BrokerRideApprovalListScreen extends StatefulWidget {
  const BrokerRideApprovalListScreen({super.key});

  @override
  State<BrokerRideApprovalListScreen> createState() =>
      _BrokerRideApprovalListScreenState();
}

class _BrokerRideApprovalListScreenState
    extends State<BrokerRideApprovalListScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<BrokerRideApprovalModel> _items = <BrokerRideApprovalModel>[];
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
  );
  final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  int _currentPage = 1;
  bool _hasNext = true;
  bool _isLoading = false;
  bool _hasPermission = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPendingBrokerRides();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 160) {
      if (!_isLoading && _hasNext) {
        _loadPendingBrokerRides();
      }
    }
  }

  Future<void> _loadPendingBrokerRides({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _currentPage = 1;
      _hasNext = true;
      _items.clear();
      _errorMessage = null;
    }
    if (!_hasNext) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';
      final role = prefs.getInt('role') ?? 0;

      if (role != 3) {
        if (!mounted) return;
        setState(() {
          _hasPermission = false;
          _hasNext = false;
          _errorMessage = null;
        });
        return;
      }

      _hasPermission = true;
      final response = await KycApiAdminService.getPendingApprovalBrokerRides(
        accessToken: token,
        page: _currentPage,
        pageSize: 15,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final pageData = BrokerRideApprovalPage.fromApiJson(body);

        if (!mounted) return;
        setState(() {
          _items.addAll(pageData.items);
          _hasNext = pageData.hasNext;
          _currentPage++;
          _errorMessage = null;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = KycApiAdminService.extractErrorMessage(
            response,
            fallback: 'Không tải được danh sách đơn tài xế đẩy chờ duyệt.',
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể kết nối tới hệ thống duyệt đơn tài xế đẩy.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openDetail(BrokerRideApprovalModel item) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BrokerRideApprovalDetailScreen(brokerRideId: item.id),
      ),
    );

    if (changed == true && mounted) {
      await _loadPendingBrokerRides(refresh: true);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyệt Đơn Tài Xế Đẩy'),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        actions: <Widget>[
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_hasPermission) {
      return _buildStateView(
        icon: Icons.lock_outline_rounded,
        message: 'Tính năng này chỉ dành cho admin role = 3.',
      );
    }

    if (_isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _items.isEmpty) {
      return _buildStateView(
        icon: Icons.error_outline_rounded,
        message: _errorMessage!,
        actionLabel: 'Tải lại',
        onPressed: () => _loadPendingBrokerRides(refresh: true),
      );
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadPendingBrokerRides(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const <Widget>[
            SizedBox(height: 180),
            Center(
              child: Text(
                'Hiện không có đơn tài xế đẩy nào chờ duyệt.',
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadPendingBrokerRides(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: _items.length + (_hasNext ? 1 : 0),
        itemBuilder: (BuildContext context, int index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildRideCard(_items[index]);
        },
      ),
    );
  }

  Widget _buildRideCard(BrokerRideApprovalModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openDetail(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      item.code.isEmpty
                          ? 'Đơn Tài Xế Đẩy #${item.id}'
                          : item.code,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB71C1C),
                      ),
                    ),
                  ),
                  _statusChip(_statusLabel(item.status, item.statusText)),
                ],
              ),
              const SizedBox(height: 12),
              _infoRow(
                icon: Icons.person_outline_rounded,
                label: 'Tài xế tạo',
                value: item.createdDriverName.isEmpty
                    ? 'ID ${item.createdDriverId}'
                    : '${item.createdDriverName} (#${item.createdDriverId})',
              ),
              _infoRow(
                icon: Icons.schedule_rounded,
                label: 'Giờ đón',
                value: _formatDateTime(item.pickupTime),
              ),
              _infoRow(
                icon: Icons.group_rounded,
                label: 'Nhóm chat',
                value: item.groupName.isEmpty
                    ? 'Group #${item.groupId}'
                    : item.groupName,
              ),
              _infoRow(
                icon: Icons.radio_button_checked,
                label: 'Điểm đón',
                value: item.fromAddress,
                color: Colors.green,
              ),
              _infoRow(
                icon: Icons.location_on_outlined,
                label: 'Điểm đến',
                value: item.toAddress,
                color: Colors.red,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _amountTile(
                        'Giá chào',
                        _currencyFormat.format(item.offerPrice),
                      ),
                    ),
                    Expanded(
                      child: _amountTile(
                        'Hoa hồng tạo',
                        _currencyFormat.format(item.creatorEarn),
                      ),
                    ),
                  ],
                ),
              ),
              if (item.note.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  'Ghi chú: ${item.note}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _amountTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Color color = const Color(0xFF424242),
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 13),
                children: <TextSpan>[
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: value.isEmpty ? '-' : value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.orange,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStateView({
    required IconData icon,
    required String message,
    String? actionLabel,
    VoidCallback? onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            if (actionLabel != null && onPressed != null) ...<Widget>[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onPressed, child: Text(actionLabel)),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return '-';
    return _dateTimeFormat.format(value.toLocal());
  }

  String _statusLabel(int status, String fallback) {
    if (status == 0) {
      return 'Đơn chờ duyệt';
    }
    if (fallback.trim().isNotEmpty) {
      return fallback;
    }
    return 'Đơn chờ duyệt';
  }
}
