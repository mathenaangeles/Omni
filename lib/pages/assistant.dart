import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:omni/widgets/custom_app_bar.dart';

class Assistant extends StatefulWidget {
  @override
  _AssistantState createState() => _AssistantState();
}

class _AssistantState extends State<Assistant> {
  final _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      setState(() {
        _messages.add({'text': message, 'sender': 'user'});
        _messageController.clear();
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final messagesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('messages');

      final docRef = await messagesRef.add({
        'prompt': message,
        'status': 'PENDING',
        'createdAt': FieldValue.serverTimestamp(),
      });

      while (true) {
        await Future.delayed(Duration(seconds: 2));
        final docSnapshot = await docRef.get();
        final status = docSnapshot.data()?['status'];

        if (status == 'COMPLETED') {
          final response = docSnapshot.data()?['response'];
          setState(() {
            _messages.add({
              'text': response ?? 'No response received.',
              'sender': 'system',
              'feedback': null
            });
          });
          break;
        }
      }
    }
  }

  void _handleFeedback(int index, String feedback) {
    setState(() {
      _messages[index]['feedback'] = feedback;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: false,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isUserMessage = message['sender'] == 'user';
                  final isSystemMessage = message['sender'] == 'system';
                  final feedback = message['feedback'];

                  return Align(
                    alignment: isUserMessage
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 10),
                      padding: const EdgeInsets.all(10),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.5,
                      ),
                      decoration: BoxDecoration(
                        color: isUserMessage
                            ? theme.colorScheme.secondary
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message['text'] ?? '',
                            style: TextStyle(
                              color:
                                  isUserMessage ? Colors.white : Colors.black,
                            ),
                          ),
                          if (isSystemMessage) ...[
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.thumb_up,
                                    color: feedback == 'up'
                                        ? theme.colorScheme.primary
                                        : Colors.grey,
                                  ),
                                  onPressed: () => _handleFeedback(index, 'up'),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.thumb_down,
                                    color: feedback == 'down'
                                        ? theme.colorScheme.error
                                        : Colors.grey,
                                  ),
                                  onPressed: () =>
                                      _handleFeedback(index, 'down'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
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
                        hintStyle: TextStyle(
                          color: Colors.black.withOpacity(0.8),
                          fontWeight: FontWeight.normal,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: theme.colorScheme.primary, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: theme.colorScheme.primary, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: theme.colorScheme.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: theme.colorScheme.primary),
                    onPressed: _sendMessage,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
