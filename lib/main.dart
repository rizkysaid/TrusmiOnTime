import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:login_absen/core/config/endpoint.dart';
import 'package:login_absen/core/database/database_config.dart';
import 'package:login_absen/core/database/database_helper.dart';
import 'package:login_absen/core/services/ApiService.dart';
import 'package:login_absen/core/ui/screens/invalid_ip.dart';
import 'package:login_absen/core/ui/screens/ip_config.dart';
import 'package:login_absen/core/ui/screens/login_screen.dart';
import 'package:login_absen/core/ui/screens/no_connection.dart';
import 'package:login_absen/core/ui/screens/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/ui/screens/camera_screen.dart';
import 'dart:async';

import 'core/ui/screens/invalid_ip.dart';
import 'core/ui/screens/login_config.dart';
import 'core/utils/toast_util.dart';

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
        "/invalid_ip": (context) => InvalidIP(),
        "/ip_config": (context) => IpConfig(),
        "/login_config": (context) => LoginConfig(),
      },
    );
  }
}

class _cekLogin extends StatefulWidget {
  @override
  __cekLoginState createState() => __cekLoginState();
}

class __cekLoginState extends State<_cekLogin> {

  String userID;
  String username;
  static String date = new DateTime.now().toIso8601String().substring(0, 10);
  final dbHelper = DatabaseHelper.instance;
  final dbConfig = DatabaseConfigHelper.instance;

  String IpAddress;

  @override
  void initState() {
    super.initState();
//    getPref();
    checkConnection();
    _deleteConfig();

  }

  @override
  void dispose(){
    super.dispose();
  }

  getPref()async{

    String ip;
    final dbHelper = DatabaseHelper.instance;
    final allRows = await dbHelper.queryAllRows();
    print('query all rows:' +allRows.toList().toString());
    print('Length = '+allRows.length.toString());

    if(allRows.length != 0){

      allRows.forEach((row) => print(row));
      ip = allRows[0]['ip_address'];

    }else{
      ip = Endpoint.base_url;
    }

    print("IP = "+ip);

    ApiServices services = ApiServices();
    print('servis');
    var response = await services.CheckKoneksi(ip);
    print('checkKoneksi');
    print('Response service = '+response.toString());
    if(response == null){
      Future.delayed(const Duration(microseconds: 2000),(){
        Navigator.pushNamedAndRemoveUntil(context, "/invalid_ip", (Route<dynamic>routes)=>false);
      });
      final id = await dbHelper.queryRowCount();
      final rowsDeleted = await dbHelper.deleteAll();
      print('deleted $rowsDeleted row(s): row $id');

    }else{
      SharedPreferences pref = await SharedPreferences.getInstance();
      setState(() {
        username = pref.getString('username');
        userID = pref.getString('userID');
      });

      if(username == false){
        Future.delayed(const Duration(microseconds: 2000),(){
          Navigator.pushNamedAndRemoveUntil(context, "/login", (Route<dynamic>routes)=>false);
        });
      }else{
        Future.delayed(const Duration(microseconds: 2000),(){
          Navigator.pushNamedAndRemoveUntil(context, "/profile", (Route<dynamic>routes)=>false);
        });
      }



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

  void _deleteConfig() async {
//     Assuming that the number of rows is the id for the last row.
    final id = await dbConfig.queryRowCount();
    final rowsDeleted = await dbConfig.deleteAll();
    print('deleted $rowsDeleted row(s): row $id');
    _insertConfig();
  }

  void _insertConfig() async {
    // row to insert
    Map<String, dynamic> row = {
      DatabaseConfigHelper.columnUsername : 'admintrusmi',
      DatabaseConfigHelper.columnPassword  : 'trusmiadmin'
    };
    final id = await dbConfig.insert(row);
    print('inserted row id: $id');
    _showConfig();
  }

  void _showConfig()async{
    final allRows = await dbConfig.queryAllRows();
    allRows.forEach((row) => print("Config = "+row.toString()));
  }

  void show_ip() async {
    final allRows = await dbHelper.queryAllRows();
    print('query all rows:');
    allRows.forEach((row) => print(row));
    var ip = '';
    ip = allRows[0]['ip_address'];
    print(ip);
  }
}