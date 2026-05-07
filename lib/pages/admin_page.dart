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
                _showError("Points must be a positive integer");
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
            children: [
              TextField(
                controller: nameController,
                decoration:
                const InputDecoration(labelText: "Location Name"),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: latController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration:
                const InputDecoration(labelText: "Latitude"),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: lngController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration:
                const InputDecoration(labelText: "Longitude"),
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
              final name = nameController.text.trim();

              final lat =
              double.tryParse(latController.text.trim());

              final lng =
              double.tryParse(lngController.text.trim());

              if (name.isEmpty || name.length < 3) {
                _showError("Name too short");
                return;
              }

              if (lat == null || lng == null) {
                _showError("Invalid coordinates");
                return;
              }

              if (lat < -90 || lat > 90) {
                _showError("Latitude must be between -90 and 90");
                return;
              }

              if (lng < -180 || lng > 180) {
                _showError("Longitude must be between -180 and 180");
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
          IconButton(
            icon: const Icon(Icons.add_location),
            onPressed: _addLocation,
          ),
        ],
      ),

      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];

          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text(user['name'] ?? 'No Name'),

              subtitle: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text("Email: ${user['email']}"),
                  Text("Points: ${user['points']}"),
                  Text("Role: ${user['role']}"),
                ],
              ),

              trailing: const Icon(Icons.edit),

              onTap: () => _editPoints(user),
            ),
          );
        },
      ),
    );
  }
}