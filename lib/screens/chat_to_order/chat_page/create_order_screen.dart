import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/chat/chat_ride_card_dto.dart';
import '../../../models/ride_count_models.dart';
import '../../../services/api_service.dart';

class CreateOrderScreen extends StatefulWidget {
  final String token;
  final ChatRideCardDto? currentRide;
  final bool canCreateRide;
  final bool isCreating;
  final Future<void> Function(Map<String, dynamic> body) onCreateRide;

  const CreateOrderScreen({
    super.key,
    required this.token,
    required this.currentRide,
    required this.canCreateRide,
    required this.isCreating,
    required this.onCreateRide,
  });

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fromAddressController = TextEditingController();
  final TextEditingController _toAddressController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _paymentContentController = TextEditingController();

  final int _type = 1;
  static const int _paymentMethod = 3;
  int _quantity = 1;
  DateTime? _pickupTime;

  List<ProvinceRideCountDto> _provinces = [];
  List<DistrictRideCountDto> _fromDistricts = [];
  List<DistrictRideCountDto> _toDistricts = [];

  int? _fromProvinceId;
  int? _toProvinceId;
  int? _fromDistrictId;
  int? _toDistrictId;

  bool _isLoadingProvince = false;
  bool _isLoadingFromDistrict = false;
  bool _isLoadingToDistrict = false;

  static const Color beluDarkBlue = Color(0xFF0288D1);
  static const Color accentColor = Color(0xFFE3F2FD);

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  @override
  void dispose() {
    _fromAddressController.dispose();
    _toAddressController.dispose();
    _customerPhoneController.dispose();
    _noteController.dispose();
    _paymentContentController.dispose();
    super.dispose();
  }

  Future<void> _loadProvinces() async {
    setState(() => _isLoadingProvince = true);

    try {
      final response = await ApiService.getRideCountByProvince(
        accessToken: widget.token,
      );

      final decoded = jsonDecode(response.body);
      final List<dynamic> rawList = _extractList(decoded);

      final data = rawList
          .map((e) => ProvinceRideCountDto.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (!mounted) return;

      setState(() {
        _provinces = data;
        _isLoadingProvince = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingProvince = false);
      _showError("Không tải được danh sách tỉnh/thành");
    }
  }

  Future<void> _loadFromDistricts(int provinceId) async {
    setState(() {
      _isLoadingFromDistrict = true;
      _fromDistricts = [];
      _fromDistrictId = null;
    });

    try {
      final response = await ApiService.getRideCountByDistrict(
        accessToken: widget.token,
        provinceId: provinceId,
      );

      final decoded = jsonDecode(response.body);
      final List<dynamic> rawList = _extractList(decoded);

      final data = rawList
          .map((e) => DistrictRideCountDto.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (!mounted) return;

      setState(() {
        _fromDistricts = data;
        _isLoadingFromDistrict = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingFromDistrict = false);
      _showError("Không tải được quận/huyện đón");
    }
  }

  Future<void> _loadToDistricts(int provinceId) async {
    setState(() {
      _isLoadingToDistrict = true;
      _toDistricts = [];
      _toDistrictId = null;
    });

    try {
      final response = await ApiService.getRideCountByDistrict(
        accessToken: widget.token,
        provinceId: provinceId,
      );

      final decoded = jsonDecode(response.body);
      final List<dynamic> rawList = _extractList(decoded);

      final data = rawList
          .map((e) => DistrictRideCountDto.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (!mounted) return;

      setState(() {
        _toDistricts = data;
        _isLoadingToDistrict = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingToDistrict = false);
      _showError("Không tải được quận/huyện trả");
    }
  }

  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) {
      return decoded;
    }

    if (decoded is Map<String, dynamic>) {
      if (decoded['data'] is List) {
        return decoded['data'] as List<dynamic>;
      }
      if (decoded['items'] is List) {
        return decoded['items'] as List<dynamic>;
      }
      if (decoded['result'] is List) {
        return decoded['result'] as List<dynamic>;
      }
    }

    return [];
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _pickupTime ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_pickupTime ?? now),
    );

    if (pickedTime == null) return;

    setState(() {
      _pickupTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!widget.canCreateRide || widget.isCreating) return;
    if (!_formKey.currentState!.validate()) return;

    if (_fromDistrictId == null || _toDistrictId == null) {
      _showError("Vui lòng chọn đầy đủ quận/huyện đón và trả");
      return;
    }

    if (_pickupTime == null) {
      _showError("Vui lòng chọn thời gian đón");
      return;
    }

    final body = <String, dynamic>{
      "fromDistrictId": _fromDistrictId,
      "toDistrictId": _toDistrictId,
      "type": _type,
      "fromAddress": _fromAddressController.text.trim(),
      "toAddress": _toAddressController.text.trim(),
      "customerPhone": _customerPhoneController.text.trim(),
      "pickupTime": _pickupTime!.toIso8601String(),
      "paymentMethod": _paymentMethod,
      "note": _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      "quantity": _quantity,
      "paymentContent": _paymentContentController.text.trim().isEmpty
          ? null
          : _paymentContentController.text.trim(),
    };

    await widget.onCreateRide(body);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.canCreateRide) return _buildBlockedView();

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCardGroup(
              title: "Lộ trình di chuyển",
              icon: Icons.route_outlined,
              children: [
                _buildRouteStep(
                  icon: Icons.radio_button_checked,
                  iconColor: Colors.green,
                  child: Column(
                    children: [
                      _buildProvinceDropdown(
                        label: "Tỉnh/Thành phố đón",
                        value: _fromProvinceId,
                        onChanged: widget.isCreating
                            ? null
                            : (v) async {
                          if (v == null) return;
                          setState(() {
                            _fromProvinceId = v;
                          });
                          await _loadFromDistricts(v);
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildDistrictDropdown(
                        label: "Quận/Huyện đón",
                        value: _fromDistrictId,
                        districts: _fromDistricts,
                        isLoading: _isLoadingFromDistrict,
                        onChanged: (v) => setState(() => _fromDistrictId = v),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _fromAddressController,
                        label: "Địa chỉ đón chi tiết",
                        hint: "Số nhà, tên đường...",
                        validator: _requiredValidator,
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 11),
                  child: SizedBox(
                    height: 20,
                    child: VerticalDivider(
                      thickness: 2,
                      color: Colors.grey,
                    ),
                  ),
                ),
                _buildRouteStep(
                  icon: Icons.location_on,
                  iconColor: Colors.redAccent,
                  child: Column(
                    children: [
                      _buildProvinceDropdown(
                        label: "Tỉnh/Thành phố trả",
                        value: _toProvinceId,
                        onChanged: widget.isCreating
                            ? null
                            : (v) async {
                          if (v == null) return;
                          setState(() {
                            _toProvinceId = v;
                          });
                          await _loadToDistricts(v);
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildDistrictDropdown(
                        label: "Quận/Huyện trả",
                        value: _toDistrictId,
                        districts: _toDistricts,
                        isLoading: _isLoadingToDistrict,
                        onChanged: (v) => setState(() => _toDistrictId = v),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _toAddressController,
                        label: "Địa chỉ trả chi tiết",
                        hint: "Văn phòng, khách sạn...",
                        validator: _requiredValidator,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildCardGroup(
              title: "Thông tin đơn hàng",
              icon: Icons.person_outline,
              children: [
                _buildTextField(
                  controller: _customerPhoneController,
                  label: "Số điện thoại khách hàng",
                  prefixIcon: Icons.phone_android,
                  keyboardType: TextInputType.phone,
                  validator: _phoneValidator,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: widget.isCreating ? null : _pickDateTime,
                        child: InputDecorator(
                          decoration: _inputDecoration(
                            "Thời gian đón",
                            prefixIcon: Icons.calendar_today,
                          ),
                          child: Text(
                            _pickupTime == null
                                ? "Chọn giờ"
                                : DateFormat('HH:mm dd/MM').format(_pickupTime!),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<int>(
                        value: _quantity,
                        decoration: _inputDecoration("Số người"),
                        items: List.generate(
                          7,
                              (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text("${i + 1}"),
                          ),
                        ),
                        onChanged: (v) => setState(() => _quantity = v!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildCardGroup(
              title: "Thanh toán & Ghi chú",
              icon: Icons.payments_outlined,
              children: [
                InputDecorator(
                  decoration: _inputDecoration("Phương thức thanh toán"),
                  child: const Text(
                    "Tiền mặt",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _paymentContentController,
                  label: "Nội dung thanh toán",
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _noteController,
                  label: "Ghi chú cho tài xế",
                  maxLines: 2,
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: widget.isCreating ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: beluDarkBlue,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: widget.isCreating
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                "XÁC NHẬN TẠO ĐƠN",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCardGroup({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: beluDarkBlue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: beluDarkBlue,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteStep({
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Icon(icon, size: 22, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? prefixIcon,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      keyboardType: keyboardType,
      enabled: !widget.isCreating,
      decoration: _inputDecoration(label, hint: hint, prefixIcon: prefixIcon),
    );
  }

  InputDecoration _inputDecoration(
      String label, {
        String? hint,
        IconData? prefixIcon,
      }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: beluDarkBlue, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      labelStyle: const TextStyle(fontSize: 14, color: Colors.blueGrey),
    );
  }

  Widget _buildProvinceDropdown({
    required String label,
    required int? value,
    required ValueChanged<int?>? onChanged,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      decoration: _inputDecoration(label),
      items: _provinces
          .map(
            (e) => DropdownMenuItem(
          value: e.id,
          child: Text(
            e.name,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      )
          .toList(),
      onChanged: _isLoadingProvince ? null : onChanged,
      validator: (v) => v == null ? "Bắt buộc" : null,
      hint: Text(_isLoadingProvince ? "Đang tải..." : "Chọn tỉnh"),
    );
  }

  Widget _buildDistrictDropdown({
    required String label,
    required int? value,
    required List<DistrictRideCountDto> districts,
    required bool isLoading,
    required ValueChanged<int?>? onChanged,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      decoration: _inputDecoration(label),
      items: districts
          .map(
            (e) => DropdownMenuItem(
          value: e.id,
          child: Text(
            e.name,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      )
          .toList(),
      onChanged: isLoading ? null : onChanged,
      validator: (v) => v == null ? "Bắt buộc" : null,
      hint: Text(isLoading ? "Đang tải..." : "Chọn huyện"),
    );
  }

  Widget _buildBlockedView() {
    final ride = widget.currentRide;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              ride == null ? "Không thể tạo đơn" : "Đơn hàng đang xử lý",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ride == null
                  ? "Hệ thống hiện không tiếp nhận đơn mới."
                  : "Mã đơn: ${ride.code}\nTrạng thái: ${ride.status}\n\nVui lòng hoàn tất đơn hiện tại trước khi tạo đơn mới.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _requiredValidator(String? v) =>
      (v == null || v.isEmpty) ? "Không được để trống" : null;

  String? _phoneValidator(String? v) =>
      (v == null || v.length < 9) ? "SĐT không hợp lệ" : null;
}