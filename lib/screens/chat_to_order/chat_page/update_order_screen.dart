import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/chat/chat_ride_card_dto.dart';
import '../../../models/ride_count_models.dart';
import '../../../services/api_service.dart';

class UpdateOrderScreen extends StatefulWidget {
  final String token;
  final List<ChatRideCardDto> rides;
  final int? latestRideId;
  final ChatRideCardDto? currentRide;
  final int? resolvedRideStatus;
  final bool isCheckingRideStatus;
  final bool canUpdateRide;
  final bool canCancelRide;
  final bool isUpdating;
  final bool isCancelling;
  final ValueChanged<int> onSelectRide;
  final Future<void> Function(int id, Map<String, dynamic> body) onUpdateRide;
  final Future<void> Function(int id) onCancelRide;

  const UpdateOrderScreen({
    super.key,
    required this.token,
    required this.rides,
    required this.latestRideId,
    required this.currentRide,
    required this.resolvedRideStatus,
    required this.isCheckingRideStatus,
    required this.canUpdateRide,
    required this.canCancelRide,
    required this.isUpdating,
    required this.isCancelling,
    required this.onSelectRide,
    required this.onUpdateRide,
    required this.onCancelRide,
  });

  @override
  State<UpdateOrderScreen> createState() => _UpdateOrderScreenState();
}

class _UpdateOrderScreenState extends State<UpdateOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isEditing = false;

  late final TextEditingController _fromAddressController;
  late final TextEditingController _toAddressController;
  late final TextEditingController _customerPhoneController;
  late final TextEditingController _noteController;

  final int _type = 1;
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

  @override
  void initState() {
    super.initState();
    _initData();
    _loadProvinces();
  }

  void _initData() {
    final ride = widget.currentRide;
    _fromAddressController = TextEditingController(text: ride?.fromAddress ?? '');
    _toAddressController = TextEditingController(text: ride?.toAddress ?? '');
    _customerPhoneController = TextEditingController(text: ride?.customerPhone ?? '');
    _noteController = TextEditingController(text: ride?.note ?? '');
    _quantity = ride?.quantity ?? 1;
    _pickupTime = ride?.pickupTime;
    _fromDistrictId = ride?.fromDistrictId;
    _toDistrictId = ride?.toDistrictId;
  }

  @override
  void didUpdateWidget(covariant UpdateOrderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldRideId = oldWidget.currentRide?.rideId;
    final newRideId = widget.currentRide?.rideId;

    if (oldRideId != newRideId) {
      final ride = widget.currentRide;
      _fromAddressController.text = ride?.fromAddress ?? '';
      _toAddressController.text = ride?.toAddress ?? '';
      _customerPhoneController.text = ride?.customerPhone ?? '';
      _noteController.text = ride?.note ?? '';
      _quantity = ride?.quantity ?? 1;
      _pickupTime = ride?.pickupTime;
      _fromDistrictId = ride?.fromDistrictId;
      _toDistrictId = ride?.toDistrictId;
      _isEditing = false;
    }

    if (oldWidget.resolvedRideStatus != widget.resolvedRideStatus &&
        widget.resolvedRideStatus == 5) {
      _isEditing = false;
    }
  }

  @override
  void dispose() {
    _fromAddressController.dispose();
    _toAddressController.dispose();
    _customerPhoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _isBusy =>
      widget.isUpdating || widget.isCancelling || widget.isCheckingRideStatus;

  int get _effectiveStatus =>
      widget.resolvedRideStatus ?? widget.currentRide?.status ?? 0;

  bool get _isCancelled => _effectiveStatus == 5;

  bool get _isLatestRide =>
      widget.currentRide != null &&
      widget.latestRideId != null &&
      widget.currentRide!.rideId == widget.latestRideId;

  Future<void> _loadProvinces() async {
    setState(() => _isLoadingProvince = true);
    final data = await ApiService.getRideCountByProvince(widget.token);
    if (!mounted) return;
    setState(() {
      _provinces = data;
      _isLoadingProvince = false;
    });
  }

  Future<void> _loadFromDistricts(int provinceId) async {
    setState(() {
      _isLoadingFromDistrict = true;
      _fromDistricts = [];
      _fromDistrictId = null;
    });
    final data = await ApiService.getRideCountByDistrict(widget.token, provinceId);
    if (!mounted) return;
    setState(() {
      _fromDistricts = data;
      _isLoadingFromDistrict = false;
    });
  }

  Future<void> _loadToDistricts(int provinceId) async {
    setState(() {
      _isLoadingToDistrict = true;
      _toDistricts = [];
      _toDistrictId = null;
    });
    final data = await ApiService.getRideCountByDistrict(widget.token, provinceId);
    if (!mounted) return;
    setState(() {
      _toDistricts = data;
      _isLoadingToDistrict = false;
    });
  }

  Future<void> _submitUpdate() async {
    final ride = widget.currentRide;
    if (ride == null || !_formKey.currentState!.validate()) return;
    if (!widget.canUpdateRide || _isBusy) return;
    if (_pickupTime == null) return;

    final body = <String, dynamic>{
      "fromDistrictId": _fromDistrictId,
      "toDistrictId": _toDistrictId,
      "type": _type,
      "fromAddress": _fromAddressController.text.trim(),
      "toAddress": _toAddressController.text.trim(),
      "customerPhone": _customerPhoneController.text.trim(),
      "pickupTime": _pickupTime!.toIso8601String(),
      "note": _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      "quantity": _quantity,
    };

    await widget.onUpdateRide(ride.rideId, body);
    if (mounted) {
      setState(() => _isEditing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.currentRide;
    if (ride == null) {
      return const Center(child: Text("Chưa có đơn để cập nhật"));
    }

    return Container(
      color: const Color(0xFFF8FAFC),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.rides.length > 1) ...[
            _buildRideSelector(),
            const SizedBox(height: 16),
          ],
          _buildSummaryCard(ride, _isCancelled),
          const SizedBox(height: 16),

          if (widget.isCheckingRideStatus)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Đang kiểm tra trạng thái đơn hàng...",
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          if (!_isCancelled && !_isLatestRide) _buildOldRideNotice(),

          if (!_isCancelled && !_isEditing) _buildMainActions(),

          if (_isEditing) ...[
            _buildEditFormHeader(),
            const SizedBox(height: 12),
            _buildActualForm(),
            const SizedBox(height: 20),
            _buildFormActions(),
          ],

          if (_isCancelled) _buildCancelledAlert(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMainActions() {
    if (!_isLatestRide) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: widget.canCancelRide && !_isBusy ? _submitCancel : null,
          icon: const Icon(Icons.cancel_outlined, size: 18),
          label: const Text("HỦY ĐƠN CŨ"),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.redAccent,
            side: const BorderSide(color: Colors.redAccent),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.canCancelRide && !_isBusy ? _submitCancel : null,
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text("HỦY ĐƠN"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: widget.canUpdateRide && !_isBusy
                ? () => setState(() => _isEditing = true)
                : null,
            icon: const Icon(Icons.edit_note, size: 18),
            label: const Text("SỬA ĐƠN"),
            style: ElevatedButton.styleFrom(
              backgroundColor: beluDarkBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRideSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "DANH SÁCH ĐƠN",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: beluDarkBlue,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.rides.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final ride = widget.rides[index];
              final isSelected = widget.currentRide?.rideId == ride.rideId;
              final isLatest = widget.latestRideId == ride.rideId;

              return InkWell(
                onTap: () => widget.onSelectRide(ride.rideId),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 180,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? beluDarkBlue : Colors.grey.shade300,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isLatest)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            "Mới nhất",
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      Text(
                        ride.code,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          ride.pickupTime == null
                              ? "Chưa có giờ đón"
                              : DateFormat('HH:mm dd/MM').format(ride.pickupTime!),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOldRideNotice() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: const Text(
        "Đây là đơn cũ. Bạn chỉ có thể hủy đơn này, không được chỉnh sửa.",
        style: TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _buildEditFormHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "CHỈNH SỬA CHI TIẾT",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: beluDarkBlue,
          ),
        ),
        TextButton.icon(
          onPressed: () => setState(() => _isEditing = false),
          icon: const Icon(Icons.close, size: 16, color: Colors.grey),
          label: const Text("Đóng", style: TextStyle(color: Colors.grey)),
        )
      ],
    );
  }

  Widget _buildActualForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildCardGroup(
            title: "Lộ trình di chuyển",
            icon: Icons.map_outlined,
            children: [
              _buildProvinceDropdown(
                label: "Tỉnh đón",
                value: _fromProvinceId,
                onChanged: (v) async {
                  if (v == null) return;
                  setState(() => _fromProvinceId = v);
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
                label: "Địa chỉ đón",
                validator: _requiredValidator,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(),
              ),
              _buildProvinceDropdown(
                label: "Tỉnh trả",
                value: _toProvinceId,
                onChanged: (v) async {
                  if (v == null) return;
                  setState(() => _toProvinceId = v);
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
                label: "Địa chỉ trả",
                validator: _requiredValidator,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCardGroup(
            title: "Thông tin khác",
            icon: Icons.info_outline,
            children: [
              _buildTextField(
                controller: _customerPhoneController,
                label: "SĐT khách",
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDateTime,
                child: InputDecorator(
                  decoration: _inputDecoration(
                    "Giờ đón",
                    prefixIcon: Icons.access_time,
                  ),
                  child: Text(
                    _pickupTime == null
                        ? "Chọn giờ"
                        : DateFormat('HH:mm dd/MM').format(_pickupTime!),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _noteController,
                label: "Ghi chú",
                maxLines: 2,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _pickupTime ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      helpText: "CHỌN NGÀY ĐÓN",
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_pickupTime ?? now),
      helpText: "CHỌN GIỜ ĐÓN",
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

  Widget _buildFormActions() {
    return ElevatedButton(
      onPressed: widget.canUpdateRide && !_isBusy ? _submitUpdate : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: widget.isUpdating
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
        "XÁC NHẬN CẬP NHẬT",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSummaryCard(ChatRideCardDto ride, bool isCancelled) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCancelled
              ? [Colors.red.shade400, Colors.red.shade600]
              : [beluDarkBlue, const Color(0xFF0277BD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ride.code,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _statusText(_effectiveStatus).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                _formatMoney(ride.finalPrice),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          _summaryRow(Icons.location_on_outlined, "Đón: ${ride.fromAddress}"),
          const SizedBox(height: 6),
          _summaryRow(Icons.flag_outlined, "Trả: ${ride.toAddress}"),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _submitCancel() async {
    final ride = widget.currentRide;
    if (ride == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận huỷ đơn"),
        content: Text("Bạn có chắc muốn huỷ đơn ${ride.code} không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Không"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text("Huỷ đơn"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.onCancelRide(ride.rideId);
    }
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
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
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
                Icon(icon, size: 18, color: beluDarkBlue),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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

  InputDecoration _inputDecoration(String label, {IconData? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
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
      decoration: _inputDecoration(label, prefixIcon: prefixIcon),
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

  Widget _buildCancelledAlert() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: const Text(
        "Đơn này đã bị huỷ. Không thể thao tác thêm.",
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formatMoney(double value) =>
      '${NumberFormat('#,###', 'vi_VN').format(value)} đ';

  String _statusText(int status) {
    switch (status) {
      case 1:
        return 'Mới tạo';
      case 2:
        return 'Đã nhận';
      case 3:
        return 'Đang đi';
      case 4:
        return 'Hoàn tất';
      case 5:
        return 'Đã huỷ';
      default:
        return 'Chờ xử lý';
    }
  }

  String? _requiredValidator(String? v) =>
      (v == null || v.isEmpty) ? "Bắt buộc" : null;
}
