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
              final input = controller.text.trim();

              final newPoints = int.tryParse(input);

              if (newPoints == null) {
                _showError("Enter a valid integer");
                return;
              }

              if (newPoints < 0) {
                _showError("Points cannot be negative");
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Email: ${user['email']}"),
                  Text("Points: ${user['points']}"),
                  Text("Role: ${user['role']}"),
                ],
              ),

              onTap: () => _editPoints(user),

              trailing: const Icon(Icons.edit),
            ),
          );
        },
      ),
    );
  }
}