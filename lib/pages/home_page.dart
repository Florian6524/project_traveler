import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'profile_page.dart';
import 'shop_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleMapController? mapController;

  LatLng _currentPosition = LatLng(44.4268, 26.1025);

  StreamSubscription<Position>? positionStream;

  Set<Marker> _markers = {};

  // 🔥 ICONS
  BitmapDescriptor? museumIcon;
  BitmapDescriptor? cafeIcon;
  BitmapDescriptor? parkIcon;

  @override
  void initState() {
    super.initState();
    _loadIcons();   // 👈 IMPORTANT
    _initLocation();
  }

  // 📍 LOAD ICONS FIRST
  Future<void> _loadIcons() async {
    museumIcon = await BitmapDescriptor.asset(
      ImageConfiguration(size: Size(64, 64)),
      'assets/icons/museum.png',
    );

    cafeIcon = await BitmapDescriptor.asset(
      ImageConfiguration(size: Size(64, 64)),
      'assets/icons/cafe.png',
    );

    parkIcon = await BitmapDescriptor.asset(
      ImageConfiguration(size: Size(64, 64)),
      'assets/icons/park.png',
    );

    // ✅ AFTER icons load → create markers
    _addMarkers();
  }

  // 📍 CREATE MARKERS (AFTER ICONS!)
  void _addMarkers() {
    final markers = {
      Marker(
        markerId: MarkerId("museum1"),
        position: LatLng(44.435, 26.102),
        icon: museumIcon ?? BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(title: "Museum"),
      ),
      Marker(
        markerId: MarkerId("cafe1"),
        position: LatLng(44.44491801613029, 26.055680157720083),
        icon: cafeIcon ?? BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(title: "Cafe"),
      ),
      Marker(
        markerId: MarkerId("park1"),
        position: LatLng(44.430, 26.105), // ✅ NEW LOCATION
        icon: parkIcon ?? BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(title: "Park"),
      ),
    };

    setState(() {
      _markers = markers;
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
      locationSettings: LocationSettings(
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
      body: SafeArea(
        child: Column(
          children: [
            // 🔝 TOP BAR
            Container(
              height: 70,
              width: double.infinity,
              alignment: Alignment.center,
              color: Colors.white,
              child: Text(
                "Traveler",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // 🗺️ MAP
            Expanded(
              child: Stack(
                children: [
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
                    markers: _markers,
                  ),

                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: FloatingActionButton(
                      onPressed: () {},
                      child: Icon(Icons.qr_code),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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