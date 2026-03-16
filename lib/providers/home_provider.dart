import 'package:flutter/material.dart';
import '../models/cafe.dart';
import '../services/api_service.dart';

class HomeProvider with ChangeNotifier {
  List<Map<String, dynamic>> _sliders = [];
  List<Cafe> _cafes = [];
  bool _isLoadingSliders = false;
  bool _isLoadingCafes = false;
  String? _sliderError;
  String? _cafeError;

  List<Map<String, dynamic>> get sliders => _sliders;
  List<Cafe> get cafes => _cafes;
  bool get isLoadingSliders => _isLoadingSliders;
  bool get isLoadingCafes => _isLoadingCafes;
  String? get sliderError => _sliderError;
  String? get cafeError => _cafeError;

  Future<void> loadHomeData({bool forced = false}) async {
    if (_sliders.isEmpty || forced) {
      await loadSliders();
    }
    if (_cafes.isEmpty || forced) {
      await loadCafes();
    }
  }

  Future<void> loadSliders() async {
    _isLoadingSliders = true;
    _sliderError = null;
    notifyListeners();

    try {
      _sliders = await ApiService.getSliders();
    } catch (e) {
      _sliderError = e.toString();
    } finally {
      _isLoadingSliders = false;
      notifyListeners();
    }
  }

  Future<void> loadCafes() async {
    _isLoadingCafes = true;
    _cafeError = null;
    notifyListeners();

    try {
      _cafes = await ApiService.getCafes();
    } catch (e) {
      _cafeError = e.toString();
    } finally {
      _isLoadingCafes = false;
      notifyListeners();
    }
  }
}
