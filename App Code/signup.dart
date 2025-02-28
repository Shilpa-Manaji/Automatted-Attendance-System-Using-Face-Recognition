import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:random_string/random_string.dart';

import 'login.dart';
//import 'package:mini_project/pages/login.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();
  var passwordcontroller = TextEditingController();
  var cpasswordcontroller = TextEditingController();
  final nameController = TextEditingController();
  final databaseReference = FirebaseDatabase.instance.ref('users');
  final phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Form(
            key: _formKey,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xffCB2B93),
                    Color(0xff9546C4),
                    Color(0xff5E61F4)
                  ],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(50),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        child: Icon(Icons.person),
                        radius: 35,
                      ),
                      SizedBox(height: 40),
                      TextFormField(
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Please enter name";
                          } else {
                            return null;
                          }
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText: "Enter name",
                        ),
                        controller: nameController,
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2),
                          border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.circular(12)),
                          hintText: "Enter phone number",
                        ),
                        controller: phoneController,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Please enter phone number";
                          } else if (value.length < 10 || value.length > 10) {
                            return "Incorrect phone number";
                          } else {
                            return null;
                          }
                        },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        obscureText: true,
                        controller: passwordcontroller,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2),
                          border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.circular(12)),
                          hintText: "Enter password",
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Please enter password";
                          }
                          if (value.length < 6) {
                            return "Password must contain at least 6 characters";
                          }
                          if (!value.contains(RegExp(r'[0-9]'))) {
                            return "Password must contain a number";
                          }
                          if (!value.contains(RegExp(r'[A-Z]'))) {
                            return "Password must contain a capital letter";
                          }
                          if (!value.contains(RegExp(r'[a-z]'))) {
                            return "Password must contain a small letter";
                          }
                          if (!value
                              .contains(RegExp(r'[!@%^&*(),.?":{}|<>#/]'))) {
                            return "Password must contain a special symbol";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        obscureText: true,
                        controller: cpasswordcontroller,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2),
                          border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.circular(12)),
                          hintText: "Confirm password",
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Please enter confirm password";
                          }
                          if (value != passwordcontroller.text) {
                            return "Password and confirm password must be the same";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 40),
                      OutlinedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final phone = phoneController.text.trim();
                            final name = nameController.text.trim();
                            final password = passwordcontroller.text.trim();
                            final cpassword = cpasswordcontroller.text.trim();

                            print("Form is valid");

                            final userRef = databaseReference.child(phone);
                            await userRef.set({
                              'name': name,
                              'phone': phone,
                              'password': password,
                              'cpassword': cpassword,
                            }).then((_) {
                              print("Data saved successfully");
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Loginpage()));
                            }).catchError((error) {
                              print("Failed to save data: $error");
                            });
                          } else {
                            print("Form is invalid");
                          }
                        },
                        child: Text("Signup"),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
