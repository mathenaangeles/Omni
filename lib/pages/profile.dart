import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:omni/widgets/custom_app_bar.dart';
import 'package:omni/widgets/student_detail.dart';

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
  String? _about;

  bool _isEditing = false;
  bool _isLoading = false;
  bool _isTeacher = false;

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
          _profilePictureUrl = data['profilePictureUrl'] ?? '';
          _about = data['about'] ?? '';
          _isTeacher = data['userType'] == 'Teacher';
        });
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
      'about': _about,
      'profilePicture': _profilePictureUrl,
    }, SetOptions(merge: true));

    setState(() {
      _isEditing = false;
      _isLoading = false;
    });
  }

  void _showAddStudentModal() {
    final TextEditingController _studentIdController = TextEditingController();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _studentIdController,
                decoration: InputDecoration(
                  labelText: 'Enter Student ID',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.secondary),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.secondary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.secondary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 16.0),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  String studentId = _studentIdController.text.trim();

                  if (studentId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Student ID cannot be empty.')),
                    );
                    return;
                  }

                  final user = _auth.currentUser;
                  DocumentReference userRef =
                      _firestore.collection('users').doc(user?.uid);

                  await _firestore.runTransaction((transaction) async {
                    DocumentSnapshot userDoc = await transaction.get(userRef);

                    List<dynamic> studentIds = userDoc['studentIds'] ?? [];

                    if (!studentIds.contains(studentId)) {
                      studentIds.add(studentId);
                      transaction.update(userRef, {'studentIds': studentIds});
                    }
                  });
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add Student',
                    style: TextStyle(fontWeight: FontWeight.w400)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
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
                                  child: _profilePictureUrl != null &&
                                          _profilePictureUrl!.isNotEmpty
                                      ? CircleAvatar(
                                          backgroundImage:
                                              NetworkImage(_profilePictureUrl!),
                                          radius: 60,
                                        )
                                      : const CircleAvatar(
                                          backgroundImage:
                                              AssetImage('assets/user.png'),
                                        ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (_isEditing) ...[
                                        TextFormField(
                                          initialValue: _firstName,
                                          decoration: InputDecoration(
                                            labelText: 'First Name',
                                            labelStyle: TextStyle(
                                              color:
                                                  theme.colorScheme.secondary,
                                            ),
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: theme
                                                      .colorScheme.secondary),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: theme
                                                      .colorScheme.secondary),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: theme
                                                      .colorScheme.secondary),
                                            ),
                                          ),
                                          onChanged: (value) =>
                                              _firstName = value,
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          initialValue: _lastName,
                                          decoration: InputDecoration(
                                            labelText: 'Last Name',
                                            labelStyle: TextStyle(
                                              color:
                                                  theme.colorScheme.secondary,
                                            ),
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: theme
                                                      .colorScheme.secondary),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: theme
                                                      .colorScheme.secondary),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: theme
                                                      .colorScheme.secondary),
                                            ),
                                          ),
                                          onChanged: (value) =>
                                              _lastName = value,
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          initialValue: _email,
                                          decoration: InputDecoration(
                                            labelText: 'Email',
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: theme
                                                      .colorScheme.secondary),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: theme
                                                      .colorScheme.secondary),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: theme
                                                      .colorScheme.secondary),
                                            ),
                                          ),
                                          enabled: false,
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          initialValue: _school,
                                          decoration: InputDecoration(
                                            labelText: 'School',
                                            labelStyle: TextStyle(
                                              color:
                                                  theme.colorScheme.secondary,
                                            ),
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: theme
                                                      .colorScheme.secondary),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: theme
                                                      .colorScheme.secondary),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: theme
                                                      .colorScheme.secondary),
                                            ),
                                          ),
                                          onChanged: (value) => _school = value,
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          initialValue: _address,
                                          decoration: InputDecoration(
                                            labelText: 'Address',
                                            labelStyle: TextStyle(
                                              color:
                                                  theme.colorScheme.secondary,
                                            ),
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: theme
                                                      .colorScheme.secondary),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: theme
                                                      .colorScheme.secondary),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: theme
                                                      .colorScheme.secondary),
                                            ),
                                          ),
                                          onChanged: (value) =>
                                              _address = value,
                                        ),
                                        const SizedBox(height: 16),
                                      ] else ...[
                                        RichText(
                                          text: TextSpan(
                                            text: 'Name: ',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            children: [
                                              TextSpan(
                                                text:
                                                    '${_firstName ?? ''} ${_lastName ?? ''}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        RichText(
                                          text: TextSpan(
                                            text: 'Email: ',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: _email ?? '',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        RichText(
                                          text: TextSpan(
                                            text: 'Address: ',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: _address ?? '',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        RichText(
                                          text: TextSpan(
                                            text: 'School: ',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: _school ?? '',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_isEditing) ...[
                              if (_isTeacher) ...[
                                TextFormField(
                                  initialValue: _about,
                                  decoration: InputDecoration(
                                    labelText: 'About',
                                    labelStyle: TextStyle(
                                      color: theme.colorScheme.secondary,
                                    ),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: theme.colorScheme.secondary),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: theme.colorScheme.secondary),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: theme.colorScheme.secondary),
                                    ),
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.always,
                                  ),
                                  maxLines: null,
                                  minLines: 5,
                                  onChanged: (value) => _about = value,
                                ),
                                const SizedBox(height: 20),
                              ],
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: _saveUserData,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            theme.colorScheme.secondary,
                                        foregroundColor:
                                            theme.colorScheme.onSecondary),
                                    child: const Text('Save'),
                                  ),
                                  const SizedBox(width: 16),
                                  OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _isEditing = false;
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor:
                                          theme.colorScheme.secondary,
                                      side: BorderSide(
                                        color: theme.colorScheme.secondary,
                                        width: 1,
                                      ),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                ],
                              )
                            ] else ...[
                              if (_isTeacher) ...[
                                const Text('About Me',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    )),
                                Text('$_about',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                    )),
                                const SizedBox(height: 20),
                              ],
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _isEditing = true;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        theme.colorScheme.secondary,
                                    foregroundColor:
                                        theme.colorScheme.onSecondary),
                                child: const Text('Edit Profile',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w400)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (_isTeacher) ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Students",
                            style: TextStyle(
                              fontSize: 25,
                              fontFamily: 'Hobo',
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _showAddStudentModal,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Student',
                                style: TextStyle(fontWeight: FontWeight.w400)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Click on a student profile to edit and view their progress reports. You can add students by clicking the button to the right and entering their student ID.",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(
                        child: FutureBuilder<List<String>>(
                          future: _getStudentIds(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError) {
                              return Center(
                                  child: Text('ERROR: ${snapshot.error}'));
                            }

                            final studentIds = snapshot.data ?? [];

                            if (studentIds.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Card(
                                  color:
                                      const Color.fromARGB(255, 254, 248, 232),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: const BorderSide(
                                      color: Color(0xffefbd40),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Row(
                                      children: [
                                        Icon(Icons.warning_amber_rounded,
                                            color: Color(0xffefbd40)),
                                        SizedBox(width: 5),
                                        Text(
                                          'No students found',
                                          style: TextStyle(
                                            color: Color(0xffefbd40),
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }

                            return FutureBuilder<List<DocumentSnapshot>>(
                              future: _getStudentsData(studentIds),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }

                                if (snapshot.hasError) {
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 16.0),
                                    child: Card(
                                      color: const Color.fromARGB(
                                          255, 255, 215, 215),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(
                                          color: theme.colorScheme.secondary,
                                          width: 1,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons
                                                  .warning_amber_rounded, // Changed to warning icon
                                              color:
                                                  theme.colorScheme.secondary,
                                            ),
                                            const SizedBox(width: 5),
                                            Expanded(
                                              child: Text(
                                                snapshot.error.toString(),
                                                style: TextStyle(
                                                  color: theme
                                                      .colorScheme.secondary,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final students = snapshot.data ?? [];

                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.5,
                                    child: GridView.builder(
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 4,
                                        crossAxisSpacing: 8.0,
                                        mainAxisSpacing: 8.0,
                                      ),
                                      itemCount: students.length,
                                      itemBuilder: (context, index) {
                                        final doc = students[index];
                                        final studentData =
                                            doc.data() as Map<String, dynamic>;
                                        return Card(
                                          elevation: 4,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      StudentDetail(
                                                    studentId: doc.id,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                    child: studentData[
                                                                    'profilePictureUrl'] !=
                                                                null &&
                                                            studentData[
                                                                    'profilePictureUrl']!
                                                                .isNotEmpty
                                                        ? Image.network(
                                                            studentData[
                                                                'profilePictureUrl']!,
                                                            width:
                                                                double.infinity,
                                                            height: 150,
                                                            fit: BoxFit.cover,
                                                          )
                                                        : Image.asset(
                                                            'assets/user.png',
                                                            width:
                                                                double.infinity,
                                                            height: 150,
                                                            fit: BoxFit.cover,
                                                          ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        RichText(
                                                          text: TextSpan(
                                                            text: 'Name: ',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                            children: [
                                                              TextSpan(
                                                                text:
                                                                    '${studentData['firstName'] ?? ''} ${studentData['lastName'] ?? ''}',
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        RichText(
                                                          text: TextSpan(
                                                            text: 'School: ',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                            children: [
                                                              TextSpan(
                                                                text: studentData[
                                                                        'school'] ??
                                                                    'N/A',
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        RichText(
                                                          text: TextSpan(
                                                            text: 'Address: ',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                            children: [
                                                              TextSpan(
                                                                text: studentData[
                                                                        'address'] ??
                                                                    'N/A',
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Future<List<String>> _getStudentIds() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final data = userDoc.data()!;
    final studentIds = List<String>.from(data['studentIds'] ?? []);
    return studentIds;
  }

  Future<List<DocumentSnapshot>> _getStudentsData(
      List<String> studentIds) async {
    if (studentIds.isEmpty) return [];

    final studentDocs = await Future.wait(
        studentIds.map((id) => _firestore.collection('users').doc(id).get()));

    return studentDocs;
  }
}
