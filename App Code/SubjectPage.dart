import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/DivisionPage.dart';

class SubjectPage extends StatefulWidget {
  final String userId;
  final String batchId;
  final String batchName;

  const SubjectPage({
    Key? key,
    required this.userId,
    required this.batchId,
    required this.batchName,
  }) : super(key: key);

  @override
  _SubjectPageState createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> {
  late DatabaseReference subjectsReference;
  List<Map<String, dynamic>> subjects = [];

  @override
  void initState() {
    super.initState();
    subjectsReference = FirebaseDatabase.instance
        .ref('users/${widget.userId}/batches/${widget.batchId}/subjects');
    fetchSubjects();
  }

  Future<void> fetchSubjects() async {
    try {
      final snapshot = await subjectsReference.get();
      if (snapshot.exists) {
        final Map<dynamic, dynamic> subjectsData =
            snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          subjects = subjectsData.entries.map((entry) {
            return {
              'key': entry.key as String, // Subject name is the key
              'name': (entry.value as Map<dynamic, dynamic>)['name'] as String,
            };
          }).toList();
        });
      } else {
        setState(() {
          subjects = [];
        });
      }
    } catch (e) {
      print("Failed to fetch subjects: $e");
    }
  }

  void _showAddSubjectDialog(BuildContext context) {
    TextEditingController _textFieldController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Subject'),
          content: TextField(
            controller: _textFieldController,
            decoration: InputDecoration(hintText: 'Enter subject name'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('ADD'),
              onPressed: () {
                String newSubject = _textFieldController.text.trim();
                if (newSubject.isNotEmpty) {
                  _addSubject(newSubject);
                  Navigator.of(context).pop();
                } else {
                  print('Subject name cannot be empty.');
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addSubject(String subjectName) async {
    final subjectRef = subjectsReference.child(subjectName);
    final snapshot = await subjectRef.get();

    if (snapshot.exists) {
      // Subject with the same name already exists
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Subject with this name already exists")),
      );
    } else {
      // Add new subject
      subjectRef.set({
        'name': subjectName,
      }).then((_) {
        fetchSubjects(); // Refresh the list
      }).catchError((error) {
        print("Failed to add subject: $error");
      });
    }
  }

  void _editSubject(String oldKey, String newSubjectName) async {
    final existingSubjectRef = subjectsReference.child(newSubjectName);
    final snapshot = await existingSubjectRef.get();

    if (snapshot.exists && oldKey != newSubjectName) {
      // Subject with the new name already exists
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Subject with this name already exists")),
      );
    } else {
      // Update subject name
      subjectsReference.child(oldKey).remove().then((_) {
        final newSubjectRef = subjectsReference.child(newSubjectName);
        newSubjectRef.set({
          'name': newSubjectName,
        }).then((_) {
          fetchSubjects(); // Refresh the list
        }).catchError((error) {
          print("Failed to update subject: $error");
        });
      }).catchError((error) {
        print("Failed to delete old subject: $error");
      });
    }
  }

  void _deleteSubject(String key) {
    subjectsReference.child(key).remove().then((_) {
      fetchSubjects(); // Refresh the list
    }).catchError((error) {
      print("Failed to delete subject: $error");
    });
  }

  void _navigateToDivisionPage(String subjectId, String subjectName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DivisionPage(
          userId: widget.userId,
          batchId: widget.batchId,
          subjectId: subjectId,
          subjectName: subjectName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Subjects - ${widget.batchName} ',
          //'Batch: ${batch['name']}',
          textScaleFactor: 1.1,
        ),
        centerTitle: true,
        foregroundColor: Color.fromARGB(255, 58, 2, 91),
        backgroundColor: Color.fromARGB(255, 254, 114, 200),
      ),
      body: subjects.isEmpty
          ? Center(child: Text('No subjects available'))
          : SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    children: [
                      for (var subject in subjects)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GestureDetector(
                            onTap: () {
                              _navigateToDivisionPage(
                                  subject['key']!, subject['name']!);
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16.0, horizontal: 8.0),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Subject: ${subject['name']}',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (String result) {
                                      if (result == 'Edit') {
                                        _showEditSubjectDialog(
                                            subject['name']!, subject['key']!);
                                      } else if (result == 'Delete') {
                                        _deleteSubject(subject['key']!);
                                      }
                                    },
                                    itemBuilder: (BuildContext context) =>
                                        <PopupMenuEntry<String>>[
                                      const PopupMenuItem<String>(
                                        value: 'Edit',
                                        child: Text('Edit'),
                                      ),
                                      const PopupMenuItem<String>(
                                        value: 'Delete',
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color.fromARGB(255, 254, 114, 200),
        onPressed: () => _showAddSubjectDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  void _showEditSubjectDialog(String subjectName, String key) {
    TextEditingController _textFieldController =
        TextEditingController(text: subjectName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Subject'),
          content: TextField(
            controller: _textFieldController,
            decoration: InputDecoration(hintText: 'Enter new subject name'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('SAVE'),
              onPressed: () {
                String newSubjectName = _textFieldController.text.trim();
                if (newSubjectName.isNotEmpty) {
                  _editSubject(key, newSubjectName);
                  Navigator.of(context).pop();
                } else {
                  print('Subject name cannot be empty.');
                }
              },
            ),
          ],
        );
      },
    );
  }
}
