import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class NetworkService extends ChangeNotifier {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  bool _hasError = false;
  bool get hasError => _hasError;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void initialize() {
    _checkInitialConnection();
    
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final hasConnection = results.any((result) => result != ConnectivityResult.none);
        _updateConnectionStatus(hasConnection);
      },
    );
  }

  Future<void> _checkInitialConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      final hasConnection = result.any((connectivityResult) => 
          connectivityResult != ConnectivityResult.none);
      _updateConnectionStatus(hasConnection);
    } catch (e) {
      _updateConnectionStatus(false);
    }
  }

  void _updateConnectionStatus(bool isConnected) {
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      
      if (!isConnected) {
        _hasError = true;
        _errorMessage = 'Отсутствует подключение к интернету';
      } else {
        _hasError = false;
        _errorMessage = null;
      }
      
      notifyListeners();
    }
  }

  void setSupabaseError(String error) {
    _hasError = true;
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }

  // ДОБАВЛЕНО: Метод для ручной проверки соединения
  Future<bool> checkConnectionManually() async {
    try {
      final result = await _connectivity.checkConnectivity();
      final hasConnection = result.any((connectivityResult) => 
          connectivityResult != ConnectivityResult.none);
      
      _updateConnectionStatus(hasConnection);
      return hasConnection;
    } catch (e) {
      _updateConnectionStatus(false);
      return false;
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}