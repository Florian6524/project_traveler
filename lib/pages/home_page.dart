import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'profile_page.dart';
import 'shop_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class LocationPoint {
  final double lat;
  final double lng;
  final String name;

  LocationPoint({required this.lat, required this.lng, required this.name});
}

class _HomePageState extends State<HomePage> {
  GoogleMapController? mapController;

  LatLng _currentPosition = const LatLng(44.4268, 26.1025);

  StreamSubscription<Position>? positionStream;

  List<LocationPoint> locations = [];
  bool isNearLocation = false;

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _initLocation();
  }

  Future<void> _loadLocations() async {
    final snapshot =
    await FirebaseFirestore.instance.collection('locations').get();

    final loaded = snapshot.docs.map((doc) {
      final data = doc.data();

      return LocationPoint(
        lat: data['lat'],
        lng: data['long'],
        name: data['name'],
      );
    }).toList();

    setState(() {
      locations = loaded;
    });
  }

  Future<void> _initLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    Position position = await Geolocator.getCurrentPosition();
    _updatePosition(position);

    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
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

    mapController?.animateCamera(CameraUpdate.newLatLng(newPos));

    _checkNearby();
  }

  void _checkNearby() {
    bool near = false;

    for (var loc in locations) {
      double distance = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        loc.lat,
        loc.lng,
      );

      if (distance < 50) {
        near = true;
        break;
      }
    }

    setState(() {
      isNearLocation = near;
    });
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Traveler"),
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
            );
          },
        ),

        actions: [
          if (isNearLocation)
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Scan QR here (future feature)")),
                );
              },
            ),
        ],
      ),

      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentPosition,
          zoom: 16,
        ),
        onMapCreated: (controller) {
          mapController = controller;
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        compassEnabled: false,
        mapToolbarEnabled: false,
      ),

      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: "Shop",
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShopPage()),
            );
          }
        },
      ),
    );
  }
}