import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/broker_ride_approval_model.dart';
import '../../services/kyc_api_admin_service.dart';

class BrokerRideApprovalDetailScreen extends StatefulWidget {
  final int brokerRideId;

  const BrokerRideApprovalDetailScreen({super.key, required this.brokerRideId});

  @override
  State<BrokerRideApprovalDetailScreen> createState() =>
      _BrokerRideApprovalDetailScreenState();
}

class _BrokerRideApprovalDetailScreenState
    extends State<BrokerRideApprovalDetailScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
  );
  final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  BrokerRideApprovalModel? _item;
  String _accessToken = '';
  String? _errorMessage;
  bool _hasPermission = true;
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';
      final role = prefs.getInt('role') ?? 0;

      if (role != 3) {
        if (!mounted) return;
        setState(() {
          _hasPermission = false;
          _isLoading = false;
        });
        return;
      }

      _accessToken = token;
      final response = await KycApiAdminService.getBrokerRideDetail(
        accessToken: token,
        brokerRideId: widget.brokerRideId,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data =
            body['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

        if (!mounted) return;
        setState(() {
          _item = BrokerRideApprovalModel.fromJson(data);
        });
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = KycApiAdminService.extractErrorMessage(
            response,
            fallback: 'Không tải được chi tiết đơn tài xế đẩy.',
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

  Future<void> _approveBrokerRide() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Duyệt đơn tài xế đẩy'),
          content: const Text(
            'Bạn xác nhận chuyển đơn tài xế đẩy này sang trạng thái chờ tài xế?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Duyệt'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _submitAction(
      request: () => KycApiAdminService.approveBrokerRide(
        accessToken: _accessToken,
        brokerRideId: widget.brokerRideId,
      ),
      successMessage: 'Đơn tài xế đẩy đã được duyệt.',
    );
  }

  Future<void> _showRejectDialog() async {
    String rejectReason = '';

    final String? reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Từ chối đơn tài xế đẩy'),
          content: TextField(
            maxLines: 3,
            onChanged: (String value) => rejectReason = value,
            decoration: const InputDecoration(
              hintText: 'Nhập lý do từ chối',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final value = rejectReason.trim();
                if (value.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lý do từ chối không được để trống.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop(value);
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Từ chối'),
            ),
          ],
        );
      },
    );

    if (reason == null || reason.isEmpty) return;

    await _submitAction(
      request: () => KycApiAdminService.rejectBrokerRide(
        accessToken: _accessToken,
        brokerRideId: widget.brokerRideId,
        reason: reason,
      ),
      successMessage: 'Đơn tài xế đẩy đã bị từ chối.',
    );
  }

  Future<void> _submitAction({
    required Future<dynamic> Function() request,
    required String successMessage,
  }) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final response = await request();

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              KycApiAdminService.extractErrorMessage(
                response,
                fallback: 'Không thể cập nhật đơn tài xế đẩy.',
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Có lỗi kết nối khi xử lý đơn tài xế đẩy.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi Tiết Đơn Tài Xế Đẩy'),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar:
          item != null && _hasPermission && item.isPendingApproval
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _showRejectDialog,
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Từ chối'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _approveBrokerRide,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline_rounded),
                      label: Text(_isSubmitting ? 'Đang xử lý...' : 'Duyệt'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
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

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildStateView(
        icon: Icons.error_outline_rounded,
        message: _errorMessage!,
        actionLabel: 'Tải lại',
        onPressed: _loadDetail,
      );
    }

    if (_item == null) {
      return _buildStateView(
        icon: Icons.info_outline_rounded,
        message: 'Không tìm thấy thông tin đơn tài xế đẩy.',
      );
    }

    final item = _item!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSummaryCard(item),
          const SizedBox(height: 12),
          _buildSection(
            title: 'Thông tin chuyến',
            children: <Widget>[
              _detailRow(
                'Mã đơn',
                item.code.isEmpty ? '#${item.id}' : item.code,
              ),
              _detailRow(
                'Trạng thái',
                _statusLabel(item.status, item.statusText),
              ),
              _detailRow('Thời gian tạo', _formatDateTime(item.createdAt)),
              _detailRow('Giờ đón', _formatDateTime(item.pickupTime)),
              _detailRow('Loại chuyến', item.type.toString()),
              _detailRow('Số lượng', item.quantity.toString()),
              _detailRow('Route ID', item.routeId.toString()),
              _detailRow(
                'Group',
                item.groupName.isEmpty
                    ? item.groupId.toString()
                    : '${item.groupName} (#${item.groupId})',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSection(
            title: 'Điểm đi và điểm đến',
            children: <Widget>[
              _detailRow(
                'Điểm đón',
                '${item.fromAddress}\n${item.fromDistrictName}, ${item.fromProvinceName}',
              ),
              _detailRow(
                'Điểm đến',
                '${item.toAddress}\n${item.toDistrictName}, ${item.toProvinceName}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSection(
            title: 'Người tạo và khách',
            children: <Widget>[
              _detailRow(
                'Tài xế tạo',
                item.createdDriverName.isEmpty
                    ? item.createdDriverId.toString()
                    : '${item.createdDriverName} (#${item.createdDriverId})',
              ),
              _detailRow(
                'Số điện thoại khách',
                item.customerPhone.isEmpty ? '-' : item.customerPhone,
              ),
              _detailRow('Ghi chú', item.note.isEmpty ? '-' : item.note),
            ],
          ),
          const SizedBox(height: 12),
          _buildSection(
            title: 'Giá trị đơn',
            children: <Widget>[
              _detailRow('Giá chào', _currencyFormat.format(item.offerPrice)),
              _detailRow(
                'Thu nhập người tạo',
                _currencyFormat.format(item.creatorEarn),
              ),
            ],
          ),
          if (item.reviewedByAdminId != null ||
              item.reviewedAt != null ||
              (item.rejectionReason?.trim().isNotEmpty ?? false)) ...<Widget>[
            const SizedBox(height: 12),
            _buildSection(
              title: 'Thông tin duyệt',
              children: <Widget>[
                _detailRow(
                  'Admin duyệt',
                  item.reviewedByAdminId?.toString() ?? '-',
                ),
                _detailRow('Thời gian duyệt', _formatDateTime(item.reviewedAt)),
                _detailRow(
                  'Lý do từ chối',
                  (item.rejectionReason?.trim().isNotEmpty ?? false)
                      ? item.rejectionReason!
                      : '-',
                ),
              ],
            ),
          ],
          if (!item.isPendingApproval) ...<Widget>[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Đơn tài xế đẩy này không còn ở trạng thái chờ duyệt.',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BrokerRideApprovalModel item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFB71C1C), Color(0xFFD84315)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            item.code.isEmpty ? 'Đơn Tài Xế Đẩy #${item.id}' : item.code,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${item.fromProvinceName} -> ${item.toProvinceName}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _summaryChip(_statusLabel(item.status, item.statusText)),
              _summaryChip(_currencyFormat.format(item.offerPrice)),
              _summaryChip(_formatDateTime(item.pickupTime)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text.isEmpty ? '-' : text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFFB71C1C),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
