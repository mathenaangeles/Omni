import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Assistant extends StatefulWidget {
  @override
  _AssistantState createState() => _AssistantState();
}

class _AssistantState extends State<Assistant> {
  final _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _sendMessage() async {
    final user = _auth.currentUser;
    if (user != null) {
      final message = _messageController.text.trim();
      if (message.isNotEmpty) {
        final userMessagesRef =
            _firestore.collection('users').doc(user.uid).collection('messages');

        // Add user message to Firestore
        final messageDoc = await userMessagesRef.add({
          'prompt': message,
          'sender': 'user',
          'timestamp': FieldValue.serverTimestamp(),
          'state': 'PENDING', // Assuming state starts as PENDING
        });

        _messageController.clear();

        // Listen for response updates
        messageDoc.snapshots().listen((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data();
            if (data != null && data['state'] == 'COMPLETED') {
              final response = data['response'] as String?;
              if (response != null) {
                userMessagesRef.add({
                  'text': response,
                  'sender': 'system',
                  'timestamp': FieldValue.serverTimestamp(),
                });
              }
            }
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Assistant'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: user != null
                  ? _firestore
                      .collection('users')
                      .doc(user.uid)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots()
                  : Stream.empty(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData) {
                  return Center(child: Text('No messages found.'));
                }
                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isUserMessage = message['sender'] == 'user';

                    return Align(
                      alignment: isUserMessage
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin:
                            EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isUserMessage
                              ? Colors.blueAccent
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          message['text'] ?? message['prompt'],
                          style: TextStyle(
                            color: isUserMessage ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
