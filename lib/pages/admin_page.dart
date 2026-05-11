import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final snapshot =
    await FirebaseFirestore.instance.collection('users').get();

    final loaded = snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data(),
      };
    }).toList();

    setState(() {
      users = loaded;
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  void _editPoints(Map<String, dynamic> user) {
    final controller =
    TextEditingController(text: user['points'].toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Edit points for ${user['name']}"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "New points",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPoints =
              int.tryParse(controller.text.trim());

              if (newPoints == null || newPoints < 0) {
                _showError(
                  "Points must be a positive integer",
                );
                return;
              }

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user['id'])
                  .update({
                'points': newPoints,
              });

              Navigator.pop(context);

              _loadUsers();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(String userId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .delete();

    _loadUsers();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("User deleted"),
      ),
    );
  }


  void _addLocation() {
    final nameController = TextEditingController();
    final latController = TextEditingController();
    final lngController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Location"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Location Name",
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: latController,
                keyboardType:
                const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Latitude",
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: lngController,
                keyboardType:
                const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Longitude",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name =
              nameController.text.trim();

              final lat = double.tryParse(
                latController.text.trim(),
              );

              final lng = double.tryParse(
                lngController.text.trim(),
              );

              if (name.isEmpty || name.length < 3) {
                _showError("Name too short");
                return;
              }

              if (lat == null || lng == null) {
                _showError("Invalid coordinates");
                return;
              }

              if (lat < -90 || lat > 90) {
                _showError(
                  "Latitude must be between -90 and 90",
                );
                return;
              }

              if (lng < -180 || lng > 180) {
                _showError(
                  "Longitude must be between -180 and 180",
                );
                return;
              }

              await FirebaseFirestore.instance
                  .collection('locations')
                  .add({
                'name': name,
                'lat': lat,
                'long': lng,
              });

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Location added"),
                ),
              );
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLocation(
      String locationId) async {
    await FirebaseFirestore.instance
        .collection('locations')
        .doc(locationId)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Location deleted"),
      ),
    );
  }

  void _manageLocations() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('locations')
        .get();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Manage Locations"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: snapshot.docs.map((doc) {
              final data = doc.data();

              return ListTile(
                title: Text(
                  data['name'] ?? '?',
                ),
                subtitle: Text(
                  "${data['lat']} , ${data['long']}",
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  onPressed: () async {
                    await _deleteLocation(doc.id);

                    Navigator.pop(context);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }


  Future<void> _addOffer() async {
    final shopController = TextEditingController();
    final itemController = TextEditingController();
    final pointsController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Offer"),

        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: shopController,
                decoration: const InputDecoration(
                  labelText: "Shop name",
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: itemController,
                decoration: const InputDecoration(
                  labelText: "Product / offer",
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: pointsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Cost in points",
                ),
              ),
            ],
          ),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            onPressed: () async {
              final shop =
              shopController.text.trim();

              final item =
              itemController.text.trim();

              final pts = int.tryParse(
                pointsController.text.trim(),
              );

              if (shop.isEmpty || shop.length < 2) {
                _showError("Invalid shop name");
                return;
              }

              if (item.isEmpty || item.length < 2) {
                _showError("Invalid product name");
                return;
              }

              if (pts == null || pts <= 0) {
                _showError(
                  "Points must be a positive integer",
                );
                return;
              }

              await FirebaseFirestore.instance
                  .collection('offers')
                  .add({
                'shopName': shop,
                'item': item,
                'points': pts,
              });

              Navigator.pop(context);

              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content: Text("Offer added"),
                ),
              );
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteOffer(
      String offerId) async {
    await FirebaseFirestore.instance
        .collection('offers')
        .doc(offerId)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Offer deleted"),
      ),
    );
  }

  void _manageOffers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('offers')
        .get();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Manage Offers"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: snapshot.docs.map((doc) {
              final data = doc.data();

              return ListTile(
                title: Text(
                  "${data['shopName']} - ${data['item']}",
                ),
                subtitle: Text(
                  "${data['points']} points",
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  onPressed: () async {
                    await _deleteOffer(doc.id);

                    Navigator.pop(context);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"),

        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _logout,
        ),

        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),

            onSelected: (v) {
              if (v == 'location') {
                _addLocation();
              }

              if (v == 'offer') {
                _addOffer();
              }

              if (v == 'manage_locations') {
                _manageLocations();
              }

              if (v == 'manage_offers') {
                _manageOffers();
              }
            },

            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'location',
                child: Row(
                  children: [
                    Icon(
                      Icons.add_location,
                      color: Colors.black54,
                    ),
                    SizedBox(width: 8),
                    Text("Add Location"),
                  ],
                ),
              ),

              PopupMenuItem(
                value: 'offer',
                child: Row(
                  children: [
                    Icon(
                      Icons.local_offer,
                      color: Colors.black54,
                    ),
                    SizedBox(width: 8),
                    Text("Add Offer"),
                  ],
                ),
              ),

              PopupMenuItem(
                value: 'manage_locations',
                child: Row(
                  children: [
                    Icon(
                      Icons.map,
                      color: Colors.black54,
                    ),
                    SizedBox(width: 8),
                    Text("Manage Locations"),
                  ],
                ),
              ),

              PopupMenuItem(
                value: 'manage_offers',
                child: Row(
                  children: [
                    Icon(
                      Icons.store,
                      color: Colors.black54,
                    ),
                    SizedBox(width: 8),
                    Text("Manage Offers"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _loadUsers,

        child: ListView.builder(
          padding:
          const EdgeInsets.symmetric(
            vertical: 8,
          ),

          itemCount: users.length,

          itemBuilder: (context, index) {
            final user = users[index];

            final name =
                user['name'] ?? 'No Name';

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                  Theme.of(context)
                      .colorScheme
                      .primary,
                  child: Text(
                    name.toString().isNotEmpty
                        ? name
                        .toString()[0]
                        .toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),

                title: Text(
                  name,
                  style: const TextStyle(
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),

                subtitle: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      "Email: ${user['email']}",
                    ),
                    Text(
                      "Points: ${user['points']}",
                    ),
                    Text(
                      "Role: ${user['role']}",
                    ),
                  ],
                ),

                trailing: Row(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    IconButton(
                      icon:
                      const Icon(Icons.edit),
                      onPressed: () =>
                          _editPoints(user),
                    ),

                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      onPressed: () async {
                        await _deleteUser(
                          user['id'],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}