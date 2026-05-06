import 'package:flutter/foundation.dart';

import '../../models/role_1/ride_detail.dart';
import '../../services/role1/ride_detail_role1_service.dart';

class RideDetailRole1Provider extends ChangeNotifier {
  RideDetail? _rideDetail;
  bool _isLoading = false;
  String? _errorMessage;

  RideDetail? get rideDetail => _rideDetail;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchRideDetail({
    required String accessToken,
    required int rideId,
    required int rideSource,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await RideDetailRole1Service.getRideDetailRole1Item(
        accessToken: accessToken,
        rideId: rideId,
        rideSource: rideSource,
      );

      _rideDetail = result;
    } catch (e) {
      _errorMessage = e.toString();
      _rideDetail = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearRideDetail() {
    _rideDetail = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}