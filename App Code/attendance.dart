import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Attendance(
        userId: 'yourUserId',
        batchId: 'yourBatchId',
        subjectId: 'yourSubjectId',
        divisionId: 'yourDivisionId',
      ),
    );
  }
}

class Attendance extends StatefulWidget {
  final String userId;
  final String batchId;
  final String subjectId;
  final String divisionId;

  Attendance({
    required this.userId,
    required this.batchId,
    required this.subjectId,
    required this.divisionId,
  });

  @override
  _AttendanceState createState() => _AttendanceState();
}

class _AttendanceState extends State<Attendance> {
  File? image;
  File? file;
  bool _isLoading = false;
  bool _isViewingAttendance = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Page'),
        centerTitle: true,
        foregroundColor: Color.fromARGB(255, 23, 1, 1),
        backgroundColor: Color.fromARGB(255, 254, 114, 200),
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Wrap(
                    spacing: 20.0,
                    runSpacing: 20.0,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: pickExcel,
                        child: Text('Pick Excel from Device'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 24.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: uploadExcel,
                        child: Text('Upload Excel'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 24.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: pickFilesFromDevice,
                        child: Text('Pick Image from Device'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 24.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: uploadFiles,
                        child: Text('Upload Image'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 24.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: viewAttendance,
                        child: Text('View Attendance'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 24.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          if (_isViewingAttendance)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  void pickExcel() async {
    // Show a dialog with the required message
    bool? isConfirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Excel File Format'),
          content: Text(
            'The Excel file should contain three columns: Images, Names, and Roll no.',
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (isConfirmed == true) {
      // If the user confirmed, proceed with picking the file
      FilePickerResult? result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);

      if (result != null) {
        setState(() {
          file = File(result.files.single.path!);
        });
      }
    }
  }

  void uploadExcel() async {
    if (file != null) {
      setState(() {
        _isLoading = true;
      });
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
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      showSnackBar('No file selected.');
    }
  }

  void pickFilesFromDevice() async {
    final picture = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picture != null) {
      setState(() {
        image = File(picture.path);
      });
    }
  }

  void uploadFiles() async {
    if (image != null) {
      setState(() {
        _isLoading = true;
      });
      try {
        final fileName = image!.path.split('/').last;
        final ref =
            FirebaseStorage.instanceFor(bucket: 'shilpa-95e1c.appspot.com')
                .ref()
                .child("files/$fileName");
        await ref.putFile(image!);

        final request = http.MultipartRequest(
            'POST',
            Uri.parse(
                'http://127.0.0.1:5000/recognize')); // Replace with your Flask server URL

        request.files
            .add(await http.MultipartFile.fromPath('file', image!.path));

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);

          if (responseData['message'] == "No faces detected") {
            showSnackBar('No faces detected in the image.');
          } else {
            showSnackBar('Attendance marked successfully');
          }
        } else {
          showSnackBar('Failed to mark attendance: ${response.body}');
        }
      } catch (e) {
        showSnackBar('Error uploading file: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      showSnackBar('No file selected.');
    }
  }

  Future<void> viewAttendance() async {
    setState(() {
      _isViewingAttendance = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/view_attendance'
            //'https://0f50-2401-4900-4bbc-74f9-fccb-4343-70a0-bdd0.ngrok-free.app/view_attendance'
            ), // Replace with your Flask server URL
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/attendance.xlsx';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        // Open the file
        OpenFile.open(filePath);
      } else {
        showSnackBar('Failed to fetch attendance file.');
      }
    } catch (error) {
      showSnackBar('Error: $error');
    } finally {
      setState(() {
        _isViewingAttendance = false;
      });
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

  Map<String, List<String>> parseExcelData(Uint8List bytes) {
    final data = <String, List<String>>{};

    // Decode the bytes into an Excel object
    var excel = Excel.decodeBytes(bytes);

    // Check if we have any sheets
    if (excel == null || excel.tables.isEmpty) {
      return data; // Return empty data if no sheets
    }

    // Get the first sheet
    var sheet = excel.tables.values.first;

    // Get the headers
    var headers =
        sheet.rows.first.map((cell) => cell?.toString().trim() ?? '').toList();

    // Initialize data map with headers
    for (var header in headers) {
      data[header] = [];
    }

    // Populate the data map
    for (var row in sheet.rows.skip(1)) {
      for (var i = 0; i < headers.length; i++) {
        if (i < row.length) {
          data[headers[i]]?.add(row[i]?.toString() ?? '');
        }
      }
    }

    return data;
  }
}
