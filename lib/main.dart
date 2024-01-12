import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_absen/core/database/database_config.dart';
import 'package:login_absen/core/database/database_helper.dart';
import 'package:login_absen/core/services/NotificationController.dart';
import 'package:login_absen/core/ui/screens/HrSystem.dart';
import 'package:login_absen/core/ui/screens/Wfh.dart';
import 'package:login_absen/core/ui/screens/invalid_ip.dart';
import 'package:login_absen/core/ui/screens/ip_config.dart';
import 'package:login_absen/core/ui/screens/login_screen.dart';
import 'package:login_absen/core/ui/screens/no_connection.dart';
import 'package:login_absen/core/ui/screens/profile_screen.dart';
import 'package:login_absen/core/ui/screens/quiz_screen.dart';
import 'core/ui/screens/camera_screen.dart';
import 'dart:async';
import 'core/ui/screens/login_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationController.initializeLocalNotifications();
  await NotificationController.initializeRemoteNotifications(debug: true);
  // await NotificationController.initializeIsolateReceivePort();
  await NotificationController.getInitialNotificationAction();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({super.key});
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState(){

    NotificationController.startListeningNotificationEvents();
    NotificationController.requestFirebaseToken();
    AwesomeNotificationsFcm().subscribeToTopic("TrusmiOntime");

    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return GetMaterialApp(
      title: "Trusmi Ontime",
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      routes: {
        "/login": (context) => LoginScreen(),
        "/profile": (context) => ProfileScreen(),
        "/camera": (context) => CameraScreen(),
        "/no_connection": (context) => NoConnection(),
        "/invalid_ip": (context) => InvalidIP(),
        "/ip_config": (context) => IpConfig(),
        "/login_config": (context) => LoginConfig(),
        "/hrsystem": (context) => HrSystem(),
        "/wfh": (context) => Wfh(),
        "/quiz": (context) => QuizScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // ConnectivityResult _connectionStatus = ConnectivityResult.none;
  // final Connectivity _connectivity = Connectivity();
  // late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  String? ip;
  String? userID;
  String? username;
  String? fcmToken;
  // static String date = new DateTime.now().toIso8601String().substring(0, 10);
  final dbHelper = DatabaseHelper.instance;
  final dbConfig = DatabaseConfigHelper.instance;

  String? ipAddress;

  @override
  void initState() {
    super.initState();
    _deleteConfig();
    getPref();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void getPref() async {

      Future.delayed(const Duration(seconds: 1), () {
        // if (fcmToken != null || fcmToken == '') {
        //   Future.delayed(const Duration(seconds: 1), () {
        //     Navigator.pushNamedAndRemoveUntil(
        //         context, "/login", (Route<dynamic> routes) => false);
        //   });
        // } else {
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pushNamedAndRemoveUntil(
                context, "/profile", (Route<dynamic> routes) => false);
          });
        // }
        precacheImage(AssetImage('assets/background.png'), context);
        precacheImage(AssetImage('assets/logo_png_ontime.png'), context);
      });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
        image: DecorationImage(
        image: AssetImage('assets/background.png'), fit: BoxFit.cover)),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image(
                alignment: Alignment.center,
                height: MediaQuery.of(context).size.height / 4,
                width: MediaQuery.of(context).size.width / 2,
                image: AssetImage("assets/logo_png_ontime.png"),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Widget splashscreen() {
  //
  // }

  void _deleteConfig() async {
//     Assuming that the number of rows is the id for the last row.
    // final id = await dbConfig.queryRowCount();
    await dbConfig.deleteAll();
    // print('deleted $rowsDeleted row(s): row $id');
    _insertConfig();
  }

  void _insertConfig() async {
    // row to insert
    Map<String, dynamic> row = {
      DatabaseConfigHelper.instance.columnUsername: 'ittrusmi',
      DatabaseConfigHelper.instance.columnPassword: 'trusmiit'
    };
    await dbConfig.insert(row);
    // print('inserted row id: $id');
    // _showConfig();
  }

  // void _showConfig() async {
  //   final allRows = await dbConfig.queryAllRows();
  //   allRows.forEach((row) => print("Config = " + row.toString()));
  // }

  void showIp() async {
    final allRows = await dbHelper.queryAllRows();
    // print('query all rows show IP:');
    allRows.forEach((row) => print(row));
    var ip = '';
    ip = allRows[0]['ip_address'];
    print(ip);
  }
}
