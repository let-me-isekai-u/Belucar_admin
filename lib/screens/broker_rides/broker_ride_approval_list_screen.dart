import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/broker_ride_approval_model.dart';
import '../../services/kyc_api_admin_service.dart';
import '../login_screen.dart';
import '../status/status_three_screen.dart';
import '../status/status_two_screen.dart';
import 'broker_ride_approval_detail_screen.dart';

// ─── Color Tokens ───────────────────────────────────────────────────
class _C {
  static const bg          = Color(0xFF0A0E1A);
  static const surface     = Color(0xFF111827);
  static const card        = Color(0xFF1A2235);
  static const cardBorder  = Color(0xFF243044);

  static const red         = Color(0xFFEF4444);
  static const redGlow     = Color(0x33EF4444);
  static const redDeep     = Color(0xFFB91C1C);
  static const orange      = Color(0xFFF59E0B);
  static const orangeGlow  = Color(0x33F59E0B);
  static const green       = Color(0xFF10B981);
  static const greenGlow   = Color(0x2210B981);
  static const blue        = Color(0xFF3B82F6);
  static const blueGlow    = Color(0x333B82F6);

  static const textPrimary   = Color(0xFFF1F5F9);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted     = Color(0xFF475569);
}

// ─── Tab enum ───────────────────────────────────────────────────────
enum _Tab { pending, accepted, processing }

class BrokerRideApprovalListScreen extends StatefulWidget {
  const BrokerRideApprovalListScreen({super.key});

  @override
  State<BrokerRideApprovalListScreen> createState() =>
      _BrokerRideApprovalListScreenState();
}

class _BrokerRideApprovalListScreenState
    extends State<BrokerRideApprovalListScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final List<BrokerRideApprovalModel> _items = [];
  final NumberFormat _currencyFormat =
  NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  _Tab _currentTab = _Tab.pending;
  int _currentPage = 1;
  bool _hasNext = true;
  bool _isLoading = false;
  bool _hasPermission = true;
  String? _errorMessage;

  late AnimationController _fadeCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500),
    );
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _loadPendingBrokerRides();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 160) {
      if (!_isLoading && _hasNext) _loadPendingBrokerRides();
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
    _fadeCtrl.reset();

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
        _fadeCtrl.forward();
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openDetail(BrokerRideApprovalModel item) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            BrokerRideApprovalDetailScreen(brokerRideId: item.id),
      ),
    );
    if (changed == true && mounted) {
      await _loadPendingBrokerRides(refresh: true);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  void _switchTab(_Tab tab) {
    if (_currentTab == tab) return;
    setState(() => _currentTab = tab);

    if (tab == _Tab.pending) return; // handled in this screen
    // For other tabs, navigate and keep this screen in stack
    if (tab == _Tab.accepted) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const StatusTwoScreen()))
          .then((_) => setState(() => _currentTab = _Tab.pending));
    } else {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const StatusThreeScreen()))
          .then((_) => setState(() => _currentTab = _Tab.pending));
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
          color: _C.red,
          backgroundColor: _C.card,
          onRefresh: () => _loadPendingBrokerRides(refresh: true),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: const SizedBox(height: 100)),
              SliverToBoxAdapter(child: _buildTabBar()),
              SliverToBoxAdapter(child: const SizedBox(height: 20)),
              SliverToBoxAdapter(child: _buildSectionHeader()),
              SliverToBoxAdapter(child: const SizedBox(height: 16)),
              _buildSliverBody(),
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
      leading: const SizedBox(),
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
                colors: [_C.red, Color(0xFFDC2626)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: _C.redGlow, blurRadius: 12, spreadRadius: 2),
              ],
            ),
            child: const Icon(
              Icons.assignment_late_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Duyệt Đơn Tài Xế Đẩy",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                "Broker Ride Approval",
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
      actions: [
        IconButton(
          onPressed: _logout,
          icon: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _C.cardBorder),
            ),
            child: const Icon(Icons.logout_rounded, size: 18, color: _C.textSecondary),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTabBar() {
    final tabs = [
      (_Tab.pending,   Icons.hourglass_top_rounded,   'Chờ duyệt'),
      (_Tab.accepted,  Icons.assignment_ind_rounded,   'Đã nhận'),
      (_Tab.processing, Icons.local_taxi_rounded,      'Di chuyển'),
    ];

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
          children: tabs.map((t) {
            final isSelected = _currentTab == t.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () => _switchTab(t.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: isSelected
                      ? BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_C.red, Color(0xFFDC2626)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: _C.redGlow,
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  )
                      : null,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        t.$2,
                        size: 16,
                        color: isSelected ? Colors.white : _C.textMuted,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        t.$3,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected ? Colors.white : _C.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top_rounded, size: 16, color: _C.textMuted),
          const SizedBox(width: 8),
          const Text(
            "Đơn chờ duyệt",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _C.textPrimary,
            ),
          ),
          const Spacer(),
          if (!_isLoading && _items.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _C.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _C.orange.withOpacity(0.3)),
              ),
              child: Text(
                '${_items.length} đơn',
                style: const TextStyle(
                  fontSize: 12,
                  color: _C.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (_isLoading && _items.isEmpty) _buildPulseDot(),
        ],
      ),
    );
  }

  Widget _buildPulseDot() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _C.orange,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _C.orange.withOpacity(_pulseAnim.value),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            "Đang tải",
            style: TextStyle(fontSize: 12, color: _C.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverBody() {
    if (!_hasPermission) {
      return SliverFillRemaining(
        child: _buildStateView(
          icon: Icons.lock_outline_rounded,
          message: 'Tính năng này chỉ dành cho admin role = 3.',
        ),
      );
    }

    if (_isLoading && _items.isEmpty) {
      return SliverToBoxAdapter(child: _buildSkeleton());
    }

    if (_errorMessage != null && _items.isEmpty) {
      return SliverFillRemaining(
        child: _buildStateView(
          icon: Icons.error_outline_rounded,
          message: _errorMessage!,
          actionLabel: 'Tải lại',
          onPressed: () => _loadPendingBrokerRides(refresh: true),
        ),
      );
    }

    if (_items.isEmpty) {
      return SliverFillRemaining(
        child: _buildStateView(
          icon: Icons.inbox_rounded,
          message: 'Hiện không có đơn tài xế đẩy nào chờ duyệt.',
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(color: _C.red),
              ),
            );
          }
          return FadeTransition(
            opacity: _fadeAnim,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildRideCard(_items[index]),
            ),
          );
        },
        childCount: _items.length + (_hasNext ? 1 : 0),
      ),
    );
  }

  Widget _buildRideCard(BrokerRideApprovalModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openDetail(item),
          splashColor: _C.red.withOpacity(0.08),
          highlightColor: _C.red.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ──────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _C.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _C.red.withOpacity(0.25)),
                      ),
                      child: const Icon(
                        Icons.assignment_late_rounded,
                        color: _C.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.code.isEmpty
                                ? 'Đơn Tài Xế Đẩy #${item.id}'
                                : item.code,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _C.textPrimary,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: ${item.id}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: _C.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _statusChip(_statusLabel(item.status, item.statusText)),
                  ],
                ),

                const SizedBox(height: 14),
                _buildDivider(),
                const SizedBox(height: 14),

                // ── Info rows ───────────────────────────────────
                _infoRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Tài xế tạo',
                  value: item.createdDriverName.isEmpty
                      ? 'ID ${item.createdDriverId}'
                      : '${item.createdDriverName} (#${item.createdDriverId})',
                  color: _C.blue,
                ),
                _infoRow(
                  icon: Icons.schedule_rounded,
                  label: 'Giờ đón',
                  value: _formatDateTime(item.pickupTime),
                  color: _C.orange,
                ),
                _infoRow(
                  icon: Icons.group_rounded,
                  label: 'Nhóm chat',
                  value: item.groupName.isEmpty
                      ? 'Group #${item.groupId}'
                      : item.groupName,
                  color: _C.textSecondary,
                ),

                const SizedBox(height: 10),

                // ── Route ───────────────────────────────────────
                _buildRouteCard(item),

                const SizedBox(height: 12),

                // ── Amount row ──────────────────────────────────
                _buildAmountRow(item),

                if (item.note.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _C.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _C.cardBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.notes_rounded,
                          size: 14,
                          color: _C.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.note,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _C.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // ── Footer ──────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'Xem chi tiết',
                      style: TextStyle(
                        fontSize: 12,
                        color: _C.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: _C.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: _C.cardBorder);
  }

  Widget _buildRouteCard(BrokerRideApprovalModel item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.cardBorder),
      ),
      child: Column(
        children: [
          _routeRow(
            icon: Icons.radio_button_checked,
            label: 'Đón',
            value: item.fromAddress,
            color: _C.green,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 9, top: 4, bottom: 4),
            child: Container(
              width: 1,
              height: 16,
              color: _C.cardBorder,
            ),
          ),
          _routeRow(
            icon: Icons.location_on_rounded,
            label: 'Đến',
            value: item.toAddress,
            color: _C.red,
          ),
        ],
      ),
    );
  }

  Widget _routeRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                value.isEmpty ? '-' : value,
                style: const TextStyle(
                  fontSize: 13,
                  color: _C.textPrimary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountRow(BrokerRideApprovalModel item) {
    return Row(
      children: [
        Expanded(
          child: _amountTile(
            icon: Icons.local_offer_rounded,
            label: 'Giá chào',
            value: _currencyFormat.format(item.offerPrice),
            color: _C.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _amountTile(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Hoa hồng tạo',
            value: _currencyFormat.format(item.creatorEarn),
            color: _C.green,
          ),
        ),
      ],
    );
  }

  Widget _amountTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: _C.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _C.textMuted,
                    ),
                  ),
                  TextSpan(
                    text: value.isEmpty ? '-' : value,
                    style: const TextStyle(color: _C.textSecondary),
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _C.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.orange.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _C.orange,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.3,
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _C.surface,
                shape: BoxShape.circle,
                border: Border.all(color: _C.cardBorder, width: 2),
              ),
              child: Icon(icon, size: 32, color: _C.textMuted),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: _C.textSecondary,
                height: 1.5,
              ),
            ),
            if (actionLabel != null && onPressed != null) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: onPressed,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_C.red, Color(0xFFDC2626)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _C.redGlow,
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(3, (i) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            height: 220,
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

  String _formatDateTime(DateTime? value) {
    if (value == null) return '-';
    return _dateTimeFormat.format(value.toLocal());
  }

  String _statusLabel(int status, String fallback) {
    if (status == 0) return 'Chờ duyệt';
    if (fallback.trim().isNotEmpty) return fallback;
    return 'Chờ duyệt';
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