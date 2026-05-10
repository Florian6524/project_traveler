import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'profile_page.dart';
import 'shop_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'location_page.dart';
import '../services/notification_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class LocationPoint {
  final String id;
  final double lat;
  final double lng;
  final String name;
  final String description;
  final String qrCodeId;

  LocationPoint({
    required this.id,
    required this.lat,
    required this.lng,
    required this.name,
    required this.description,
    required this.qrCodeId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lat': lat,
      'long': lng,
      'name': name,
      'description': description,
      'qrCodeId': qrCodeId,
    };
  }
}

class OfferInfo {
  final String id;
  final String shopName;
  final String item;
  final String locationId;

  OfferInfo({
    required this.id,
    required this.shopName,
    required this.item,
    required this.locationId,
  });
}

class _HomePageState extends State<HomePage> {
  GoogleMapController? mapController;

  LatLng _currentPosition = const LatLng(44.4268, 26.1025);

  StreamSubscription<Position>? positionStream;

  List<LocationPoint> locations = [];
  List<OfferInfo> offers = [];
  bool isNearLocation = false;

  Map<String, dynamic>? nearbyLocation;

  static const double _kVisitRadius = 100;
  static const double _kOfferRadius = 150;
  static const int _kOfferCooldownMs = 6 * 60 * 60 * 1000;

  final Set<String> _locationsInsideNow = {};
  final Map<String, int> _lastNotifiedAt = {};

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _loadOffers();
    _initLocation();
  }

  Future<void> _loadLocations() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('locations').get();

    final loaded = snapshot.docs.map((doc) {
      final data = doc.data();
      return LocationPoint(
        id: doc.id,
        lat: data['lat'],
        lng: data['long'],
        name: data['name'],
        description: data['description'] ?? '',
        qrCodeId: data['qrCodeId'] ?? '',
      );
    }).toList();

    setState(() {
      locations = loaded;
    });
  }

  Future<void> _loadOffers() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('offers').get();

    final loaded = snapshot.docs.map((doc) {
      final data = doc.data();
      return OfferInfo(
        id: doc.id,
        shopName: data['shopName'] ?? '',
        item: data['item'] ?? '',
        locationId: data['locationId'] ?? '',
      );
    }).where((o) => o.locationId.isNotEmpty).toList();

    setState(() {
      offers = loaded;
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
    _checkOfferZones();
  }

  void _checkNearby() {
    bool near = false;
    Map<String, dynamic>? foundLocation;

    for (var loc in locations) {
      double distance = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        loc.lat,
        loc.lng,
      );

      if (distance < _kVisitRadius) {
        near = true;
        foundLocation = loc.toMap();
        break;
      }
    }

    setState(() {
      isNearLocation = near;
      nearbyLocation = foundLocation;
    });
  }

  void _checkOfferZones() {
    final now = DateTime.now().millisecondsSinceEpoch;

    for (var loc in locations) {
      final distance = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        loc.lat,
        loc.lng,
      );

      final wasInside = _locationsInsideNow.contains(loc.id);
      final isInside = distance < _kOfferRadius;

      if (isInside && !wasInside) {
        _locationsInsideNow.add(loc.id);

        final matchingOffers =
            offers.where((o) => o.locationId == loc.id).toList();

        if (matchingOffers.isEmpty) continue;

        final lastTime = _lastNotifiedAt[loc.id] ?? 0;
        if (now - lastTime < _kOfferCooldownMs) continue;

        _lastNotifiedAt[loc.id] = now;

        final preview = matchingOffers.length == 1
            ? '${matchingOffers.first.shopName}: ${matchingOffers.first.item}'
            : '${matchingOffers.length} offers available here';

        NotificationService.showOfferNotification(
          id: loc.id.hashCode & 0x7FFFFFFF,
          title: "Offers near ${loc.name} 🎁",
          body: preview,
        );
      } else if (!isInside && wasInside) {
        _locationsInsideNow.remove(loc.id);
      }
    }
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  Set<Marker> _buildMarkers() {
    return locations.map((loc) {
      final hasOffer = offers.any((o) => o.locationId == loc.id);
      return Marker(
        markerId: MarkerId(loc.id),
        position: LatLng(loc.lat, loc.lng),
        infoWindow: InfoWindow(
          title: loc.name,
          snippet: hasOffer ? "Offers available 🎁" : loc.description,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          hasOffer
              ? BitmapDescriptor.hueOrange
              : BitmapDescriptor.hueAzure,
        ),
      );
    }).toSet();
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
      ),
      body: Stack(
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
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            markers: _buildMarkers(),
          ),
          Positioned(
            right: 16,
            bottom: 24,
            child: FloatingActionButton(
              heroTag: 'recenter',
              onPressed: () {
                mapController?.animateCamera(
                  CameraUpdate.newLatLng(_currentPosition),
                );
              },
              child: const Icon(Icons.my_location),
            ),
          ),
          if (isNearLocation && nearbyLocation != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.place,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nearbyLocation!['name'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Text(
                              "You're here! Scan the QR to earn points.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        icon: const Icon(Icons.qr_code_scanner),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LocationPage(
                                locationData: nearbyLocation!,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
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
