// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import 'home_screen.dart';
// import 'login_screen.dart';
// import 'accountant/withdrawal_confirm_screen.dart'; // Đảm bảo import đúng đường dẫn này
// import '../services/api_service.dart';
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> {
//   bool _navigated = false;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _checkLoginStatus();
//     });
//   }
//
//   Future<void> _checkLoginStatus() async {
//     await Future.delayed(const Duration(seconds: 2));
//
//     final prefs = await SharedPreferences.getInstance();
//     final accessToken = prefs.getString('accessToken');
//     final int role = prefs.getInt('role') ?? 1; // Mặc định là 1 nếu không tìm thấy
//
//     if (!mounted || _navigated) return;
//
//     // 1. Không có token -> Về màn Login
//     if (accessToken == null || accessToken.isEmpty) {
//       _goLogin();
//       return;
//     }
//
//     // 2. Có token -> Verify bằng API
//     try {
//       final res = await ApiService.getPendingRides(
//         accessToken: accessToken,
//         page: 1,
//         pageSize: 1,
//       );
//
//       if (!mounted || _navigated) return;
//
//       if (res.statusCode == 200) {
//         // Token hợp lệ -> Điều hướng dựa trên Role
//         _goHomeByRole(role);
//       } else {
//         // Token hết hạn hoặc không hợp lệ
//         await _clearToken();
//         _goLogin();
//       }
//     } catch (_) {
//       // Lỗi kết nối hoặc lỗi server
//       if (mounted && !_navigated) _goLogin();
//     }
//   }
//
//   Future<void> _clearToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove('accessToken');
//     await prefs.remove('role'); // Xóa luôn role cho sạch data
//   }
//
//   // Hàm điều hướng phân quyền mới
//   void _goHomeByRole(int role) {
//     if (_navigated) return;
//     _navigated = true;
//
//     Navigator.of(context).pushReplacement(
//       MaterialPageRoute(
//         builder: (_) => role == 2
//             ? const WithdrawalConfirmList() // Giao diện Kế toán
//             : const HomeScreen(),           // Giao diện Admin
//       ),
//     );
//   }
//
//   void _goLogin() {
//     if (_navigated) return;
//     _navigated = true;
//
//     Navigator.of(context).pushReplacement(
//       MaterialPageRoute(builder: (_) => const LoginScreen()),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       body: DecoratedBox(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.blue, Colors.blueAccent],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: Center(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(Icons.local_taxi, size: 100, color: Colors.white),
//               SizedBox(height: 20),
//               Text(
//                 "BELU CAR ADMIN",
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   letterSpacing: 2,
//                 ),
//               ),
//               SizedBox(height: 40),
//               CircularProgressIndicator(color: Colors.white),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }