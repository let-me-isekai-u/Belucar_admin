import 'dart:ui'; // Quan trọng để dùng ImageFilter
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'statistics_screen.dart';
import 'status/status_one_screen.dart';
import 'status/status_two_screen.dart';
import 'status/status_three_screen.dart';
import 'status/status_4_screen.dart';
import 'status/status_5_screen.dart';
import 'accountant/withdrawal_history_screen.dart';
import 'voucher_used_screen.dart';
import 'chat_to_order/list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _adminName = "Lý Tổng!!";
  String _accessToken = "";

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
  }

  Future<void> _loadAdminInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _adminName = "Lý Tổng =))";
      _accessToken = prefs.getString('accessToken') ?? "";
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Lớp nền
          Positioned.fill(
            child: Image.asset(
              'lib/assets/belucar_summer_splash.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),

          // Lớp blur + overlay nhẹ
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                color: Colors.black.withValues(alpha: 0.05),
              ),
            ),
          ),

          // Nội dung chính của App
          Column(
            children: [
              _buildCustomAppBar(context),

              // Header Chào mừng
              _buildHeaderWelcome(),

              const SizedBox(height: 10),

              // Danh sách Menu
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _sectionHeader("QUẢN LÝ VẬN HÀNH", Colors.red),

                    _buildMenuButton(
                      context,
                      title: "Chuyến chưa có tài xế",
                      subtitle: "Đang chờ điều phối ngay",
                      icon: Icons.hourglass_empty_rounded,
                      color: Colors.orange.shade800,
                      status: 1,
                    ),
                    _buildMenuButton(
                      context,
                      title: "Đã có tài xế",
                      subtitle: "Tài xế đã xác nhận đơn",
                      icon: Icons.assignment_ind_rounded,
                      color: Colors.blue.shade700,
                      status: 2,
                    ),
                    _buildMenuButton(
                      context,
                      title: "Đang di chuyển",
                      subtitle: "Xe đang trên đường tới đích",
                      icon: Icons.local_taxi_rounded,
                      color: Colors.green.shade700,
                      status: 3,
                    ),
                    _buildMenuButton(
                      context,
                      title: "Đã hoàn thành",
                      subtitle: "Lịch sử chuyến thành công",
                      icon: Icons.check_circle_rounded,
                      color: Colors.teal.shade700,
                      status: 4,
                    ),
                    _buildMenuButton(
                      context,
                      title: "Tin nhắn đặt đơn",
                      subtitle: "Danh sách đơn đặt bằng tin nhắn",
                      icon: Icons.chat_bubble,
                      color: Colors.lightBlue,
                      status: 5,
                    ),
                    _buildMenuButton(
                      context,
                      title: "Đã hủy",
                      subtitle: "Danh sách đơn đã hủy bỏ",
                      icon: Icons.cancel_rounded,
                      color: Colors.red.shade900,
                      status: 6,
                    ),

                    const SizedBox(height: 15),
                    _sectionHeader("BÁO CÁO & TÀI CHÍNH", Colors.red),

                    _buildSpecialButton(
                      context,
                      title: "Thống kê doanh thu",
                      subtitle: "Tổng quan hiệu suất kinh doanh",
                      icon: _assetIconWrapper("lib/assets/icons/bieudo.jpg"),
                      color: Colors.purple.shade700,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StatisticsScreen()),
                      ),
                    ),
                    _buildSpecialButton(
                      context,
                      title: "Lịch sử rút tiền",
                      subtitle: "Quản lý dòng tiền hệ thống",
                      icon: _assetIconWrapper("lib/assets/icons/viTien.jpg"),
                      color: Colors.brown.shade700,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WithdrawalHistoryScreen()),
                      ),
                    ),
                    _buildSpecialButton(
                      context,
                      title: "Voucher Tết",
                      subtitle: "Danh sách voucher được sử dụng",
                      icon: _assetIconWrapper("lib/assets/icons/Lixi.png"),
                      color: Colors.red.shade700,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const VoucherUsedScreen()),
                      ),
                    ),

                    const SizedBox(height: 25),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget AppBar tùy chỉnh để trong suốt hòa vào background
  Widget _buildCustomAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        bottom: 10,
      ),
      child: Row(
        children: [
          const SizedBox(width: 50),
          IconButton(
            icon: const Icon(
              Icons.power_settings_new_rounded,
              color: Colors.white,
            ),
            onPressed: () => _logout(context),
          )
        ],
      ),
    );
  }

  Widget _buildHeaderWelcome() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(25, 10, 25, 25),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
            ),
            child: const CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white,
              backgroundImage: AssetImage('lib/assets/icons/admin_launcher.png'),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 1,
              shadows: const [
                Shadow(color: Colors.black45, blurRadius: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget bọc icon asset cho thống nhất
  Widget _assetIconWrapper(String path) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Image.asset(path, width: 32, height: 32),
    );
  }

  Widget _buildMenuButton(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required int status,
      }) {
    return _cardWrapper(
      onTap: () {
        Widget targetScreen;
        switch (status) {
          case 1:
            targetScreen = const StatusOneScreen();
            break;
          case 2:
            targetScreen = const StatusTwoScreen();
            break;
          case 3:
            targetScreen = const StatusThreeScreen();
            break;
          case 4:
            targetScreen = const StatusFourScreen();
            break;
          case 5:
            targetScreen = MessageListScreen(token: _accessToken);
            break;
          case 6:
            targetScreen = const StatusFiveScreen();
            break;
          default:
            return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => targetScreen),
        );
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _iconContainer(icon, color),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Colors.redAccent,
        ),
      ),
    );
  }

  Widget _buildSpecialButton(
      BuildContext context, {
        required String title,
        required String subtitle,
        required Widget icon,
        required Color color,
        required VoidCallback onTap,
      }) {
    return _cardWrapper(
      onTap: onTap,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: icon,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFFB71C1C),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: const Icon(
          Icons.stars_rounded,
          size: 20,
          color: Colors.amber,
        ),
      ),
    );
  }

  Widget _cardWrapper({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.amber.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }

  Widget _iconContainer(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}