import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendsPage extends StatelessWidget {
  const FriendsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Friends"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('friends')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data!.docs;

          final myFriends = docs.where((doc) {
            final users = List<String>.from(doc['users']);
            return users.contains(user.uid);
          }).toList();

          if (myFriends.isEmpty) {
            return const Center(
              child: Text("No friends yet"),
            );
          }

          return ListView.builder(
            itemCount: myFriends.length,
            itemBuilder: (context, index) {
              final friendDoc = myFriends[index];

              final users =
              List<String>.from(friendDoc['users']);

              final friendUid = users.firstWhere(
                    (uid) => uid != user.uid,
              );

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(friendUid)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const SizedBox();
                  }

                  final friend =
                  userSnapshot.data!;

                  return Card(
                    child: ListTile(
                      leading:
                      const Icon(Icons.person),

                      title: Text(friend['name']),

                      subtitle:
                      Text(friend['email']),
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