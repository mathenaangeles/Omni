import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:omni/widgets/custom_app_bar.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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
      });

      while (true) {
        await Future.delayed(Duration(seconds: 2));
        final docSnapshot = await docRef.get();
        final state = docSnapshot.data()?['status']['state'];

        if (state == 'COMPLETED') {
          final response = docSnapshot.data()?['response'];
          setState(() {
            _messages.add({
              'text': response ?? 'I\'m sorry. I can\'t answer that.',
              'sender': 'system',
              'feedback': null,
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
                          isSystemMessage
                              ? MarkdownBody(
                                  data: message['text'] ?? '',
                                  styleSheet: MarkdownStyleSheet(
                                    p: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : Text(
                                  message['text'] ?? '',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
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
