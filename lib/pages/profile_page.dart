import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;

  void _changeName(String currentName) {
    final controller =
    TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Change Username"),
        content: TextField(
          controller: controller,
          decoration:
          const InputDecoration(labelText: "New username"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();

              if (newName.length < 3) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                    Text("Name must be at least 3 characters"),
                  ),
                );
                return;
              }

              await FirebaseFirestore.instance
                  .collection("users")
                  .doc(user!.uid)
                  .update({
                'name': newName,
              });

              Navigator.pop(context);

              setState(() {});
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),

      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("users")
            .doc(user!.uid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator());
          }

          if (!snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
                child: Text("No user data found"));
          }

          final data = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Username: ${data['name']}",
                        style:
                        const TextStyle(fontSize: 20),
                      ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          _changeName(data['name']),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Text(
                  "Email: ${data['email']}",
                  style: const TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 20),

                Text(
                  "Points: ${data['points']}",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Explore places and scan QR codes to earn points!",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}