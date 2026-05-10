import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'chat_page.dart';

class FriendsPage extends StatelessWidget {
  const FriendsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(title: const Text("Friends")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('friends')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          final myFriends = docs.where((doc) {
            final users = List<String>.from(doc['users']);
            return users.contains(user.uid);
          }).toList();

          if (myFriends.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "No friends yet.\nAdd one from your profile.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: myFriends.length,
            itemBuilder: (context, index) {
              final friendDoc = myFriends[index];
              final users = List<String>.from(friendDoc['users']);
              final friendUid =
                  users.firstWhere((uid) => uid != user.uid);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(friendUid)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const SizedBox();
                  }

                  final friend = userSnapshot.data!;
                  final name = friend['name'] ?? '?';

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primary,
                        child: Text(
                          name.toString().isNotEmpty
                              ? name.toString()[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(friend['email']),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.chat_bubble_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatPage(
                                friendUid: friendUid,
                                friendName: name,
                              ),
                            ),
                          );
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              friendUid: friendUid,
                              friendName: name,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
