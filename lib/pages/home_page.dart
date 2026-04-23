import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleMapController? mapController;

  LatLng _currentPosition = LatLng(44.4268, 26.1025); // default: Bucharest

  StreamSubscription<Position>? positionStream;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    // Check permission
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // Get initial position
    Position position = await Geolocator.getCurrentPosition();

    _updatePosition(position);

    // Listen to live updates
    positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // update every 5 meters
      ),
    ).listen((Position position) {
      _updatePosition(position);
    });
  }

  void _updatePosition(Position position) {
    LatLng newPos = LatLng(position.latitude, position.longitude);

    setState(() {
      _currentPosition = newPos;
    });

    // Move camera smoothly
    mapController?.animateCamera(
      CameraUpdate.newLatLng(newPos),
    );
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🗺️ FULLSCREEN MAP
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 16,
            ),
            onMapCreated: (controller) {
              mapController = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),

          // 🔘 FUTURE UI LAYER (buttons, etc.)
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                print("Future action button");
              },
              child: Icon(Icons.qr_code),
            ),
          ),
        ],
      ),
    );
  }
}