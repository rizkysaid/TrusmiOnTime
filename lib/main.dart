import 'package:flutter/material.dart';
import 'package:login_absen/core/ui/screens/login_screen.dart';
import 'package:login_absen/core/ui/screens/no_connection.dart';
import 'package:login_absen/core/ui/screens/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/ui/screens/camera_screen.dart';
import 'dart:async';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Login",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.red[700],
        accentColor: Colors.redAccent
      ),
//      home: _cekLogin(),
      home: _cekLogin(),
      routes: {
        "/login": (context) => LoginScreen(),
        // "/register": (context) => LoginScreen(),
        "/profile": (context) => ProfileScreen(),
        "/camera": (context) => CameraScreen(),
        "/no_connection": (context) => NoConnection(),
      },
    );
  }
}

class _cekLogin extends StatefulWidget {
  @override
  __cekLoginState createState() => __cekLoginState();
}

class __cekLoginState extends State<_cekLogin> {

  @override
  void initState() { 
    super.initState();
    getPref();
  }

  getPref()async{
    SharedPreferences pref = await SharedPreferences.getInstance();
    final username = pref.getString('username');

    if(username != null){
        Future.delayed(const Duration(microseconds: 2000),(){
          Navigator.pushNamedAndRemoveUntil(context, "/profile", (Route<dynamic>routes)=>false);
        });
    }else{
        Future.delayed(const Duration(microseconds: 2000),(){
          Navigator.pushNamedAndRemoveUntil(context, "/login", (Route<dynamic>routes)=>false);
        });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
       body: splashscreen(),
    );
  }

  Widget splashscreen(){
    return Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('assets/background.png'),
                  fit: BoxFit.cover
              )
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[

                Image(
                    alignment: Alignment.center,
                    height: MediaQuery.of(context).size.height / 4,
                    width: MediaQuery.of(context).size.width / 2,
                    image: AssetImage("assets/logo_png_ontime.png")
                )
              ],
            ),
          ),
        );
  }
}