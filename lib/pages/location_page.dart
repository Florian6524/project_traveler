import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationPage extends StatefulWidget {
  final Map<String, dynamic> locationData;

  const LocationPage({
    Key? key,
    required this.locationData,
  }) : super(key: key);

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  bool scanned = false;

  Future<void> _handleQrScan(String qrValue) async {
    if (scanned) return;

    scanned = true;

    final user = FirebaseAuth.instance.currentUser!;

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    final userDoc = await userRef.get();

    Map<String, dynamic> scannedCodes =
    Map<String, dynamic>.from(
      userDoc.data()?['scannedCodes'] ?? {},
    );

    final correctQr =
    widget.locationData['qrCodeId'];

    if (qrValue != correctQr) {
      _showMessage("Wrong QR code for this location");
      scanned = false;
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    const cooldown =
        24 * 60 * 60 * 1000;

    if (scannedCodes.containsKey(qrValue)) {
      final lastScan = scannedCodes[qrValue];

      if (now - lastScan < cooldown) {
        final remaining =
            cooldown - (now - lastScan);

        final hours =
        (remaining / (1000 * 60 * 60))
            .ceil();

        _showMessage(
          "You already scanned this QR.\nTry again in $hours h.",
        );

        scanned = false;

        return;
      }
    }

    int currentPoints =
        userDoc.data()?['points'] ?? 0;

    await userRef.update({
      'points': currentPoints + 10,
      'scannedCodes.$qrValue': now,
    });

    _showMessage("+10 points earned!");

    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _openScanner() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SizedBox(
          height: 500,
          child: MobileScanner(
            onDetect: (capture) {
              final barcode =
                  capture.barcodes.first;

              final value = barcode.rawValue;

              if (value != null) {
                Navigator.pop(context);

                _handleQrScan(value);
              }
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final name =
        widget.locationData['name'] ?? 'Location';

    final description =
    widget.locationData['description'];

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              description == null ||
                  description.toString().isEmpty
                  ? "No description available"
                  : description,
              style: const TextStyle(
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _openScanner,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text(
                  "Scan QR Code",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}