import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Upload(
        userId: 'yourUserId',
        batchId: 'yourBatchId',
        subjectId: 'yourSubjectId',
        divisionId: 'yourDivisionId',
      ),
    );
  }
}

class Upload extends StatefulWidget {
  final String userId;
  final String batchId;
  final String subjectId;
  final String divisionId;

  Upload({
    required this.userId,
    required this.batchId,
    required this.subjectId,
    required this.divisionId,
  });

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  late DatabaseReference databaseRef;
  File? file;

  @override
  void initState() {
    super.initState();
    databaseRef = FirebaseDatabase.instance.ref().child(
        'users/${widget.userId}/batches/${widget.batchId}/subjects/${widget.subjectId}/divisions/${widget.divisionId}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Attendance File'),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 254, 114, 200),
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: ElevatedButton(
                onPressed: pickExcel,
                child: Text('Pick Excel from Device'),
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: uploadExcel,
                child: Text('Upload Excel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void pickExcel() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);

    if (result != null) {
      setState(() {
        file = File(result.files.single.path!);
      });
    }
  }

  void uploadExcel() async {
    if (file != null) {
      try {
        final fileName = file!.path.split('/').last;

        // Upload file to Firebase Storage
        final ref =
            FirebaseStorage.instanceFor(bucket: 'shilpa-95e1c.appspot.com')
                .ref()
                .child("files/$fileName");

        await ref.putFile(file!);

        // Get the download URL
        final url = await ref.getDownloadURL();

        // Send file details to Flask server
        final serverUrl =
            'http://127.0.0.1:5000/train'; // Replace with your machine's IP
        final request = http.MultipartRequest('POST', Uri.parse(serverUrl));
        request.files
            .add(await http.MultipartFile.fromPath('file', file!.path));

        final response = await request.send();

        if (response.statusCode == 200) {
          showSnackBar('Model trained successfully');
        } else {
          showSnackBar('Failed to train model');
        }
      } catch (e) {
        showSnackBar('Error uploading file: $e');
      }
    } else {
      showSnackBar('No file selected.');
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }
}
