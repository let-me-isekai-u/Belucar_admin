import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';
import 'login_screen.dart';
import 'accountant/withdrawal_confirm_screen.dart';
import 'broker_rides/broker_ride_approval_list_screen.dart';
import '../services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Cấu hình thời gian hiển thị tối thiểu giống bên User
  static const Duration _minDisplayDuration = Duration(seconds: 3);
  late final DateTime _splashStart;
  bool _navigated = false;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _splashStart = DateTime.now(); // Ghi lại thời điểm bắt đầu
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _shimmerAnimation = CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginStatus();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  // Hàm đảm bảo splash hiện đủ thời gian mới chuyển màn
  Future<void> _ensureMinDisplay() async {
    final elapsed = DateTime.now().difference(_splashStart);
    if (elapsed < _minDisplayDuration) {
      await Future.delayed(_minDisplayDuration - elapsed);
    }
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    final int role = prefs.getInt('role') ?? 1;

    // 1. Không có token -> Đợi đủ thời gian rồi về Login
    if (accessToken == null || accessToken.isEmpty) {
      await _ensureMinDisplay();
      _goLogin();
      return;
    }

    // 2. Có token -> Verify bằng API
    try {
      final res = await ApiService.getPendingRides(
        accessToken: accessToken,
        page: 1,
        pageSize: 1,
      );

      if (!mounted || _navigated) return;

      if (res.statusCode == 200) {
        // Token hợp lệ -> Đợi đủ thời gian rồi điều hướng theo Role
        await _ensureMinDisplay();
        _goHomeByRole(role);
        return;
      } else {
        // Token hết hạn
        await _clearToken();
      }
    } catch (_) {
      // Lỗi kết nối
    }

    // Mặc định nếu có lỗi hoặc token hỏng thì về Login
    await _ensureMinDisplay();
    _goLogin();
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('role');
  }

  void _goHomeByRole(int role) {
    if (_navigated || !mounted) return;
    _navigated = true;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => role == 2
            ? const WithdrawalConfirmList()
            : role == 3
            ? const BrokerRideApprovalListScreen()
            : const HomeScreen(),
      ),
    );
  }

  void _goLogin() {
    if (_navigated || !mounted) return;
    _navigated = true;

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF4AB8E8),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Image.asset(
                'lib/assets/summer_splash.png',
                fit: BoxFit.contain,
                alignment: Alignment.center,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: size.height * 0.15,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.45),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 36,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ShimmerLoadingBar(animation: _shimmerAnimation),
                    const SizedBox(height: 10),
                    Text(
                      'Đang tải...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.70),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerLoadingBar extends StatelessWidget {
  final Animation<double> animation;

  const _ShimmerLoadingBar({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Container(
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 1.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(color: Colors.white.withValues(alpha: 0.25)),
                  FractionallySizedBox(
                    alignment: Alignment((animation.value * 3.0) - 1.5, 0),
                    widthFactor: 0.35,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.75),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
