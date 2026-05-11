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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadOffers(), _loadUserPoints()]);
    if (mounted) setState(() => _loading = false);
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
      Iterable.generate(
          8, (_) => chars.codeUnitAt(rand.nextInt(chars.length))),
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.celebration,
                size: 56,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 12),
              const Text(
                "Your Reward Code",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 16, horizontal: 28),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    fontSize: 28,
                    letterSpacing: 4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Valid for 10 minutes",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Done"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Shop"),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      "$userPoints",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : offers.isEmpty
              ? const Center(child: Text("No offers available"))
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: offers.map((offer) {
                    final canBuy = userPoints >= offer.points;

                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: canBuy ? () => _buyOffer(offer) : null,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: canBuy
                                        ? [
                                            theme.colorScheme.primary,
                                            theme.colorScheme.secondary,
                                          ]
                                        : [
                                            Colors.grey.shade400,
                                            Colors.grey.shade300,
                                          ],
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  canBuy
                                      ? Icons.local_offer
                                      : Icons.lock_outline,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      offer.shopName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      offer.item,
                                      style: const TextStyle(
                                          color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Text(
                                    "${offer.points}",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: canBuy
                                          ? theme.colorScheme.primary
                                          : Colors.grey,
                                    ),
                                  ),
                                  const Text(
                                    "pts",
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}
