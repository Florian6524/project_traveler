import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'friends_page.dart';
import 'requests_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;

  void _showAddFriendDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Friend"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Friend Email",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = controller.text.trim();

              if (email.isEmpty) {
                _showMessage("Enter an email");
                return;
              }

              final query = await FirebaseFirestore.instance
                  .collection('users')
                  .where('email', isEqualTo: email)
                  .get();

              if (query.docs.isEmpty) {
                _showMessage("User does not exist");
                return;
              }

              final friendDoc = query.docs.first;
              final friendData = friendDoc.data();
              final friendUid = friendDoc.id;

              if (friendData['role'] == 'admin') {
                _showMessage("Cannot add admins");
                return;
              }

              if (friendUid == user!.uid) {
                _showMessage("You cannot add yourself");
                return;
              }

              final currentUserDoc =
              await FirebaseFirestore.instance
                  .collection("users")
                  .doc(user!.uid)
                  .get();

              List friends =
              (currentUserDoc.data()?['friends'] ?? [])
              as List;

              if (friends.contains(friendUid)) {
                _showMessage("You are already friends");
                return;
              }

              final existing = await FirebaseFirestore
                  .instance
                  .collection('friend_requests')
                  .where('fromUid', isEqualTo: user!.uid)
                  .where('toUid', isEqualTo: friendUid)
                  .get();

              if (existing.docs.isNotEmpty) {
                _showMessage("Request already sent");
                return;
              }

              final reverse = await FirebaseFirestore
                  .instance
                  .collection('friend_requests')
                  .where('fromUid', isEqualTo: friendUid)
                  .where('toUid', isEqualTo: user!.uid)
                  .get();

              if (reverse.docs.isNotEmpty) {
                _showMessage(
                  "This user already sent you a request",
                );
                return;
              }

              await FirebaseFirestore.instance
                  .collection('friend_requests')
                  .add({
                'fromUid': user!.uid,
                'fromName': user!.email,
                'toUid': friendUid,
                'status': 'pending',
              });

              Navigator.pop(context);

              _showMessage("Friend request sent");
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

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
                _showMessage(
                    "Name must be at least 3 characters");
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

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
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
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text("No user data found"),
            );
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
                        style: const TextStyle(
                          fontSize: 20,
                        ),
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

                ElevatedButton.icon(
                  onPressed: _showAddFriendDialog,
                  icon: const Icon(Icons.person_add),
                  label: const Text("Add Friend"),
                ),

                const SizedBox(height: 10),

                ElevatedButton.icon(
                  icon: const Icon(Icons.mail),
                  label: const Text("Requests"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const RequestsPage(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),

                ElevatedButton.icon(
                  icon: const Icon(Icons.people),
                  label: const Text("Friends"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const FriendsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}