import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../services/api_service.dart';

class FavoriteProvider with ChangeNotifier {
  List<MenuItem> _favorites = [];
  bool _isLoading = false;

  List<MenuItem> get favorites => _favorites;
  bool get isLoading => _isLoading;

  FavoriteProvider() {
    // Initial load happens if we have a token, but usually it's better to call it explicitly on login
    loadFavoritesFromApi();
  }

  Future<void> loadFavoritesFromApi() async {
    _isLoading = true;
    notifyListeners();

    try {
      _favorites = await ApiService.getFavorites();
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearFavorites() {
    _favorites = [];
    notifyListeners();
  }

  bool isFavorite(String id) {
    return _favorites.any((item) => item.id == id);
  }

  Future<void> toggleFavorite(MenuItem item) async {
    // Optimistic UI update
    final index = _favorites.indexWhere((element) => element.id == item.id);
    final bool wasFavorite = index >= 0;

    if (wasFavorite) {
      _favorites.removeAt(index);
    } else {
      _favorites.add(item);
    }
    notifyListeners();

    try {
      final success = await ApiService.toggleFavorite(item.id);
      if (!success) {
        // Rollback on failure
        if (wasFavorite) {
          _favorites.add(item);
        } else {
          _favorites.removeWhere((element) => element.id == item.id);
        }
        notifyListeners();
      }
    } catch (e) {
      // Rollback on error
      if (wasFavorite) {
        _favorites.add(item);
      } else {
        _favorites.removeWhere((element) => element.id == item.id);
      }
      notifyListeners();
      debugPrint('Error toggling favorite: $e');
    }
  }
}
