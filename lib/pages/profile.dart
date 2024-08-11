import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:omni/widgets/custom_app_bar.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  String? _firstName;
  String? _lastName;
  String? _email;
  String? _address;
  String? _school;
  String? _profilePictureUrl;

  List<String> _modules = [];

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          _firstName = data['firstName'] ?? '';
          _lastName = data['lastName'] ?? '';
          _email = user.email;
          _address = data['address'] ?? '';
          _school = data['school'] ?? '';
          _profilePictureUrl = data['profilePicture'] ?? '';
        });

        final modulesSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('modules')
            .get();
        _modules = modulesSnapshot.docs
            .map((doc) => doc.data()['name'] as String)
            .toList();
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    await _firestore.collection('users').doc(user.uid).set({
      'firstName': _firstName,
      'lastName': _lastName,
      'address': _address,
      'school': _school,
      'profilePicture': _profilePictureUrl,
    }, SetOptions(merge: true));

    setState(() {
      _isEditing = false;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: _profilePictureUrl != null
                                ? CircleAvatar(
                                    backgroundImage:
                                        NetworkImage(_profilePictureUrl!),
                                    radius: 60,
                                  )
                                : CircleAvatar(
                                    backgroundColor:
                                        theme.colorScheme.secondary,
                                    radius: 60,
                                    child: Icon(Icons.person,
                                        size: 60,
                                        color: theme.colorScheme.onSecondary),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_isEditing) ...[
                                  TextFormField(
                                    initialValue: _firstName,
                                    decoration: const InputDecoration(
                                      labelText: 'First Name',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (value) => _firstName = value,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    initialValue: _lastName,
                                    decoration: const InputDecoration(
                                      labelText: 'Last Name',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (value) => _lastName = value,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    initialValue: _email,
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      border: OutlineInputBorder(),
                                    ),
                                    enabled: false,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    initialValue: _address,
                                    decoration: const InputDecoration(
                                      labelText: 'Address',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (value) => _address = value,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    initialValue: _school,
                                    decoration: const InputDecoration(
                                      labelText: 'School',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (value) => _school = value,
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      ElevatedButton(
                                        onPressed: _saveUserData,
                                        child: const Text('Save'),
                                      ),
                                      const SizedBox(width: 16),
                                      OutlinedButton(
                                        onPressed: () {
                                          setState(() {
                                            _isEditing = false;
                                          });
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                    ],
                                  )
                                ] else ...[
                                  Text('First Name: $_firstName',
                                      style: const TextStyle(fontSize: 16)),
                                  const SizedBox(height: 8),
                                  Text('Last Name: $_lastName',
                                      style: const TextStyle(fontSize: 16)),
                                  const SizedBox(height: 8),
                                  Text('Email: $_email',
                                      style: const TextStyle(fontSize: 16)),
                                  const SizedBox(height: 8),
                                  Text('Address: $_address',
                                      style: const TextStyle(fontSize: 16)),
                                  const SizedBox(height: 8),
                                  Text('School: $_school',
                                      style: const TextStyle(fontSize: 16)),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _isEditing = true;
                                      });
                                    },
                                    child: const Text('Edit Profile'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Modules',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      _modules.isEmpty
                          ? const Text('No modules available.')
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _modules.map((module) {
                                return Text(module,
                                    style: const TextStyle(fontSize: 16));
                              }).toList(),
                            ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
