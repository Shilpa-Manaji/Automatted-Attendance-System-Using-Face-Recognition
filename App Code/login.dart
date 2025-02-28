import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/academics.dart';
import 'package:flutter_application_1/signup.dart';
//import 'package:mini_project/pages/homepage.dart';  // Import your homepage here

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  bool showPassword = false;
  final phoneController = TextEditingController();
  final _password = TextEditingController();
  final databaseReference = FirebaseDatabase.instance.ref('users');
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    final user = auth.currentUser;
    if (user != null) {
      // User is already logged in, navigate to Academics page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Academics(userId: user.phoneNumber ?? ''),
        ),
      );
    }
  }

  void _login() async {
    final phone = phoneController.text.trim();
    final password = _password.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      // Show error if fields are empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter both phone number and password")),
      );
      return;
    }

    try {
      // Query database for users with the given phone number
      final snapshot =
          await databaseReference.orderByChild('phone').equalTo(phone).once();

      if (snapshot.snapshot.value == null) {
        // Phone number not found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Phone number not found")),
        );
        return;
      }

      final users = snapshot.snapshot.value as Map?;
      final user = users?.values.first as Map?;

      if (user != null) {
        final storedPassword = user['password'];
        if (storedPassword == password) {
          // Correct password, navigate to Academics page with phone number
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Academics(userId: phone),
            ),
          );
        } else {
          // Incorrect password
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Incorrect password")),
          );
        }
      } else {
        // No user data found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User data not found")),
        );
      }
    } catch (error) {
      // Handle any errors
      print("Failed to login: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to login: $error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xffCB2B93),
                  Color(0xff9546C4),
                  Color(0xff5E61F4),
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
                    TextField(
                      keyboardType: TextInputType.number,
                      controller: phoneController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: Icon(Icons.phone),
                        hintText: "Enter phone number",
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _password,
                      obscureText: !showPassword,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: InkWell(
                          onTap: () {
                            setState(() {
                              showPassword = !showPassword;
                            });
                          },
                          child: Icon(showPassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                        ),
                        hintText: "Enter password",
                      ),
                    ),
                    SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: _login,
                      child: Text("Login"),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 40),
                    Text("Don't have an account?",
                        style: TextStyle(color: Colors.white)),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Signup()),
                        );
                      },
                      child: Text(
                        "Sign up",
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.white,
                          decorationColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
