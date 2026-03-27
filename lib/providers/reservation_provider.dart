import 'package:flutter/material.dart';
import '../models/reservation.dart';
import '../services/api_service.dart';

class ReservationProvider with ChangeNotifier {
  List<Reservation> _reservations = [];
  bool _isLoading = false;

  List<Reservation> get reservations => [..._reservations];
  bool get isLoading => _isLoading;

  Future<void> fetchReservations({String? status, String? type}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await ApiService.getReservations(status: status, type: type);
      _reservations = data;
    } catch (e) {
      debugPrint('Error fetching reservations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createReservation(Reservation reservation) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await ApiService.createReservation({
        'user_id': reservation.userId,
        'cafe_id': reservation.cafeId,
        'date_time': reservation.dateTime.toIso8601String(),
        'number_of_people': reservation.numberOfPeople,
        'type': reservation.type,
        'special_requests': reservation.specialRequests,
      });
      if (success) {
        _reservations.insert(0, reservation);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error creating reservation: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addReservation(Reservation reservation) {
    _reservations.insert(0, reservation);
    notifyListeners();
  }
}
