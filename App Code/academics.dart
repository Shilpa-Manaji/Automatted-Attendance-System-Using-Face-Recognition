// lib/DataPage.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Login.dart';
import 'package:flutter_application_1/SubjectPage.dart';

class Academics extends StatefulWidget {
  final String userId;

  const Academics({Key? key, required this.userId}) : super(key: key);

  @override
  _AcademicsState createState() => _AcademicsState();
}

class _AcademicsState extends State<Academics> {
  List<Map<String, String>> academicYears = [];
  final FirebaseAuth auth = FirebaseAuth.instance;
  late DatabaseReference databaseReference;
  final batchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    databaseReference =
        FirebaseDatabase.instance.ref('users/${widget.userId}/batches');
    fetchBatches();
  }

  Future<void> fetchBatches() async {
    try {
      final snapshot = await databaseReference.get();
      print("Snapshot value: ${snapshot.value}");
      if (snapshot.exists) {
        final Map<dynamic, dynamic> batches =
            snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          academicYears = batches.entries.map((entry) {
            return {
              'key': entry.key as String, // Batch name is the key
              'name': (entry.value as Map<dynamic, dynamic>)['name'] as String,
            };
          }).toList();
        });
      } else {
        setState(() {
          academicYears = [];
        });
      }
    } catch (e) {
      print("Failed to fetch batches: $e");
    }
  }

  void _showAddDialog(BuildContext context) {
    batchController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Batch'),
          content: TextField(
            controller: batchController,
            decoration: InputDecoration(hintText: "Enter batch name"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                String batchName = batchController.text.trim();
                if (batchName.isNotEmpty) {
                  _addBatch(batchName);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Invalid batch name")),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(String batchName, String key) {
    batchController.text = batchName;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Batch'),
          content: TextField(
            controller: batchController,
            decoration: InputDecoration(hintText: "Enter new batch name"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                String newBatchName = batchController.text.trim();
                if (newBatchName.isNotEmpty) {
                  _editBatch(key, newBatchName);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Invalid batch name")),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _addBatch(String batchName) async {
    final existingBatchRef = databaseReference.child(batchName);
    final snapshot = await existingBatchRef.get();

    if (snapshot.exists) {
      // Batch with the same name already exists
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Batch with this name already exists")),
      );
    } else {
      // Add new batch
      final newBatchRef = databaseReference.child(batchName);
      newBatchRef.set({'name': batchName}).then((_) {
        fetchBatches(); // Refresh the list
      }).catchError((error) {
        print("Failed to add batch: $error");
      });
    }
  }

  void _editBatch(String oldKey, String newBatchName) async {
    final existingBatchRef = databaseReference.child(newBatchName);
    final snapshot = await existingBatchRef.get();

    if (snapshot.exists && oldKey != newBatchName) {
      // Batch with the new name already exists
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Batch with this name already exists")),
      );
    } else {
      // Update batch name
      databaseReference.child(oldKey).remove().then((_) {
        final newBatchRef = databaseReference.child(newBatchName);
        newBatchRef.set({'name': newBatchName}).then((_) {
          fetchBatches(); // Refresh the list
        }).catchError((error) {
          print("Failed to update batch: $error");
        });
      }).catchError((error) {
        print("Failed to delete old batch: $error");
      });
    }
  }

  void _deleteBatch(String key) {
    databaseReference.child(key).remove().then((_) {
      fetchBatches(); // Refresh the list
    }).catchError((error) {
      print("Failed to delete batch: $error");
    });
  }

  void _logout() async {
    await auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => Loginpage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false; // Prevent back navigation
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Batches',
            textScaleFactor: 1.2,
          ),
          centerTitle: true,
          foregroundColor: Color.fromARGB(255, 58, 2, 91),
          backgroundColor: Color.fromARGB(255, 254, 114, 200),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _logout,
            ),
          ],
        ),
        body: academicYears.isEmpty
            ? Center(child: Text('No batches available'))
            : SingleChildScrollView(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      children: [
                        for (var batch in academicYears)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SubjectPage(
                                      userId: widget.userId,
                                      batchId: batch['key']!,
                                      batchName: batch['name']!,
                                    ),
                                  ),
                                );
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
                                      'Batch: ${batch['name']}',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (String result) {
                                        if (result == 'Edit') {
                                          _showEditDialog(
                                              batch['name']!, batch['key']!);
                                        } else if (result == 'Delete') {
                                          _deleteBatch(batch['key']!);
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
          onPressed: () => _showAddDialog(context),
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
