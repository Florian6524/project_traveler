import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatPage extends StatefulWidget {
  final String friendUid;
  final String friendName;

  const ChatPage({
    Key? key,
    required this.friendUid,
    required this.friendName,
  }) : super(key: key);

  static String chatIdFor(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late final String _myUid;
  late final String _chatId;

  @override
  void initState() {
    super.initState();
    _myUid = FirebaseAuth.instance.currentUser!.uid;
    _chatId = ChatPage.chatIdFor(_myUid, widget.friendUid);
    _resetUnread();
  }

  Future<void> _resetUnread() async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .set({
      'users': [_myUid, widget.friendUid],
      'unreadCount': {_myUid: 0},
    }, SetOptions(merge: true));
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    final chatRef =
        FirebaseFirestore.instance.collection('chats').doc(_chatId);

    final snap = await chatRef.get();
    final currentUnread = ((snap.data()?['unreadCount']
            as Map<String, dynamic>?) ??
        {})[widget.friendUid] ??
        0;

    await chatRef.set({
      'users': [_myUid, widget.friendUid],
      'lastMessage': text,
      'lastSender': _myUid,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'unreadCount': {
        _myUid: 0,
        widget.friendUid: (currentUnread as int) + 1,
      },
    }, SetOptions(merge: true));

    await chatRef.collection('messages').add({
      'senderUid': _myUid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.friendName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return const Center(
                    child: Text("Say hi 👋"),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMine = msg['senderUid'] == _myUid;

                    return Align(
                      alignment: isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth:
                              MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMine
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMine ? 16 : 4),
                            bottomRight: Radius.circular(isMine ? 4 : 16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          msg['text'] ?? '',
                          style: TextStyle(
                            color: isMine ? Colors.white : Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.send),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
