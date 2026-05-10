import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'chat_page.dart';

class ChatsListPage extends StatelessWidget {
  const ChatsListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(title: const Text("Messages")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('users', arrayContains: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!.docs.where((d) {
            return (d.data() as Map<String, dynamic>)
                .containsKey('lastMessage');
          }).toList();

          chats.sort((a, b) {
            final ta = (a['lastTimestamp'] as Timestamp?)?.toDate();
            final tb = (b['lastTimestamp'] as Timestamp?)?.toDate();
            if (ta == null && tb == null) return 0;
            if (ta == null) return 1;
            if (tb == null) return -1;
            return tb.compareTo(ta);
          });

          if (chats.isEmpty) {
            return const Center(
              child: Text(
                "No conversations yet.\nStart one from your friends list.",
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final users = List<String>.from(chat['users']);
              final friendUid =
                  users.firstWhere((u) => u != user.uid);
              final unread = ((chat.data() as Map<String, dynamic>)
                      ['unreadCount'] as Map<String, dynamic>?)
                      ?[user.uid] ??
                  0;
              final lastMessage = chat['lastMessage'] ?? '';

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(friendUid)
                    .get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const SizedBox();
                  final friend = userSnap.data!;
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
                        style:
                            const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: (unread as int) > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$unread',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                          : null,
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
