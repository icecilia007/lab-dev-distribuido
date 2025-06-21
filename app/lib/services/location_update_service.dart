// location_update_service.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class LocationUpdateService {
  String _lastSentStatus = "DISPONIVEL";
  Function(String)? onStatusChanged;
  String get lastSentStatus => _lastSentStatus;
  final ApiService _apiService;
  Timer? _timer;
  Position? _lastPosition;
  final int _driverId;
  int? _currentOrderId;
  static const int _updateIntervalMinutes = 2;

  LocationUpdateService({
    required ApiService apiService,
    required int driverId,
  }) : _apiService = apiService,
        _driverId = driverId;

  void setStatusCallback(Function(String) callback) {
    onStatusChanged = callback;
  }

  void setLastSentStatus(String status) {
    if (_lastSentStatus != status) {
      _lastSentStatus = status;

      // Notify any listeners about the status change
      if (onStatusChanged != null) {
        onStatusChanged!(status);
      }
    }
  }

  void startLocationUpdates(int? orderId) {
    _currentOrderId = orderId;
    _stopTimer();

    _timer = Timer.periodic(
        Duration(minutes: _updateIntervalMinutes),
            (_) => _sendLocationUpdate()
    );

    _sendLocationUpdate();
  }

  void stopLocationUpdates() {
    _stopTimer();
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void updateOrderId(int? orderId) {
    _currentOrderId = orderId;
    // Send an immediate update with the new order ID
    _sendLocationUpdate();
  }

  Future<void> _sendLocationUpdate() async {
    try {
      final Position currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );
      print('Enviando posição atual para o backend: Latitude: ${currentPosition.latitude}, Longitude: ${currentPosition.longitude}');
      String statusVeiculo;

      if (_currentOrderId == null) {
        statusVeiculo = "DISPONIVEL";
      } else {
        if (_lastPosition != null &&
            _lastPosition!.latitude == currentPosition.latitude &&
            _lastPosition!.longitude == currentPosition.longitude) {
          statusVeiculo = "PARADO"; // Stopped
        } else {
          statusVeiculo = "EM_MOVIMENTO"; // Moving
        }
      }

      await _apiService.atualizarLocalizacaoMotorista(
        _driverId,
        currentPosition.latitude,
        currentPosition.longitude,
        statusVeiculo,
        pedidoId: _currentOrderId,
      );

      final bool success = await _apiService.atualizarLocalizacaoMotorista(
        _driverId,
        currentPosition.latitude,
        currentPosition.longitude,
        statusVeiculo,
        pedidoId: _currentOrderId,
      );

      if (success) {
        if (_lastSentStatus != statusVeiculo) {
          _lastSentStatus = statusVeiculo;

          if (onStatusChanged != null) {
            onStatusChanged!(_lastSentStatus);
          }
        }
      }

      _lastPosition = currentPosition;
    } catch (e) {
      print('Error sending location update: $e');
    }
  }
}
