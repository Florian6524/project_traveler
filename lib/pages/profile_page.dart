import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'friends_page.dart';
import 'requests_page.dart';
import 'chats_list_page.dart';

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

              final currentUserDoc = await FirebaseFirestore.instance
                  .collection("users")
                  .doc(user!.uid)
                  .get();

              List friends =
                  (currentUserDoc.data()?['friends'] ?? []) as List;

              if (friends.contains(friendUid)) {
                _showMessage("You are already friends");
                return;
              }

              final existing = await FirebaseFirestore.instance
                  .collection('friend_requests')
                  .where('fromUid', isEqualTo: user!.uid)
                  .where('toUid', isEqualTo: friendUid)
                  .get();

              if (existing.docs.isNotEmpty) {
                _showMessage("Request already sent");
                return;
              }

              final reverse = await FirebaseFirestore.instance
                  .collection('friend_requests')
                  .where('fromUid', isEqualTo: friendUid)
                  .where('toUid', isEqualTo: user!.uid)
                  .get();

              if (reverse.docs.isNotEmpty) {
                _showMessage("This user already sent you a request");
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
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Change Username"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "New username"),
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
                _showMessage("Name must be at least 3 characters");
                return;
              }

              await FirebaseFirestore.instance
                  .collection("users")
                  .doc(user!.uid)
                  .update({'name': newName});

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

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("users")
            .doc(user!.uid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("No user data found"));
          }

          final data = snapshot.data!;
          final name = data['name'] ?? '?';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    name.toString().isNotEmpty
                        ? name.toString()[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 36,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => _changeName(name),
                    ),
                  ],
                ),
                Text(
                  data['email'] ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        "${data['points'] ?? 0} points",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _actionTile(
                  icon: Icons.person_add,
                  label: "Add Friend",
                  onTap: _showAddFriendDialog,
                ),
                _actionTile(
                  icon: Icons.mail_outline,
                  label: "Friend Requests",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RequestsPage(),
                      ),
                    );
                  },
                ),
                _actionTile(
                  icon: Icons.people_outline,
                  label: "Friends",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FriendsPage(),
                      ),
                    );
                  },
                ),
                _actionTile(
                  icon: Icons.chat_bubble_outline,
                  label: "Messages",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChatsListPage(),
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
