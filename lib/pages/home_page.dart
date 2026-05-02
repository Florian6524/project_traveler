import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'profile_page.dart';
import 'shop_page.dart';
import 'package:firebase_auth/firebase_auth.dart';


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class Place {
  final String name;
  final LatLng position;

  Place(this.name, this.position);
}

class _HomePageState extends State<HomePage> {
  GoogleMapController? mapController;

  LatLng _currentPosition = const LatLng(44.4268, 26.1025);

  StreamSubscription<Position>? positionStream;

  final List<Place> places = [
    Place("Museum", const LatLng(44.435, 26.102)),
    Place("Cafe", const LatLng(44.427, 26.100)),
    Place("Park", const LatLng(44.430, 26.105)),
    Place("test", const LatLng(44.44462351124719, 26.05668737490598)),
    Place("Maria si Ion", const LatLng(44.44498453879395, 26.055664206259504))
  ];

  Place? nearbyPlace;

  @override
  void initState() {
    super.initState();
    _initLocation();
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

    _checkNearbyPlace(position);

    mapController?.animateCamera(
      CameraUpdate.newLatLng(newPos),
    );
  }

  void _checkNearbyPlace(Position position) {
    const double maxDistance = 50; // increase maybe, for testing and stuff

    for (var place in places) {
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        place.position.latitude,
        place.position.longitude,
      );

      if (distance <= maxDistance) {
        setState(() {
          nearbyPlace = place;
        });
        return;
      }
    }

    setState(() {
      nearbyPlace = null;
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
          },
        ),

        actions: [
          if (nearbyPlace != null)
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: () {
                print("Scan at ${nearbyPlace!.name}");
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
              MaterialPageRoute(builder: (_) => ProfilePage()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ShopPage()),
            );
          }
        },
      ),
    );
  }
}