import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class LocationService {
  static Future<String?> getCurrentCoordinates() async {
    try {
      debugPrint('[LocationService] Step 1: Checking if location service is enabled...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] Service Disabled.');
        return null;
      }

      debugPrint('[LocationService] Step 2: Checking location permissions...');
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      debugPrint('[LocationService] Step 3: Getting current position...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      
      final coords = '${position.latitude},${position.longitude}';
      debugPrint('[LocationService] Location obtained: $coords');
      return coords;
      
    } catch (e) {
      debugPrint('[LocationService] ERROR encountered: $e');
    }
    return null;
  }
}
