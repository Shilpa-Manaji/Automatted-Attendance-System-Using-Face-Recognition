import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/attendance.dart'; // Import the DataPage

class DivisionPage extends StatefulWidget {
  final String userId;
  final String batchId;
  final String subjectId;
  final String subjectName;

  const DivisionPage({
    Key? key,
    required this.userId,
    required this.batchId,
    required this.subjectId,
    required this.subjectName,
  }) : super(key: key);

  @override
  _DivisionPageState createState() => _DivisionPageState();
}

class _DivisionPageState extends State<DivisionPage> {
  late DatabaseReference divisionsReference;
  List<Map<String, String>> divisions = [];

  @override
  void initState() {
    super.initState();
    divisionsReference = FirebaseDatabase.instance.ref(
        'users/${widget.userId}/batches/${widget.batchId}/subjects/${widget.subjectId}/divisions');
    fetchDivisions();
  }

  Future<void> fetchDivisions() async {
    try {
      final snapshot = await divisionsReference.get();
      if (snapshot.exists) {
        final Map<dynamic, dynamic> divisionsData =
            snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          divisions = divisionsData.entries.map((entry) {
            return {
              'key': entry.key as String, // Division name is the key
              'name': (entry.value as Map<dynamic, dynamic>)['name'] as String,
            };
          }).toList();
        });
      } else {
        setState(() {
          divisions = [];
        });
      }
    } catch (e) {
      print("Failed to fetch divisions: $e");
    }
  }

  void _showAddDivisionDialog(BuildContext context) {
    TextEditingController _textFieldController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Division'),
          content: TextField(
            controller: _textFieldController,
            decoration: InputDecoration(hintText: 'Enter division name'),
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
                String newDivision = _textFieldController.text.trim();
                if (newDivision.isNotEmpty) {
                  _addDivision(newDivision);
                  Navigator.of(context).pop();
                } else {
                  print('Division name cannot be empty.');
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addDivision(String divisionName) async {
    final divisionRef = divisionsReference.child(divisionName);
    final snapshot = await divisionRef.get();

    if (snapshot.exists) {
      // Division with the same name already exists
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Division with this name already exists")),
      );
    } else {
      // Add new division
      divisionRef.set({
        'name': divisionName,
      }).then((_) {
        fetchDivisions(); // Refresh the list
      }).catchError((error) {
        print("Failed to add division: $error");
      });
    }
  }

  void _editDivision(String oldKey, String newDivisionName) async {
    final existingDivisionRef = divisionsReference.child(newDivisionName);
    final snapshot = await existingDivisionRef.get();

    if (snapshot.exists && oldKey != newDivisionName) {
      // Division with the new name already exists
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Division with this name already exists")),
      );
    } else {
      // Update division name
      divisionsReference.child(oldKey).remove().then((_) {
        final newDivisionRef = divisionsReference.child(newDivisionName);
        newDivisionRef.set({
          'name': newDivisionName,
        }).then((_) {
          fetchDivisions(); // Refresh the list
        }).catchError((error) {
          print("Failed to update division: $error");
        });
      }).catchError((error) {
        print("Failed to delete old division: $error");
      });
    }
  }

  void _deleteDivision(String key) {
    divisionsReference.child(key).remove().then((_) {
      fetchDivisions(); // Refresh the list
    }).catchError((error) {
      print("Failed to delete division: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Divisions - ${widget.subjectName}',
          textScaleFactor: 1.2,
        ),
        centerTitle: true,
        foregroundColor: Color.fromARGB(255, 58, 2, 91),
        backgroundColor: Color.fromARGB(255, 254, 114, 200),
      ),
      body: divisions.isEmpty
          ? Center(child: Text('No divisions available'))
          : SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    children: [
                      for (var division in divisions)
                        GestureDetector(
                          onTap: () {
                            // Navigate to DataPage with division details
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Attendance(
                                  userId: widget.userId,
                                  batchId: widget.batchId,
                                  subjectId: widget.subjectId,
                                  divisionId: division['key']!,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
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
                                    'Division: ${division['name']}',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showEditDivisionDialog(
                                            division['name']!,
                                            division['key']!);
                                      } else if (value == 'delete') {
                                        _deleteDivision(division['key']!);
                                      }
                                    },
                                    itemBuilder: (BuildContext context) {
                                      return [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit'),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete'),
                                        ),
                                      ];
                                    },
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
        onPressed: () => _showAddDivisionDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  void _showEditDivisionDialog(String divisionName, String key) {
    TextEditingController _textFieldController =
        TextEditingController(text: divisionName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Division'),
          content: TextField(
            controller: _textFieldController,
            decoration: InputDecoration(hintText: 'Enter new division name'),
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
                String newDivisionName = _textFieldController.text.trim();
                if (newDivisionName.isNotEmpty) {
                  _editDivision(key, newDivisionName);
                  Navigator.of(context).pop();
                } else {
                  print('Division name cannot be empty.');
                }
              },
            ),
          ],
        );
      },
    );
  }
}
