import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StudentDetail extends StatefulWidget {
  final String studentId;

  const StudentDetail({required this.studentId, super.key});

  @override
  _StudentDetailState createState() => _StudentDetailState();
}

class _StudentDetailState extends State<StudentDetail> {
  late Future<Map<String, dynamic>> _studentDetailsFuture;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  final Map<String, String> _grades = {
    'Proficient': 'Proficient',
    'Satisfactory': 'Satisfactory',
    'Developing': 'Developing',
    'Emerging': 'Emerging',
    'Skill Not Observed': 'Skill Not Observed',
  };

  late String _academicGrade;
  late String _employmentGrade;
  late String _communityGrade;
  late String _academicReport;
  late String _employmentReport;
  late String _communityReport;
  late List<dynamic> _skillGaps;

  @override
  void initState() {
    super.initState();
    _studentDetailsFuture = _fetchStudentDetails();
  }

  Future<Map<String, dynamic>> _fetchStudentDetails() async {
    final currentUser = await _firestore
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .get();
    final isEditable = currentUser.data()?['userType'] == 'Teacher';

    final userDoc =
        await _firestore.collection('users').doc(widget.studentId).get();
    final studentDoc =
        await _firestore.collection('students').doc(widget.studentId).get();

    final userData = userDoc.data() ?? {};
    final studentData = studentDoc.data() ?? {};

    _academicGrade = studentData['academicGrade'] ?? '';
    _employmentGrade = studentData['employmentGrade'] ?? '';
    _communityGrade = studentData['communityGrade'] ?? '';
    _academicReport = studentData['academicReport'] ?? '';
    _employmentReport = studentData['employmentReport'] ?? '';
    _communityReport = studentData['communityReport'] ?? '';
    _skillGaps = studentData['skillGaps'] ?? [];

    return {
      'firstName': userData['firstName'] ?? '',
      'lastName': userData['lastName'] ?? '',
      'school': userData['school'] ?? '',
      'address': userData['address'] ?? '',
      'profilePictureUrl': userData['profilePictureUrl'] ?? '',
      'academicGrade': studentData['academicGrade'] ?? '',
      'employmentGrade': studentData['employmentGrade'] ?? '',
      'communityGrade': studentData['communityGrade'] ?? '',
      'academicReport':
          studentData['academicReport'] ?? 'No academic report found',
      'employmentReport':
          studentData['employmentReport'] ?? 'No employment report found',
      'communityReport':
          studentData['communityReport'] ?? 'No community report found',
      'isEditable': isEditable,
      'skillGaps': studentData['skillGaps'] ?? [],
    };
  }

  void _saveChanges() async {
    if (_formKey.currentState?.validate() ?? false) {
      await _firestore.collection('students').doc(widget.studentId).update({
        'academicGrade': _academicGrade,
        'employmentGrade': _employmentGrade,
        'communityGrade': _communityGrade,
        'academicReport': _academicReport,
        'employmentReport': _employmentReport,
        'communityReport': _communityReport,
        'skillGaps': _skillGaps,
      });
      setState(() {
        _isEditing = false;
      });
    }
  }

  Future<void> _generateReport() async {
    final studentRef = _firestore.collection('students').doc(widget.studentId);

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/generate_report'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'student_id': widget.studentId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _academicGrade = data['academic_grade'] ?? 'Skill Not Observed';
          _employmentGrade = data['employment_grade'] ?? 'Skill Not Observed';
          _communityGrade = data['community_grade'] ?? 'Skill Not Observed';
          _academicReport = data['academic_report'] ?? '';
          _employmentReport = data['employment_report'] ?? '';
          _communityReport = data['community_report'] ?? '';
          _skillGaps = List<String>.from(data['skill_gaps'] ?? []);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'The report was generated successfully.',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      } else {
        throw Exception('ERROR: Failed to generate a report.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ERROR: $e',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> uploadFile(BuildContext context, String studentID) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      try {
        String fileName = result.files.single.name;
        Reference ref =
            FirebaseStorage.instance.ref().child('$studentID/$fileName');
        UploadTask uploadTask;
        if (kIsWeb) {
          final data = result.files.single.bytes;
          if (data != null) {
            uploadTask = ref.putData(data);
          } else {
            throw 'No file data found';
          }
        } else {
          final file = File(result.files.single.path!);
          uploadTask = ref.putFile(file);
        }
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          print(
              'Progress: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100} %');
        });
        await uploadTask;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'The file was uploaded successfully.',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      } catch (e) {
        print('Upload failed: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected')),
      );
    }
  }

  void _removeSkillGap(String skillGap) {
    setState(() {
      _skillGaps.remove(skillGap);
    });
  }

  Future<List<Map<String, dynamic>>> _fetchFiles() async {
    List<Map<String, dynamic>> files = [];
    final ListResult result =
        await FirebaseStorage.instance.ref(widget.studentId).listAll();

    for (var item in result.items) {
      final String name = item.name;
      final String url = await item.getDownloadURL();
      files.add({'name': name, 'url': url});
    }

    return files;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/logo.png', height: kToolbarHeight * 0.8),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _studentDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('No student data found'));
          }

          final isEditable = data['isEditable'] as bool;

          final List<String> skillGapsArray =
              List<String>.from(data['skillGaps']);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 5.0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: data['profilePictureUrl'] != null &&
                                    data['profilePictureUrl'] != ''
                                ? Image.network(
                                    data['profilePictureUrl'] ?? '',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  )
                                : Image.asset(
                                    'assets/user.png',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 30,
                                    )),
                                RichText(
                                  text: TextSpan(
                                    text: 'School: ',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '${data['school'] ?? ''}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                RichText(
                                  text: TextSpan(
                                    text: 'Address: ',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '${data['address'] ?? ''}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
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
                  const SizedBox(height: 16),
                  Card(
                    elevation: 8.0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isEditing)
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8.0,
                                    runSpacing: 4.0,
                                    children: _skillGaps.map((skillGap) {
                                      return Chip(
                                        label: Text(skillGap,
                                            style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: theme
                                                    .colorScheme.secondary)),
                                        onDeleted: () =>
                                            _removeSkillGap(skillGap),
                                        deleteIcon: const Icon(Icons.close),
                                        deleteIconColor:
                                            theme.colorScheme.secondary,
                                        side: BorderSide(
                                            color: theme.colorScheme.secondary,
                                            width: 2.0),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 20),
                                  _buildGradeDropdown(
                                    'Academic Grade',
                                    _academicGrade,
                                    (value) {
                                      setState(() {
                                        _academicGrade = value ?? 'Proficient';
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  _buildTextArea(
                                    'Academic Report',
                                    _academicReport,
                                    (value) {
                                      setState(() {
                                        _academicReport = value ?? '';
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  _buildGradeDropdown(
                                    'Employment Grade',
                                    _employmentGrade,
                                    (value) {
                                      setState(() {
                                        _employmentGrade =
                                            value ?? 'Proficient';
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  _buildTextArea(
                                    'Employment Report',
                                    _employmentReport,
                                    (value) {
                                      setState(() {
                                        _employmentReport = value ?? '';
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  _buildGradeDropdown(
                                    'Community Grade',
                                    _communityGrade,
                                    (value) {
                                      setState(() {
                                        _communityGrade = value ?? 'Proficient';
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  _buildTextArea(
                                    'Community Report',
                                    _communityReport,
                                    (value) {
                                      setState(() {
                                        _communityReport = value ?? '';
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      ElevatedButton(
                                        onPressed: _saveChanges,
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                theme.colorScheme.secondary,
                                            foregroundColor:
                                                theme.colorScheme.onSecondary),
                                        child: const Text('Save'),
                                      ),
                                      const SizedBox(width: 8),
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
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _generateReport,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Generate Report'),
                                  ),
                                ],
                              ),
                            )
                          else ...[
                            Text(
                              "Progress Report",
                              style: TextStyle(
                                fontSize: 25,
                                fontFamily: 'Hobo',
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              "When generating reports with Gemini AI, please check the contents before saving them. The model summarizes insights it gleaned from the uploaded documents, such as assessments and notes from educators. The skill gaps below are automatically generated.",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black.withOpacity(0.8)),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
                                const Text(
                                  'Skill Gaps',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                const SizedBox(height: 5),
                                SkillGapsRow(skillGaps: skillGapsArray),
                                const SizedBox(height: 20),
                              ],
                            ),
                            _buildGradeText(
                                'Academic Grade', data['academicGrade']),
                            _buildTextAreaDisplay(
                              'Academic Report',
                              data['academicReport'],
                            ),
                            const SizedBox(height: 20),
                            Divider(
                              color: Colors.grey.withOpacity(0.2),
                              height: 1,
                            ),
                            const SizedBox(height: 20),
                            _buildGradeText(
                                'Employment Grade', data['employmentGrade']),
                            _buildTextAreaDisplay(
                              'Employment Report',
                              data['employmentReport'],
                            ),
                            const SizedBox(height: 20),
                            Divider(
                              color: Colors.grey.withOpacity(0.2),
                              height: 1,
                            ),
                            const SizedBox(height: 20),
                            _buildGradeText(
                                'Community Grade', data['communityGrade']),
                            _buildTextAreaDisplay(
                              'Community Report',
                              data['communityReport'],
                            ),
                            const SizedBox(height: 16),
                            if (isEditable)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _isEditing = true;
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            theme.colorScheme.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Edit Report'),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      onPressed: () {
                                        uploadFile(context, widget.studentId);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            theme.colorScheme.secondary,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Upload'),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGradeDropdown(
    String label,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    String safeValue =
        _grades.containsKey(value) ? value : 'Skill Not Observed';

    return DropdownButtonFormField<String>(
      value: safeValue,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ),
      items: _grades.entries.map((entry) {
        return DropdownMenuItem<String>(
          value: entry.key,
          child: Text(
            entry.value,
            style: const TextStyle(
              fontWeight: FontWeight.w400,
            ),
          ),
        );
      }).toList(),
      validator: (value) {
        if (value == null || !_grades.containsKey(value)) {
          return 'Please select a valid grade';
        }
        return null;
      },
    );
  }

  Widget _buildTextArea(
      String label, String value, ValueChanged<String?> onChanged) {
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
        ),
        border: OutlineInputBorder(
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.secondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.secondary),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        enabledBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.secondary),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field cannot be empty';
        }
        return null;
      },
    );
  }

  Widget _buildTextAreaDisplay(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        '$label:',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      Text(
        value,
        style: TextStyle(fontSize: 16),
      )
    ]);
  }

  Widget _buildGradeText(String label, String value) {
    final color = _getGradeColor(value);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        '$label:',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      Text(
        value,
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20),
      )
    ]);
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'Proficient':
        return Colors.blue;
      case 'Satisfactory':
        return Colors.green;
      case 'Developing':
        return Color(0xffefbd40);
      case 'Emerging':
        return Colors.orange;
      case 'Skill Not Observed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class SkillGapsRow extends StatelessWidget {
  final List<String> skillGaps;

  const SkillGapsRow({required this.skillGaps, super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0, // Space between chips horizontally
      runSpacing: 8.0, // Space between chips vertically
      children: skillGaps.map((skillGap) {
        return Chip(
          label: Text(
            skillGap,
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          backgroundColor: Colors.transparent,
          side: BorderSide(
            color: Theme.of(context).colorScheme.secondary,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
        );
      }).toList(),
    );
  }
}
