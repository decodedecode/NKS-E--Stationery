import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<void> _checkAndRequestPermission(BuildContext context) async {
    LocationPermission permission = await Geolocator.checkPermission();
    print('object');

    if (permission == LocationPermission.denied) {
      // Request permission
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showPermissionDeniedMessage(context);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSettingsDialog(context);
      return;
    }
  }

  Future<Position> getCurrentLocation(BuildContext context) async {
    await _checkAndRequestPermission(context); // Ensure permissions
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  void _showPermissionDeniedMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Location permission denied. Please enable it to use this feature.'),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Location Permission Required'),
        content: Text(
          'Please enable location permissions in settings to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Geolocator.openAppSettings(); // Opens app settings
              Navigator.pop(ctx);
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
