import 'package:connectivity/connectivity.dart';
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
      home: _cekLogin(),
//      home: LoginScreen(),
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
//    getPref();
    checkConnection();
  }

  @override
  void dispose(){
    super.dispose();
  }

  getPref()async{
    SharedPreferences pref = await SharedPreferences.getInstance();
    final username = pref.getString('username');

    if(username != null){
//        Future.delayed(const Duration(microseconds: 2000),(){
          Navigator.pushNamedAndRemoveUntil(context, "/profile", (Route<dynamic>routes)=>false);
//        });
    }else{
//        Future.delayed(const Duration(microseconds: 2000),(){
          Navigator.pushNamedAndRemoveUntil(context, "/login", (Route<dynamic>routes)=>false);
//        });
    }
  }

  Future<void>checkConnection() async{
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      // I am connected to a mobile network.
      Future.delayed(const Duration(microseconds: 2000),(){
        Navigator.pushNamedAndRemoveUntil(context, "/no_connection", (Route<dynamic>routes)=>false);
      });

    } else if (connectivityResult == ConnectivityResult.wifi) {
      // I am connected to a wifi network.
      getPref();
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