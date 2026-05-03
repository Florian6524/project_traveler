import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({Key? key}) : super(key: key);

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class Offer {
  final String shopName;
  final String item;
  final int points;

  Offer({
    required this.shopName,
    required this.item,
    required this.points,
  });
}

class _ShopPageState extends State<ShopPage> {
  List<Offer> offers = [];
  int userPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadOffers();
    _loadUserPoints();
  }

  Future<void> _loadOffers() async {
    final snapshot =
    await FirebaseFirestore.instance.collection('offers').get();

    final loaded = snapshot.docs.map((doc) {
      final data = doc.data();

      return Offer(
        shopName: data['shopName'],
        item: data['item'],
        points: data['points'],
      );
    }).toList();

    setState(() {
      offers = loaded;
    });
  }

  Future<void> _loadUserPoints() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    setState(() {
      userPoints = doc.data()?['points'] ?? 0;
    });
  }

  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();

    return String.fromCharCodes(
      Iterable.generate(8, (_) => chars.codeUnitAt(rand.nextInt(chars.length))),
    );
  }

  Future<void> _buyOffer(Offer offer) async {
    if (userPoints < offer.points) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'points': userPoints - offer.points,
    });

    final code = _generateCode();

    setState(() {
      userPoints -= offer.points;
    });

    _showCodePopup(code);
  }

  void _showCodePopup(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          height: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const Text(
                "Your Reward Code 🎉",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 25,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    fontSize: 28,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const Text(
                "Valid for 10 minutes",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Done"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Shop"),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: Text(
                "Points: $userPoints",
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),

      body: ListView(
        children: offers.map((offer) {
          final canBuy = userPoints >= offer.points;

          return Card(
            margin: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            color: canBuy ? Colors.white : Colors.grey[300],
            child: ListTile(
              title: Text(
                offer.shopName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(offer.item),
              trailing: Text("${offer.points} pts"),
              onTap: canBuy ? () => _buyOffer(offer) : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}