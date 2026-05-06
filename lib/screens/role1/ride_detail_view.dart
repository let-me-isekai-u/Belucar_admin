import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/role1/ride_detail_role1_provider.dart';

class RideDetailView extends StatefulWidget {
  final String accessToken;
  final int rideId;
  final int rideSource;

  const RideDetailView({
    super.key,
    required this.accessToken,
    required this.rideId,
    required this.rideSource,
  });

  @override
  State<RideDetailView> createState() => _RideDetailViewState();
}

class _RideDetailViewState extends State<RideDetailView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // ── Design tokens ──────────────────────────────────────────────
  static const _bg         = Color(0xFF0F1117);
  static const _surface    = Color(0xFF1A1D27);
  static const _surfaceAlt = Color(0xFF20243A);
  static const _accent     = Color(0xFF4F8EF7);
  static const _accentGlow = Color(0x334F8EF7);
  static const _gold       = Color(0xFFE8B84B);
  static const _textPrimary   = Color(0xFFF0F2FF);
  static const _textSecondary = Color(0xFF8B91B0);
  static const _divider    = Color(0xFF2A2E45);
  static const _green      = Color(0xFF3DD68C);
  static const _red        = Color(0xFFFF5C6A);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    Future.microtask(() {
      debugPrint('🚀 [RideDetailView] rideId=${widget.rideId} | rideSource=${widget.rideSource} | token=${widget.accessToken.isNotEmpty ? '✅ có token' : '❌ KHÔNG CÓ TOKEN'}');
      context.read<RideDetailRole1Provider>().fetchRideDetail(
        accessToken: widget.accessToken,
        rideId: widget.rideId,
        rideSource: widget.rideSource,
      );
      _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RideDetailRole1Provider>();
    final detail   = provider.rideDetail;

    return Scaffold(
      backgroundColor: _bg,
      // ── AppBar ──────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            const Text(
              'CHI TIẾT CHUYẾN',
              style: TextStyle(
                fontSize: 13,
                letterSpacing: 3,
                fontWeight: FontWeight.w700,
                color: _textSecondary,
              ),
            ),
            if (detail != null)
              Text(
                '#${detail.code}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _accent,
                  letterSpacing: 1,
                ),
              ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _accent.withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),

      // ── Body ────────────────────────────────────────────────────
      body: _buildBody(provider, detail),
    );
  }

  Widget _buildBody(RideDetailRole1Provider provider, dynamic detail) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: _accent,
          strokeWidth: 2,
        ),
      );
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 48, color: _red.withOpacity(0.7)),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _textSecondary, fontSize: 15, height: 1.5),
              ),
            ),
          ],
        ),
      );
    }

    if (detail == null) {
      return const Center(
        child: Text(
          'Không có dữ liệu',
          style: TextStyle(color: _textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      color: _accent,
      backgroundColor: _surface,
      onRefresh: () async {
        await context.read<RideDetailRole1Provider>().fetchRideDetail(
          accessToken: widget.accessToken,
          rideId: widget.rideId,
          rideSource: widget.rideSource,
        );
      },
      child: FadeTransition(
        opacity: _fadeAnim,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // ── Hero status strip ──────────────────────────────────
            _buildStatusHero(detail),
            const SizedBox(height: 20),

            // ── Route card ─────────────────────────────────────────
            _buildRouteCard(detail),
            const SizedBox(height: 16),

            // ── General info ───────────────────────────────────────
            _buildSection(
              icon: Icons.info_outline_rounded,
              title: 'Thông tin chung',
              color: _accent,
              rows: [
                _rowData('Nguồn chuyến', _rideSourceLabel(detail)),
                _rowData('Mã đơn', detail.code),
                _rowData('Loại', _rideTypeLabel(detail.type)),
                _rowData('Số lượng khách', detail.quantity?.toString()),
                _rowData('Ghi chú',       detail.note),
                _rowData('Thời gian tạo', _formatDateTime(detail.createdAt),
                    icon: Icons.schedule_rounded),
                _rowData('Thời gian đón', _formatDateTime(detail.pickupTime),
                    icon: Icons.directions_car_rounded),
              ],
            ),
            const SizedBox(height: 12),

            // ── Customer ───────────────────────────────────────────
            _buildSection(
              icon: Icons.person_outline_rounded,
              title: 'Khách hàng',
              color: _gold,
              rows: [
                _rowData('Họ tên',        detail.customerName),
                _rowData('Số điện thoại', detail.customerPhone,
                    icon: Icons.phone_outlined),
              ],
            ),
            const SizedBox(height: 12),

            // ── Driver row: created + accepted ─────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildDriverMini(
                    title:  'Tài xế tạo đơn',
                    name:   detail.createdDriverName,
                    phone:  detail.createdDriverPhone,
                    avatar: null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDriverMini(
                    title:  'Tài xế nhận đơn',
                    name:   detail.acceptedDriverName,
                    phone:  detail.acceptedDriverPhone,
                    avatar: detail.acceptedDriverAvatar,
                    license: detail.acceptedDriverLicenseNumber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Payment ────────────────────────────────────────────
            _buildPaymentCard(detail),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ── Hero status strip ──────────────────────────────────────────
  Widget _buildStatusHero(dynamic detail) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_surfaceAlt, _surface],
        ),
        border: Border.all(color: _accentGlow, width: 1),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _accentGlow,
              shape: BoxShape.circle,
            ),
            child: const Icon(
                Icons.directions_car_filled_rounded,
                color: _accent,
                size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _rideSourceLabel(detail),
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Mã: ${detail.code ?? '---'}',
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          _buildStatusBadge(detail.statusText),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    final text   = status ?? '---';
    final isOk   = text.toLowerCase().contains('hoàn')    ||
        text.toLowerCase().contains('thành công');
    final isWarn = text.toLowerCase().contains('chờ')     ||
        text.toLowerCase().contains('đang');
    final color  = isOk ? _green : isWarn ? _gold : _textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Route card ─────────────────────────────────────────────────
  Widget _buildRouteCard(dynamic detail) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _divider),
      ),
      child: Column(
        children: [
          _buildRoutePoint(
            icon: Icons.trip_origin_rounded,
            color: _green,
            label: 'ĐIỂM ĐÓN',
            province: detail.fromProvince,
            district: detail.fromDistrict,
            address:  detail.fromAddress,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Row(
              children: [
                Column(
                  children: List.generate(
                    4,
                        (_) => Container(
                      width: 2, height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: _textSecondary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildRoutePoint(
            icon: Icons.location_on_rounded,
            color: _red,
            label: 'ĐIỂM ĐẾN',
            province: detail.toProvince,
            district: detail.toDistrict,
            address:  detail.toAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildRoutePoint({
    required IconData icon,
    required Color color,
    required String label,
    String? province,
    String? district,
    String? address,
  }) {
    final addr = _joinNonEmpty([address, district, province]);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  )),
              const SizedBox(height: 2),
              Text(
                addr.isEmpty ? '---' : addr,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Generic section card ───────────────────────────────────────
  Widget _buildSection({
    required IconData icon,
    required String title,
    required Color color,
    required List<_RowData> rows,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: _divider),
          // rows
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: rows
                  .map((r) => _buildInfoRow(r.label, r.value, icon: r.icon))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Driver mini card ───────────────────────────────────────────
  Widget _buildDriverMini({
    required String title,
    String? name,
    String? phone,
    String? avatar,
    String? license,
  }) {
    final hasAvatar = avatar != null &&
        avatar.isNotEmpty &&
        avatar != 'null' &&
        avatar.startsWith('http');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // avatar
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_surfaceAlt, _divider],
              ),
              image: hasAvatar
                  ? DecorationImage(
                image: NetworkImage(avatar!),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: hasAvatar
                ? null
                : const Icon(Icons.person_rounded,
                color: _textSecondary, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _safe(name),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_safe(phone) != '---') ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone_outlined,
                    color: _accent, size: 12),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    _safe(phone),
                    style: const TextStyle(
                        color: _accent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          if (license != null &&
              license.isNotEmpty &&
              license != 'null') ...[
            const SizedBox(height: 4),
            Text(
              license,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _textSecondary, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  // ── Payment card ───────────────────────────────────────────────
  Widget _buildPaymentCard(dynamic detail) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: const [
                Icon(Icons.account_balance_wallet_outlined,
                    color: _gold, size: 18),
                SizedBox(width: 8),
                Text(
                  'Thanh toán',
                  style: TextStyle(
                    color: _gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: _divider),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                  'Phương thức',
                  _paymentMethodLabel(detail.paymentMethodValue),
                ),
                const SizedBox(height: 4),
                Container(height: 1, color: _divider),
                const SizedBox(height: 4),
                // big final price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Giá cuối',
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        )),
                    Text(
                      _formatMoney(detail.finalPrice),
                      style: const TextStyle(
                        color: _gold,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(height: 1, color: _divider),
                const SizedBox(height: 4),
                _buildInfoRow('Giá gốc',  _formatMoney(detail.price)),
                _buildInfoRow('Giảm giá', _formatMoney(detail.discount),
                    valueColor: _green),
                _buildInfoRow('Phụ thu',  _formatMoney(detail.surcharge),
                    valueColor: _red),
                const SizedBox(height: 4),
                Container(height: 1, color: _divider),
                const SizedBox(height: 4),
                _buildInfoRow('Thu nhập ròng',
                    _formatMoney(detail.netIncome),
                    valueColor: _green),
                _buildInfoRow('Thu nhập người tạo',
                    _formatMoney(detail.creatorEarn)),
                _buildInfoRow('Hoa hồng hệ thống',
                    _formatMoney(detail.systemCommissionAmount)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Row widget ─────────────────────────────────────────────────
  Widget _buildInfoRow(
      String label,
      String? value, {
        IconData? icon,
        Color? valueColor,
      }) {
    final display = _safe(value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: _textSecondary),
            const SizedBox(width: 6),
          ],
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(
              display,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ??
                    (display == '---' ? _textSecondary : _textPrimary),
                fontSize: 13,
                fontWeight: display == '---'
                    ? FontWeight.w400
                    : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────
  String _safe(String? v) =>
      (v == null || v.trim().isEmpty || v == 'null') ? '---' : v;

  String _formatMoney(double? v) {
    if (v == null) return '---';
    final formatted = v
        .toStringAsFixed(0)
        .replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
    return '$formatted đ';
  }

  String _joinNonEmpty(List<String?> parts) => parts
      .where((p) => p != null && p.isNotEmpty && p != 'null')
      .join(', ');

  String _rideSourceLabel(dynamic detail) {
    if (detail?.rideSource == 1) return 'Đơn của khách hàng';
    return 'Đơn của tài xế';
  }

  String _rideTypeLabel(int? type) {
    switch (type) {
      case 1:
        return 'Chở người';
      case 2:
        return 'Bao xe 5 chỗ';
      case 3:
        return 'Bao xe 7 chỗ';
      default:
        return '---';
    }
  }

  String _paymentMethodLabel(int? paymentMethodValue) {
    switch (paymentMethodValue) {
      case 1:
        return 'Chuyển khoản';
      case 2:
        return 'Thanh toán bằng ví';
      case 3:
        return 'Tiền mặt (Thanh toán sau)';
      default:
        return '---';
    }
  }

  String _formatDateTime(String? iso) {
    if (iso == null || iso.trim().isEmpty || iso == 'null') {
      return '---';
    }
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(parsed.toLocal());
  }

  _RowData _rowData(String label, String? value, {IconData? icon}) =>
      _RowData(label, value, icon);
}

// ignore: unused_element
class _RowData {
  final String label;
  final String? value;
  final IconData? icon;
  const _RowData(this.label, this.value, this.icon);
}