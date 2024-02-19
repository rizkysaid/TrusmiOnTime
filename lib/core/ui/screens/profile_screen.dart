import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:login_absen/core/bloc/profile/profile_bloc.dart';
import 'package:login_absen/core/config/endpoint.dart';
import 'package:login_absen/core/config/about.dart';
import 'package:login_absen/core/controller/ProfileController.dart';
import 'package:login_absen/core/database/database_helper.dart';
import 'package:login_absen/core/models/ProfileModel.dart';
import 'package:login_absen/core/services/ApiService.dart';
import 'package:login_absen/core/services/face_camera.dart';
import 'package:login_absen/core/ui/screens/quiz_screen.dart';
import 'package:login_absen/core/ui/screens/trusmiverse.dart';
import 'package:login_absen/core/ui/widget/prodevBestEmployee.dart';
import 'package:login_absen/core/ui/widget/singleBestEmployee.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'PassParams.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:date_format/date_format.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:material_dialogs/material_dialogs.dart';
import 'package:material_dialogs/widgets/buttons/icon_button.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  ApiServices services = ApiServices();
  CancelToken apiToken = CancelToken();

  String username = '';
  String password = '';
  String userID = '';
  String nama = '';
  String jabatan = '';
  String clockin = '--:--';
  String clockout = '--:--';
  String imageUrl = '';
  String message = '';
  String _status = '';
  bool _isCheckin = false;
  bool statusPhoto = false;
  bool statusIcon = true;
  bool _visibleButton = true;
  Color _colorButton = Colors.red;
  late Timer timer;

  String dateIn = '';
  String dateOut = '';
  String idShift = '';
  String shiftIn = '';
  String shiftOut = '';
  String shift = '';

  String date = new DateTime.now().toIso8601String().substring(0, 10);
  String _toolTip = "Check In";
  String photoProfile = '';

  String _timeString = '';
  String _hariTanggal = '';
  String departmentId = '';
  String departmentName = '';

  // String fcmTokenExist = '';
  String firebaseAppToken = '';

  String prevMonthName = '';

  int responseTime = 15;

  bool isShowSuccessCheckin = false;
  bool isShowSuccessCheckout = false;

  late bool isQuizPasses;

  String dateId = formatDate(DateTime.now(), [dd, '/', mm, '/', yy]);

  File? imageFile;

  bool isShowHariBesar = false;
  bool statusHariBesar = false;
  String title = '';
  String msg = '';
  String gif = '';
  bool hariBesar = false;

  List<ProfileModel> productProfile = [];
  final ProfileBloc _profileBloc = ProfileBloc();

  RefreshController _refreshController =
  RefreshController(initialRefresh: false);

  final DateTime now = DateTime.now();
  final DateTime htNow = DateTime.now();


  @override
  void initState() {
    super.initState();

    initConnectivity();

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

    _timeString = _formatDateTime(now).toString();
    _hariTanggal = _formatHariTanggal(now).toString();
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) {

      _getTime();

      final String formattedHariTanggal = _formatHariTanggal(htNow).toString();

      _hariTanggal = formattedHariTanggal;
      // _timeString = formattedDateTime;
      // if (mounted) {
      //   setState(() {
      //     _timeString = formattedDateTime;
      //   });
      // }
    });

  }

  _formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  void _getTime() {
    final DateTime now = DateTime.now();
    final String formattedDateTime = _formatDateTime(now);
    if(mounted){
      setState(() {
        _timeString = formattedDateTime;
      });
    }
  }

  _formatHariTanggal(DateTime dateTime) {
    return DateFormat('EEE, dd MMM yyyy').format(dateTime);
  }

  Future<void> initConnectivity() async {

    // var pref = await SharedPreferences.getInstance();
    // if (pref.getString('fcmToken') == null || pref.getString('fcmToken') == '') {
    //   print('initConnectivityz');
    //   print(pref.getString('fcmToken'));
    //   logout();
    //
    // } else {

      late ConnectivityResult result;
      // Platform messages may fail, so we use a try/catch PlatformException.
      try {
        result = await _connectivity.checkConnectivity();

        if (result == ConnectivityResult.none) {
          Navigator.pushReplacementNamed(context, "/no_connection");
        } else if (result == ConnectivityResult.mobile) {
          if (Endpoint.baseIp == 'http://192.168.23.23') {
            Navigator.pushReplacementNamed(context, "/no_connection");
          } else {
            getPref();
          }
        } else {
          getPref();
        }
      } on PlatformException catch (e) {
        print(e.toString());
        return;
      }

      // If the widget was removed from the tree while the asynchronous platform
      // message was in flight, we want to discard the reply rather than calling
      // setState to update our non-existent appearance.
      if (!mounted) {
        return Future.value(null);
      }

      return _updateConnectionStatus(result);

    // }
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    setState(() {
      _connectionStatus = result;
    });
    if (result == ConnectivityResult.none) {
      Navigator.pushReplacementNamed(context, "/no_connection");
    } else if (result == ConnectivityResult.mobile) {
      if (Endpoint.baseIp == 'http://192.168.23.23') {
        Navigator.pushReplacementNamed(context, "/no_connection");
      } else {
        _profileBloc.add(InitialProfile());
        getPref();
        _onRefresh();
      }
    } else {
      _profileBloc.add(InitialProfile());
      getPref();
      _onRefresh();
    }
    print(_connectionStatus);
  }

  Future<void> _onRefresh() async {
    await Future.delayed(Duration(milliseconds: 2000));
    _refreshController.refreshCompleted();
    _profileBloc.add(InitialProfile());
    ProfileController().getProfil(userID, date, _profileBloc, apiToken);
  }

  Future<void> _onLoading() async {
    await Future.delayed(Duration(milliseconds: 2000));

    _refreshController.loadComplete();
  }

  Future<void> getPref() async {

    var requestToken = await AwesomeNotificationsFcm().requestFirebaseAppToken();
    setState(() {
      firebaseAppToken = requestToken;
    });
    print('getPref() token: $firebaseAppToken');

    _profileBloc.add(InitialProfile());
    var pref = await SharedPreferences.getInstance();
    if (pref.getString('username') == null || pref.getString('username') == '') {
    // if (pref.getString('fcmToken') == null || pref.getString('fcmToken') == '') {
      print('getPref() fcmToken:  ${pref.getString('fcmToken')}');
      logout();
    } else {
      setState(() {
        username = pref.getString('username')!;
        password = pref.getString('password')!;
        userID = pref.getString('userID').toString();
        departmentId = pref.getString('departmentId').toString();
        departmentName = pref.getString('departmentName').toString();
      });

      print('departmentName $departmentName');

      ProfileController().getProfil(userID, date, _profileBloc, apiToken);
    }

    if (clockin.isEmpty) {
      clockin = "--:--";
    }

    if (clockout.isEmpty) {
      clockout = "--:--";
    }

    if (imageUrl == "-") {
      imageUrl = "";
    }

    if (_status.isEmpty) {
      _status = "checkin";
    }
    precacheImage(AssetImage('assets/background_new.png'), context);
    precacheImage(AssetImage('assets/gold-medal.png'), context);
    precacheImage(AssetImage('assets/logo_png_ontime.png'), context);
  }

  Future<void> checkHolidays() async {
    String ip;
    final dbHelper = DatabaseHelper.instance;
    final allRows = await dbHelper.queryAllRows();

    if (allRows.length != 0) {
      allRows.forEach((row) => print(row));
      ip = allRows[0]['ip_address'];
    } else {
      ip = Endpoint.baseUrl;
    }

    var response = await services.checkHolidays(ip, userID);

    print('checkHolidays => ' + response.toString());
    if (response == null || response['status'] == false) {
      // 120 = Departement Marketing RSP
      if (departmentId == '120') {
        getBestMktRsp(context);
      } else {
        checkBestBadEmployee(context);
      }

      return null;
    } else {
      statusHariBesar = response['status'];
      // print(response['data']);
      if (statusHariBesar == true) {
        setState(() {
          hariBesar = true;
          title = response['title'];
          msg = response['message'];
          gif = response['gif'];
        });
        if (!isShowHariBesar) {
          showHariBesar(
              response['lottie'], response['title'], response['message']);
        }
      } else {
        setState(() {
          hariBesar = false;
        });
        // 120 = Departement Marketing RSP
        if (departmentId == '120') {
          getBestMktRsp(context);
        } else {
          checkBestBadEmployee(context);
        }
      }
    }
  }

  Future<void> checkBestBadEmployee(context) async {
    String ip;
    final dbHelper = DatabaseHelper.instance;
    final allRows = await dbHelper.queryAllRows();

    if (allRows.length != 0) {
      allRows.forEach((row) => print(row));
      ip = allRows[0]['ip_address'];
    } else {
      ip = Endpoint.baseUrl;
    }

    var response = await services.checkBestBadEmployee(ip, userID);

    if (response != null) {
      if (response['status'] == true) {
        _displayBestBadEmployees(context, response);
      } else {
        _profileBloc.add(InitialProfile());
        ProfileController().getProfil(userID, date, _profileBloc, apiToken);
      }
    } else {
      _profileBloc.add(InitialProfile());
      ProfileController().getProfil(userID, date, _profileBloc, apiToken);
    }
  }

  Future<void> _displayBestBadEmployees(BuildContext context, response) {
    return showGeneralDialog(
        context: context,
        barrierDismissible: false,
        transitionDuration: Duration(milliseconds: 500),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: animation,
              child: child,
            ),
          );
        },
        pageBuilder: (context, animation, secondaryAnimation) {
          return SafeArea(
            child: Container(
              padding: EdgeInsets.all(10),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          response['data']['best'].length == 1
                              ? SingleBestEmployee(response: response, userID: userID, date: date)
                              : ProdevBestEmployee(response: response, userID: userID, date: date),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: GestureDetector(
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          // image: DecorationImage(
                          //   image: AssetImage('assets/background_new.png'),
                          //   fit: BoxFit.cover,
                          // ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            DefaultTextStyle(
                              child: Text('Close (x)'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _profileBloc.add(InitialProfile());
                        ProfileController().getProfil(userID, date, _profileBloc, apiToken);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Future<void> getBestMktRsp(context) async {
    showProgressDialog(context);
    String ip;
    final dbHelper = DatabaseHelper.instance;
    final allRows = await dbHelper.queryAllRows();

    if (allRows.length != 0) {
      allRows.forEach((row) => print(row));
      ip = allRows[0]['ip_address'];
    } else {
      ip = Endpoint.baseUrl;
    }

    var response = await services.getBestMktRsp(ip, apiToken);
    if (response == null) {
      Navigator.pop(context);
      _profileBloc.add(InitialProfile());
      ProfileController().getProfil(userID, date, _profileBloc, apiToken);
    } else {
      _displayBestMktRsp(context, response);
    }
  }

  Future<void> _displayBestMktRsp(BuildContext context, response) {
    Navigator.pop(context);
    setState(() {
      prevMonthName = DateFormat('MMMM yyyy')
          .format(DateTime.now().subtract(Duration(days: 30)));
    });

    return showGeneralDialog(
        context: context,
        barrierDismissible: false,
        transitionDuration: Duration(milliseconds: 500),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: animation,
              child: child,
            ),
          );
        },
        pageBuilder: (context, animation, secondaryAnimation) {
          return SafeArea(
            child: Container(
              padding: EdgeInsets.all(10),
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            // color: Color(0xff015a80),
                            image: DecorationImage(
                              image: AssetImage('assets/background_new.png'),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                              bottomRight: Radius.circular(30),
                              bottomLeft: Radius.circular(30),
                            ),
                          ),
                          child: ListView(
                            children: [
                              SizedBox(
                                height: 15,
                              ),
                              Center(
                                child: DefaultTextStyle(
                                  child: Text(
                                    "Sales Of The Month",
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Center(
                                child: DefaultTextStyle(
                                  child: Text(
                                    prevMonthName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              // Akad
                              Center(
                                child: DefaultTextStyle(
                                  child: Text(
                                    "Akad",
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.only(left: 16, right: 16),
                                child: Divider(
                                  color: Colors.white,
                                ),
                              ),

                              (response['data']['ak_02_nama'] != '')
                                  ? Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Container(
                                              height: 120,
                                              width: (MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  2.5),
                                              child: Card(
                                                semanticContainer: true,
                                                elevation: 0,
                                                color: Colors.transparent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          15),
                                                ),
                                                child: Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    Container(
                                                      width: MediaQuery.of(
                                                                  context)
                                                              .size
                                                              .width /
                                                          2.5,
                                                      padding:
                                                          EdgeInsets.all(5),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          Container(
                                                            padding: EdgeInsets
                                                                .only(
                                                                    right:
                                                                        30),
                                                            child: Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .white,
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(
                                                                          2.5),
                                                              child:
                                                                  CircleAvatar(
                                                                backgroundImage:
                                                                    NetworkImage(
                                                                  Endpoint.baseIp +
                                                                      '/' +
                                                                      response['data']
                                                                          [
                                                                          'ak_12_photo'],
                                                                ),
                                                                radius: 30,
                                                              ),
                                                            ),
                                                          ),
                                                          Flexible(
                                                            child:
                                                                DefaultTextStyle(
                                                              child: Text(
                                                                response[
                                                                        'data']
                                                                    [
                                                                    'ak_12_nama'],
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                              style:
                                                                  TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                          Flexible(
                                                            child:
                                                                DefaultTextStyle(
                                                              child: Text(
                                                                'Masa kerja > 12 bulan',
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                              style:
                                                                  TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 10,
                                                      right: 15,
                                                      child: Stack(
                                                        alignment:
                                                            Alignment.center,
                                                        children: [
                                                          Container(
                                                            child: Image(
                                                              image: AssetImage(
                                                                  'assets/gold-medal.png'),
                                                              width: 70,
                                                              height: 70,
                                                            ),
                                                          ),
                                                          Positioned(
                                                            top: 10,
                                                            child:
                                                                DefaultTextStyle(
                                                              child: Text(
                                                                  'Akad'),
                                                              style:
                                                                  TextStyle(
                                                                color: Colors
                                                                    .black54,
                                                                fontSize: 8,
                                                              ),
                                                            ),
                                                          ),
                                                          Positioned(
                                                            top: 18,
                                                            child:
                                                                DefaultTextStyle(
                                                              child: Text(response[
                                                                      'data'][
                                                                  'ak_12_akad']),
                                                              style:
                                                                  TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 17,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Container(
                                              height: 120,
                                              width: (MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  2.5),
                                              child: Card(
                                                semanticContainer: true,
                                                elevation: 0,
                                                color: Colors.transparent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          15),
                                                ),
                                                child: Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    Container(
                                                      width: MediaQuery.of(
                                                                  context)
                                                              .size
                                                              .width /
                                                          2.5,
                                                      padding:
                                                          EdgeInsets.all(5),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          Container(
                                                            padding: EdgeInsets
                                                                .only(
                                                                    right:
                                                                        30),
                                                            child: Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .white,
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(
                                                                          2.5),
                                                              child:
                                                                  CircleAvatar(
                                                                backgroundImage:
                                                                    NetworkImage(
                                                                  Endpoint.baseIp +
                                                                      '/' +
                                                                      response['data']
                                                                          [
                                                                          'ak_612_photo'],
                                                                ),
                                                                radius: 30,
                                                              ),
                                                            ),
                                                          ),
                                                          Flexible(
                                                            child:
                                                                DefaultTextStyle(
                                                              child: Text(
                                                                response[
                                                                        'data']
                                                                    [
                                                                    'ak_612_nama'],
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                              style:
                                                                  TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                          Flexible(
                                                            child:
                                                                DefaultTextStyle(
                                                              child: Text(
                                                                'Masa kerja 6-12 bulan',
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                              style:
                                                                  TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 10,
                                                      right: 15,
                                                      child: Stack(
                                                        alignment:
                                                            Alignment.center,
                                                        children: [
                                                          Container(
                                                            child: Image(
                                                              image: AssetImage(
                                                                  'assets/gold-medal.png'),
                                                              width: 70,
                                                              height: 70,
                                                            ),
                                                          ),
                                                          Positioned(
                                                            top: 10,
                                                            child:
                                                                DefaultTextStyle(
                                                              child: Text(
                                                                  'Akad'),
                                                              style:
                                                                  TextStyle(
                                                                color: Colors
                                                                    .black54,
                                                                fontSize: 8,
                                                              ),
                                                            ),
                                                          ),
                                                          Positioned(
                                                            top: 18,
                                                            child:
                                                                DefaultTextStyle(
                                                              child: Text(response[
                                                                      'data'][
                                                                  'ak_612_akad']),
                                                              style:
                                                                  TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 17,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Container(
                                              height: 120,
                                              width: (MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  2.5),
                                              child: Card(
                                                semanticContainer: true,
                                                elevation: 0,
                                                color: Colors.transparent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          15),
                                                ),
                                                child: Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    Container(
                                                      width: MediaQuery.of(
                                                                  context)
                                                              .size
                                                              .width /
                                                          2.5,
                                                      padding:
                                                          EdgeInsets.all(5),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          Container(
                                                            padding: EdgeInsets
                                                                .only(
                                                                    right:
                                                                        30),
                                                            child: Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .white,
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(
                                                                          2.5),
                                                              child:
                                                                  CircleAvatar(
                                                                backgroundImage:
                                                                    NetworkImage(
                                                                  Endpoint.baseIp +
                                                                      '/' +
                                                                      response['data']
                                                                          [
                                                                          'ak_35_photo'],
                                                                ),
                                                                radius: 30,
                                                              ),
                                                            ),
                                                          ),
                                                          Flexible(
                                                            child:
                                                                DefaultTextStyle(
                                                              child: Text(
                                                                response[
                                                                        'data']
                                                                    [
                                                                    'ak_35_nama'],
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                              style:
                                                                  TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                          Flexible(
                                                            child:
                                                                DefaultTextStyle(
                                                              child: Text(
                                                                'Masa kerja 3-5 bulan',
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                              style:
                                                                  TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 10,
                                                      right: 15,
                                                      child: Stack(
                                                        alignment:
                                                            Alignment.center,
                                                        children: [
                                                          Container(
                                                            child: Image(
                                                              image: AssetImage(
                                                                  'assets/gold-medal.png'),
                                                              width: 70,
                                                              height: 70,
                                                            ),
                                                          ),
                                                          Positioned(
                                                            top: 10,
                                                            child:
                                                                DefaultTextStyle(
                                                              child: Text(
                                                                  'Akad'),
                                                              style:
                                                                  TextStyle(
                                                                color: Colors
                                                                    .black54,
                                                                fontSize: 8,
                                                              ),
                                                            ),
                                                          ),
                                                          Positioned(
                                                            top: 18,
                                                            child:
                                                                DefaultTextStyle(
                                                              child: Text(response[
                                                                      'data'][
                                                                  'ak_35_akad']),
                                                              style:
                                                                  TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 17,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Container(
                                              height: 120,
                                              width: (MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  2.5),
                                              child: Card(
                                                semanticContainer: true,
                                                elevation: 0,
                                                color: Colors.transparent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          15),
                                                ),
                                                child: Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    Container(
                                                      width: MediaQuery.of(
                                                                  context)
                                                              .size
                                                              .width /
                                                          2.5,
                                                      padding:
                                                          EdgeInsets.all(5),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          Container(
                                                            padding: EdgeInsets
                                                                .only(
                                                                    right:
                                                                        30),
                                                            child: Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .white,
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(
                                                                          2.5),
                                                              child:
                                                                  CircleAvatar(
                                                                backgroundImage:
                                                                    NetworkImage(
                                                                  Endpoint.baseIp +
                                                                      '/' +
                                                                      response['data']
                                                                          [
                                                                          'ak_02_photo'],
                                                                ),
                                                                radius: 30,
                                                              ),
                                                            ),
                                                          ),
                                                          Flexible(
                                                            child:
                                                                DefaultTextStyle(
                                                              child: Text(
                                                                response[
                                                                        'data']
                                                                    [
                                                                    'ak_02_nama'],
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                              style:
                                                                  TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                          Flexible(
                                                            child:
                                                                DefaultTextStyle(
                                                              child: Text(
                                                                'Masa kerja 0-2 bulan',
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                              style:
                                                                  TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 10,
                                                      right: 15,
                                                      child: Stack(
                                                        alignment:
                                                            Alignment.center,
                                                        children: [
                                                          Container(
                                                            child: Image(
                                                              image: AssetImage(
                                                                  'assets/gold-medal.png'),
                                                              width: 70,
                                                              height: 70,
                                                            ),
                                                          ),
                                                          Positioned(
                                                            top: 10,
                                                            child:
                                                                DefaultTextStyle(
                                                              child: Text(
                                                                  'Akad'),
                                                              style:
                                                                  TextStyle(
                                                                color: Colors
                                                                    .black54,
                                                                fontSize: 8,
                                                              ),
                                                            ),
                                                          ),
                                                          Positioned(
                                                            top: 18,
                                                            child:
                                                                DefaultTextStyle(
                                                              child: Text(response[
                                                                      'data'][
                                                                  'ak_02_akad']),
                                                              style:
                                                                  TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 17,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              height: 120,
                                              width: (MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  2.5),
                                              child: Card(
                                                semanticContainer: true,
                                                elevation: 0,
                                                color: Colors.transparent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          15),
                                                ),
                                                child: Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    Container(
                                                      width: MediaQuery.of(
                                                                  context)
                                                              .size
                                                              .width /
                                                          2.5,
                                                      padding:
                                                          EdgeInsets.all(5),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          Container(
                                                            padding: EdgeInsets
                                                                .only(
                                                                    right:
                                                                        30),
                                                            child: Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .white,
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(
                                                                          2.5),
                                                              child:
                                                                  CircleAvatar(
                                                                backgroundImage:
                                                                    NetworkImage(
                                                                  Endpoint.baseIp +
                                                                      '/' +
                                                                      response['data']
                                                                          [
                                                                          'ak_12_photo'],
                                                                ),
                                                                radius: 30,
                                                              ),
                                                            ),
                                                          ),
                                                          Flexible(
                                                            child:
                                                                DefaultTextStyle(
                                                              child: Text(
                                                                response[
                                                                        'data']
                                                                    [
                                                                    'ak_12_nama'],
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                              style:
                                                                  TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                          Flexible(
                                                            child:
                                                                DefaultTextStyle(
                                                              child: Text(
                                                                'Masa kerja > 12 bulan',
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                              style:
                                                                  TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 10,
                                                      right: 15,
                                                      child: Stack(
                                                        alignment:
                                                            Alignment.center,
                                                        children: [
                                                          Container(
                                                            child: Image(
                                                              image: AssetImage(
                                                                  'assets/gold-medal.png'),
                                                              width: 70,
                                                              height: 70,
                                                            ),
                                                          ),
                                                          Positioned(
                                                            top: 10,
                                                            child:
                                                                DefaultTextStyle(
                                                              child: Text(
                                                                  'Akad'),
                                                              style:
                                                                  TextStyle(
                                                                color: Colors
                                                                    .black54,
                                                                fontSize: 8,
                                                              ),
                                                            ),
                                                          ),
                                                          Positioned(
                                                            top: 18,
                                                            child:
                                                                DefaultTextStyle(
                                                              child: Text(response[
                                                                      'data'][
                                                                  'ak_12_akad']),
                                                              style:
                                                                  TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 17,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Container(
                                              height: 120,
                                              width: (MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  2.5),
                                              child: Card(
                                                semanticContainer: true,
                                                elevation: 0,
                                                color: Colors.transparent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          15),
                                                ),
                                                child: Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    Container(
                                                      width: MediaQuery.of(
                                                                  context)
                                                              .size
                                                              .width /
                                                          2.5,
                                                      padding:
                                                          EdgeInsets.all(5),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          Container(
                                                            padding: EdgeInsets
                                                                .only(
                                                                    right:
                                                                        30),
                                                            child: Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .white,
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(
                                                                          2.5),
                                                              child:
                                                                  CircleAvatar(
                                                                backgroundImage:
                                                                    NetworkImage(
                                                                  Endpoint.baseIp +
                                                                      '/' +
                                                                      response['data']
                                                                          [
                                                                          'ak_612_photo'],
                                                                ),
                                                                radius: 30,
                                                              ),
                                                            ),
                                                          ),
                                                          Flexible(
                                                            child:
                                                                DefaultTextStyle(
                                                              child: Text(
                                                                response[
                                                                        'data']
                                                                    [
                                                                    'ak_612_nama'],
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                              style:
                                                                  TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                          Flexible(
                                                            child:
                                                                DefaultTextStyle(
                                                              child: Text(
                                                                'Masa kerja 6-12 bulan',
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                              style:
                                                                  TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 10,
                                                      right: 15,
                                                      child: Stack(
                                                        alignment:
                                                            Alignment.center,
                                                        children: [
                                                          Container(
                                                            child: Image(
                                                              image: AssetImage(
                                                                  'assets/gold-medal.png'),
                                                              width: 70,
                                                              height: 70,
                                                            ),
                                                          ),
                                                          Positioned(
                                                            top: 10,
                                                            child:
                                                                DefaultTextStyle(
                                                              child: Text(
                                                                  'Akad'),
                                                              style:
                                                                  TextStyle(
                                                                color: Colors
                                                                    .black54,
                                                                fontSize: 8,
                                                              ),
                                                            ),
                                                          ),
                                                          Positioned(
                                                            top: 18,
                                                            child:
                                                                DefaultTextStyle(
                                                              child: Text(response[
                                                                      'data'][
                                                                  'ak_612_akad']),
                                                              style:
                                                                  TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 17,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Container(
                                              height: 120,
                                              width: (MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  2.5),
                                              child: Card(
                                                semanticContainer: true,
                                                elevation: 0,
                                                color: Colors.transparent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          15),
                                                ),
                                                child: Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    Container(
                                                      width: MediaQuery.of(
                                                                  context)
                                                              .size
                                                              .width /
                                                          2.5,
                                                      padding:
                                                          EdgeInsets.all(5),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          Container(
                                                            padding: EdgeInsets
                                                                .only(
                                                                    right:
                                                                        30),
                                                            child: Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .white,
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(
                                                                          2.5),
                                                              child:
                                                                  CircleAvatar(
                                                                backgroundImage:
                                                                    NetworkImage(
                                                                  Endpoint.baseIp +
                                                                      '/' +
                                                                      response['data']
                                                                          [
                                                                          'ak_35_photo'],
                                                                ),
                                                                radius: 30,
                                                              ),
                                                            ),
                                                          ),
                                                          Flexible(
                                                            child:
                                                                DefaultTextStyle(
                                                              child: Text(
                                                                response[
                                                                        'data']
                                                                    [
                                                                    'ak_35_nama'],
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                              style:
                                                                  TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                          Flexible(
                                                            child:
                                                                DefaultTextStyle(
                                                              child: Text(
                                                                'Masa kerja 3-5 bulan',
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                              style:
                                                                  TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 10,
                                                      right: 15,
                                                      child: Stack(
                                                        alignment:
                                                            Alignment.center,
                                                        children: [
                                                          Container(
                                                            child: Image(
                                                              image: AssetImage(
                                                                  'assets/gold-medal.png'),
                                                              width: 70,
                                                              height: 70,
                                                            ),
                                                          ),
                                                          Positioned(
                                                            top: 10,
                                                            child:
                                                                DefaultTextStyle(
                                                              child: Text(
                                                                  'Akad'),
                                                              style:
                                                                  TextStyle(
                                                                color: Colors
                                                                    .black54,
                                                                fontSize: 8,
                                                              ),
                                                            ),
                                                          ),
                                                          Positioned(
                                                            top: 18,
                                                            child:
                                                                DefaultTextStyle(
                                                              child: Text(response[
                                                                      'data'][
                                                                  'ak_35_akad']),
                                                              style:
                                                                  TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 17,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                              SizedBox(
                                height: 20,
                              ),

                              // Booking
                              Center(
                                child: DefaultTextStyle(
                                  child: Text(
                                    "Booking",
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.only(left: 16, right: 16),
                                child: Divider(
                                  color: Colors.white,
                                ),
                              ),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Container(
                                    height: 120,
                                    width:
                                        (MediaQuery.of(context).size.width /
                                            2.5),
                                    child: Card(
                                      semanticContainer: true,
                                      elevation: 0,
                                      color: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                2.5,
                                            padding: EdgeInsets.all(5),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.only(
                                                      right: 30),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    padding:
                                                        EdgeInsets.all(2.5),
                                                    child: CircleAvatar(
                                                      backgroundImage:
                                                          NetworkImage(
                                                        Endpoint.baseIp +
                                                            '/' +
                                                            response['data'][
                                                                'b_12_photo'],
                                                      ),
                                                      radius: 30,
                                                    ),
                                                  ),
                                                ),
                                                Flexible(
                                                  child: DefaultTextStyle(
                                                    child: Text(
                                                      response['data']
                                                          ['b_12_nama'],
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                    ),
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                Flexible(
                                                  child: DefaultTextStyle(
                                                    child: Text(
                                                      'Masa kerja > 12 bulan',
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                    ),
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Positioned(
                                            top: 10,
                                            right: 15,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Container(
                                                  child: Image(
                                                    image: AssetImage(
                                                        'assets/gold-medal.png'),
                                                    width: 70,
                                                    height: 70,
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 10,
                                                  child: DefaultTextStyle(
                                                    child: Text('Booking'),
                                                    style: TextStyle(
                                                      color: Colors.black54,
                                                      fontSize: 8,
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 18,
                                                  child: DefaultTextStyle(
                                                    child: Text(
                                                        response['data']
                                                            ['b_12_booking']),
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 120,
                                    width:
                                        (MediaQuery.of(context).size.width /
                                            2.5),
                                    child: Card(
                                      semanticContainer: true,
                                      elevation: 0,
                                      color: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                2.5,
                                            padding: EdgeInsets.all(5),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.only(
                                                      right: 30),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    padding:
                                                        EdgeInsets.all(2.5),
                                                    child: CircleAvatar(
                                                      backgroundImage:
                                                          NetworkImage(
                                                        Endpoint.baseIp +
                                                            '/' +
                                                            response['data'][
                                                                'b_612_photo'],
                                                      ),
                                                      radius: 30,
                                                    ),
                                                  ),
                                                ),
                                                Flexible(
                                                  child: DefaultTextStyle(
                                                    child: Text(
                                                      response['data']
                                                          ['b_612_nama'],
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                    ),
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                Flexible(
                                                  child: DefaultTextStyle(
                                                    child: Text(
                                                      'Masa kerja 6-12 bulan',
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                    ),
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Positioned(
                                            top: 10,
                                            right: 15,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Container(
                                                  child: Image(
                                                    image: AssetImage(
                                                        'assets/gold-medal.png'),
                                                    width: 70,
                                                    height: 70,
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 10,
                                                  child: DefaultTextStyle(
                                                    child: Text('Booking'),
                                                    style: TextStyle(
                                                      color: Colors.black54,
                                                      fontSize: 8,
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 18,
                                                  child: DefaultTextStyle(
                                                    child: Text(response[
                                                            'data']
                                                        ['b_612_booking']),
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Container(
                                    height: 120,
                                    width:
                                        (MediaQuery.of(context).size.width /
                                            2.5),
                                    child: Card(
                                      semanticContainer: true,
                                      elevation: 0,
                                      color: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                2.5,
                                            padding: EdgeInsets.all(5),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.only(
                                                      right: 30),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    padding:
                                                        EdgeInsets.all(2.5),
                                                    child: CircleAvatar(
                                                      backgroundImage:
                                                          NetworkImage(
                                                        Endpoint.baseIp +
                                                            '/' +
                                                            response['data'][
                                                                'b_35_photo'],
                                                      ),
                                                      radius: 30,
                                                    ),
                                                  ),
                                                ),
                                                Flexible(
                                                  child: DefaultTextStyle(
                                                    child: Text(
                                                      response['data']
                                                          ['b_35_nama'],
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                    ),
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                Flexible(
                                                  child: DefaultTextStyle(
                                                    child: Text(
                                                      'Masa kerja 3-5 bulan',
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                    ),
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Positioned(
                                            top: 10,
                                            right: 15,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Container(
                                                  child: Image(
                                                    image: AssetImage(
                                                        'assets/gold-medal.png'),
                                                    width: 70,
                                                    height: 70,
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 10,
                                                  child: DefaultTextStyle(
                                                    child: Text('Booking'),
                                                    style: TextStyle(
                                                      color: Colors.black54,
                                                      fontSize: 8,
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 18,
                                                  child: DefaultTextStyle(
                                                    child: Text(
                                                        response['data']
                                                            ['b_35_booking']),
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 120,
                                    width:
                                        (MediaQuery.of(context).size.width /
                                            2.5),
                                    child: Card(
                                      semanticContainer: true,
                                      elevation: 0,
                                      color: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15),
                                      ),
                                      child: response['data']['b_02_photo'] !=
                                              ''
                                          ? Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Container(
                                                  width:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width /
                                                          2.5,
                                                  padding: EdgeInsets.all(5),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Container(
                                                        padding:
                                                            EdgeInsets.only(
                                                                right: 30),
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                Colors.white,
                                                            shape: BoxShape
                                                                .circle,
                                                          ),
                                                          padding:
                                                              EdgeInsets.all(
                                                                  2.5),
                                                          child: CircleAvatar(
                                                            backgroundImage:
                                                                NetworkImage(
                                                              Endpoint.baseIp +
                                                                  '/' +
                                                                  response[
                                                                          'data']
                                                                      [
                                                                      'b_02_photo'],
                                                            ),
                                                            radius: 30,
                                                          ),
                                                        ),
                                                      ),
                                                      Flexible(
                                                        child:
                                                            DefaultTextStyle(
                                                          child: Text(
                                                            response['data']
                                                                ['b_02_nama'],
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          style: TextStyle(
                                                            color:
                                                                Colors.white,
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold,
                                                          ),
                                                        ),
                                                      ),
                                                      Flexible(
                                                        child:
                                                            DefaultTextStyle(
                                                          child: Text(
                                                            'Masa kerja 0-2 bulan',
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          style: TextStyle(
                                                            color:
                                                                Colors.white,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 10,
                                                  right: 15,
                                                  child: Stack(
                                                    alignment:
                                                        Alignment.center,
                                                    children: [
                                                      Container(
                                                        child: Image(
                                                          image: AssetImage(
                                                              'assets/gold-medal.png'),
                                                          width: 70,
                                                          height: 70,
                                                        ),
                                                      ),
                                                      Positioned(
                                                        top: 10,
                                                        child:
                                                            DefaultTextStyle(
                                                          child:
                                                              Text('Booking'),
                                                          style: TextStyle(
                                                            color: Colors
                                                                .black54,
                                                            fontSize: 8,
                                                          ),
                                                        ),
                                                      ),
                                                      Positioned(
                                                        top: 18,
                                                        child:
                                                            DefaultTextStyle(
                                                          child: Text(response[
                                                                  'data'][
                                                              'b_02_booking']),
                                                          style: TextStyle(
                                                            color:
                                                                Colors.black,
                                                            fontSize: 17,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Padding(
                                              padding:
                                                  const EdgeInsets.all(5),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    padding:
                                                        EdgeInsets.all(2.5),
                                                    child: CircleAvatar(
                                                      backgroundColor:
                                                          Colors.grey,
                                                      child: Icon(
                                                        Icons.person,
                                                        size: 40,
                                                        color: Colors.white,
                                                      ),
                                                      radius: 30,
                                                    ),
                                                  ),
                                                  Flexible(
                                                    child: DefaultTextStyle(
                                                      child: Text(''),
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  Flexible(
                                                    child: DefaultTextStyle(
                                                      child: Text(
                                                        'Masa kerja 0-2 bulan',
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                _profileBloc.add(InitialProfile());
                                ProfileController().getProfil(userID, date, _profileBloc, apiToken);
                              },
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color:
                                      Colors.lightBlue[50]!.withOpacity(0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.grey,
                                  size: 17,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }


  Future<void> setKondisi(state) async {
    setState(() {
      userID = state.userId;
      idShift = state.idShift;
      responseTime = state.responseTime;
    });
    if (state.idShift != '3') {
      // Selain Security
      if (state.clockIn != dateId) {
        if (state.clockIn == "--:--") {
          setState(() {
            _isCheckin = false;
          });

          setState(() {
            statusPhoto = false;
            statusIcon = true;
            imageUrl = "";
            _colorButton = Colors.red;
            clockout = state.clockOut;
            clockin = state.clockIn;
            _visibleButton = true;
            _status = "checkin";
            shift = state.shiftIn;
          });

          //kondisi belum checkin
        } else if (state.clockOut == "--:--") {
          if (_isCheckin == true) {
            setState(() {
              // _isCheckout = false;
            });
          }

          setState(() {
            clockin = state.clockIn;
            clockout = state.clockOut;
            statusPhoto = true;
            statusIcon = false;
            imageUrl = state.photoIn;
            _colorButton = Colors.deepOrange;
            _visibleButton = true;
            _status = "checkout";
            shift = state.shiftOut;
          });
        } else {
          //kondisi sudah checkin & belum checkout
          if (state.clockIn != "--:--" && state.clockOut != "--:--") {
            //kondisi sudah checkin & sudah checkout
            setState(() {
              clockin = state.clockIn;
              clockout = state.clockOut;
              statusPhoto = true;
              statusIcon = false;
              imageUrl = state.photoIn;
              _colorButton = Colors.red;
              _visibleButton = false;
              _status = "checkin";
              shift = state.shiftIn;
            });
          }
        }
      }
    } else {
      //KONDISI SIFT 3

      if (state.clockIn == "--:--" && state.clockOut == "--:--") {
        setState(() {
          _isCheckin = false;
          // _isCheckout = false;
        });

        setState(() {
          statusPhoto = false;
          statusIcon = true;
          imageUrl = "";
          _colorButton = Colors.red;
          clockout = state.clockOut;
          clockin = state.clockIn;
          _visibleButton = true;
          _status = "checkin";
          shift = state.shiftIn;
        });

        //kondisi belum checkin
      } else if (state.clockIn != "--:--" && state.clockOut == "--:--") {
        if (_isCheckin == true) {
          setState(() {
            // _isCheckout = false;
          });
        }

        setState(() {
          clockin = state.clockIn;
          clockout = state.clockOut;
          statusPhoto = true;
          statusIcon = false;
          imageUrl = state.photoIn;
          _colorButton = Colors.deepOrange;
          _visibleButton = true;
          _status = "checkout";
          shift = state.shiftOut;
        });
      } else if (dateOut != dateId) {
        //kondisi sudah checkin & belum checkout
        setState(() {
          clockin = state.clockIn;
          clockout = state.clockOut;
          dateOut = "";
          dateIn = "";
          statusPhoto = true;
          statusIcon = false;
          imageUrl = state.photoIn;
          _colorButton = Colors.red;
          _visibleButton = true;
          _status = "checkin";
          shift = state.shiftIn;
        });
      } else {
        //kondisi tanggal checkout tidak sama dengan tgl hari ini
        setState(() {
          statusPhoto = true;
          statusIcon = false;
          clockin = state.clockIn;
          clockout = state.clockOut;
          imageUrl = state.photoIn;
          _visibleButton = true;
          _status = "checkin";
          shift = state.shiftIn;
        });
      }
    }

    // QUIZ
    setState(() {
      state.quizRequired == "1"
          ? state.quizStatus == '1'
          ? isQuizPasses = true
          : isQuizPasses = false
          : isQuizPasses = true;
    });

    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setBool('isQuizPasses', isQuizPasses);

    print('state.quizRequired : ${state.quizRequired.toString()}');
    print('state.quizStatus : ${state.quizStatus.toString()}');
    print('isQuizPasses : ${isQuizPasses.toString()}');

  }

  Future<void> updateFcmToken(userId, firebaseAppToken, state) async {
    // showProgressDialog(context);
    String ip;
    final dbHelper = DatabaseHelper.instance;
    final allRows = await dbHelper.queryAllRows();

    if (allRows.length != 0) {
      allRows.forEach((row) => print(row));
      ip = allRows[0]['ip_address'];
    } else {
      ip = Endpoint.baseUrl;
    }

    // print(ip);

    var response = await services.updateFcmToken(ip, userId, firebaseAppToken, apiToken);
    print(response.toString());
    if(response['status'] == true){

      // print('ip: ${ip.toString()}');
      // print('userId: $userId');
      // print('firebaseAppToken: $firebaseAppToken');

      RegExp pattern = RegExp(r'[!@#$%^&*()_+={}|\[\]:;"<>,.?/~` \t\n\r\f\v]');
      // state.allDepartments.forEach((dept) async {
      //   // print(dept.replaceAll(pattern, ''));
      //   await AwesomeNotificationsFcm().unsubscribeToTopic(dept.replaceAll(pattern, ''));
      // });

      await AwesomeNotificationsFcm().subscribeToTopic(state.departmentName.replaceAll(pattern, ''));
      // print('departmentName: ${state.departmentName.replaceAll(pattern, '')}');

      SharedPreferences pref = await SharedPreferences.getInstance();
      pref.setString('fcmToken', firebaseAppToken);
    }

  }

  Future showProgressDialog(BuildContext loadContext) {
    return showDialog(
      context: loadContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Future<void> showSuccessDialog(context, status) async {
    String title = '';
    if (status == 'checkin') {
      title = "Check In Success ";
    } else {
      title = "Check Out Success ";
    }

    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.bottomSlide,
      title: title,
      // desc: 'Ingin istirahat sekarang?',
      // btnCancelText: "Nanti",
      // btnOkText: "Ya",
      // btnCancelOnPress: () {},
      btnOkOnPress: () {
        if (status == 'checkin') {
          setState(() {
            isShowSuccessCheckin = true;
          });
          checkHolidays();
        } else {
          setState(() {
            isShowSuccessCheckout = true;
          });

          // 120 = Departement Marketing RSP
          if (departmentId == '120') {
            getBestMktRsp(context);
          } else {
            checkBestBadEmployee(context);
          }
        }
      },
      dismissOnBackKeyPress: false,
      dismissOnTouchOutside: false,
    )..show();

  }

  Future<void> showHariBesar(lottie, title, message) async {
    isShowHariBesar = true;
    return Dialogs.materialDialog(
      color: Colors.white,
      msg: message,
      title: title,
      lottieBuilder: Lottie.network(
        Endpoint.urlLottie + lottie,
        fit: BoxFit.contain,
      ),
      context: context,
      actions: [
        IconsButton(
          onPressed: () {
            Navigator.of(context).pop();

            // 120 = Departement Marketing RSP
            if (departmentId == '120') {
              getBestMktRsp(context);
            } else {
              checkBestBadEmployee(context);
            }
          },
          text: '',
          iconData: Icons.done,
          color: Colors.blue,
          textStyle: TextStyle(color: Colors.white),
          iconColor: Colors.white,
        ),
      ],
    );
  }

  Future<void> showErrorDialog(context, status) async {
    String title = '';
    if (status == 'checkin') {
      title = "Check In Failed";
    } else {
      title = "Check Out Failed";
    }

    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.bottomSlide,
      title: title,
      // desc: 'Ingin istirahat sekarang?',
      // btnCancelText: "Nanti",
      // btnOkText: "Ya",
      // btnCancelOnPress: () {},
      btnCancelOnPress: () {
        _profileBloc.add(InitialProfile());
        ProfileController().getProfil(userID, date, _profileBloc, apiToken);
      },
    )..show();
  }

  Future<void> logout() async {
    _profileBloc.add(InitialProfile());
    removePref();
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pushNamedAndRemoveUntil(
          context, "/login", (Route<dynamic> routes) => false);
    });
  }

  Future<void> absen() async {
    Future.delayed(const Duration(microseconds: 2000), () {
      Navigator.pushNamedAndRemoveUntil(
          context, "/profile", (Route<dynamic> routes) => false);
    });
  }

  Future<void> goToHR(context) async {
    Navigator.pushNamed(context, "/hrsystem",
        arguments: PassParams(username, password));
  }

  Future<void> goToTrusmiverse(context) async {
    String pwd = md5.convert(utf8.encode(password)).toString();
    try {
      final response = await services.trusmiverseLogin(username, pwd, apiToken);
      print(jsonDecode(response.data)['link'].toString());
      String url = jsonDecode(response.data)['link'].toString();
      String token = jsonDecode(response.data)['token'].toString();
      Get.to(() => Trusmiverse(url: url, token: token));
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> wfh(context) async {
    Navigator.pushNamed(context, "/wfh",
        arguments: PassParams(username, password));
  }

  Future<void> removePref() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      pref.remove('fcmToken');
      pref.remove('username');
      pref.remove('password');
      pref.remove('clock_in');
      pref.remove('isQuizPasses');
    });

    await AwesomeNotificationsFcm().deleteToken();

  }

  Future<void> checkStatus(userId) async {
    showProgressDialog(context);

    String ip;
    final dbHelper = DatabaseHelper.instance;
    final allRows = await dbHelper.queryAllRows();

    if (allRows.length != 0) {
      ip = allRows[0]['ip_address'];
    } else {
      ip = Endpoint.baseUrl;
    }

    try {
      var response = await services.checkStatus(ip, userID, responseTime);

      // print('responseTime = ' + responseTime.toString());

      if (response.data.aktif.isEmpty) {
        Future.delayed(const Duration(microseconds: 2000), () {
          Navigator.pushNamedAndRemoveUntil(
              context, "/no_connection", (Route<dynamic> routes) => false);
        });
      } else {
        Navigator.of(context, rootNavigator: true).pop(context);

        if (response.data.aktif == '1') {
          if (response.data.achive == true) {
            if (clockin != '--:--') {
              if (isQuizPasses) {
                // ProfileController().openCamera(_status, userID, date, idShift, shift, _profileBloc, apiToken);
                Get.to(FaceCameraWidget(statusCheckin: _status, userId: userID, idShift: idShift, shift: shift));
              } else {
                _showQuiz();
                // Get.offAll(() => QuizScreen());
              }
            } else {
              // ProfileController().openCamera(_status, userID, date, idShift, shift, _profileBloc, apiToken);
              // Navigator.pushNamed(context, '/face_camera');
              Get.to(FaceCameraWidget(statusCheckin: _status, userId: userID, idShift: idShift, shift: shift));
            }
          } else {
            AwesomeDialog(
              context: context,
              dialogType: DialogType.error,
              title: "Anda tidak bisa melakukan absen!",
              desc: response.data.message,
              btnOkText: "Kembali",
              btnOkOnPress: () {
                Future.delayed(const Duration(microseconds: 2000), () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, "/profile", (Route<dynamic> routes) => false);
                });
              },
            )..show();
          }
        } else {
          AwesomeDialog(
            context: context,
            dialogType: DialogType.error,
            title: "Anda tidak bisa melakukan absen!",
            desc: "Akun anda telah dinonaktifkan.",
            btnOkText: "Logout",
            btnOkOnPress: () {
              logout();
            },
          )..show();
        }
      }
    } catch (_) {
      // ToastUtils.show('Request Time Out. Please try again!');
      Fluttertoast.showToast(
        msg: 'Request Time Out. Please try again!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        // backgroundColor: Colors.red,
        // textColor: Colors.white,
        // fontSize: 16.0,
      );
      Navigator.pop(context);
    }
  }

  Future<void> _showQuiz() async {
    Future<void> future = showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      enableDrag: true,
      builder: (context) => QuizScreen(),
    );

    future.then((value) => _closeQuiz(value));
  }

  Future<void> _closeQuiz(void value) async {
    var pref = await SharedPreferences.getInstance();
    if (pref.containsKey('isQuizPasses')) {
      setState(() {
        isQuizPasses = pref.getBool('isQuizPasses')!;
      });
    } else {
      setState(() {
        isQuizPasses = false;
      });
    }
    if (isQuizPasses) {
      // ProfileController().openCamera(_status, userID, date, idShift, shift, _profileBloc, apiToken);
      Get.to(FaceCameraWidget(statusCheckin: _status, userId: userID, idShift: idShift, shift: shift));
    }
  }


  @override
  void dispose() {
    if (!mounted) {
      _connectivitySubscription.cancel();
      timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String version = About.version;

    return SmartRefresher(
      enablePullDown: true,
      enablePullUp: false,
      header: WaterDropMaterialHeader(
        backgroundColor: Colors.red,
      ),
      controller: _refreshController,
      onRefresh: _onRefresh,
      onLoading: _onLoading,
      child: BlocProvider(
        create: (BuildContext context) => ProfileBloc(),
        child: BlocListener<ProfileBloc, ProfileState>(
          bloc: _profileBloc,
          listener: (context, state) async {
            // print('listener status =>' + state.status.toString());
            switch (state.status) {
              case ProfileStatus.success:
                // Navigator.of(context, rootNavigator: true).pop(context);
                setKondisi(state);

                // if(deleteToken == true){
                  updateFcmToken(userID, firebaseAppToken, state);
                // }


                break;
              case ProfileStatus.failure:
                // Navigator.of(context, rootNavigator: true).pop(context);
                // print('listener failure ');
                Future.delayed(const Duration(microseconds: 2000), () {
                  Navigator.pushNamedAndRemoveUntil(context, "/no_connection",
                      (Route<dynamic> routes) => false);
                });
                break;
              default:
                // showProgressDialog(context);
                getPref();
            }
          },
          child: BlocBuilder<ProfileBloc, ProfileState>(
            bloc: _profileBloc,
            builder: (context, state) {
              switch (state.status) {
                case ProfileStatus.initial:
                  return Scaffold(
                    appBar: AppBar(
                      title: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/logo_png_ontime.png',
                              fit: BoxFit.contain,
                              width: MediaQuery.of(context).size.width / 4,
                              height: MediaQuery.of(context).size.height / 14,
                            ),
                            Container(
                              padding: const EdgeInsets.fromLTRB(0, 0, 50, 0),
                            )
                          ]),
                      iconTheme: new IconThemeData(color: Colors.white),
                      flexibleSpace: Container(
                        decoration: new BoxDecoration(
                          gradient: new LinearGradient(
                            colors: [
                              const Color(0xFFFF1744),
                              const Color(0xFFF44336)
                            ],
                            begin: const FractionalOffset(0.0, 0.0),
                            end: const FractionalOffset(1.0, 0.0),
                            stops: [0.0, 1.0],
                            tileMode: TileMode.clamp,
                          ),
                        ),
                      ),
                    ),
                    drawer: Drawer(
                      elevation: 1.5,
                    ),
                    body: LayoutBuilder(builder: (BuildContext context,
                        BoxConstraints viewportConstraints) {
                      String networkImageUrl =
                          Endpoint.urlFoto + '/' + imageUrl;
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                              minHeight: viewportConstraints.maxHeight),
                          child: Column(
                            children: <Widget>[
                              Container(
                                width: MediaQuery.of(context).size.width,
                                height:
                                    (MediaQuery.of(context).size.height / 1.5),
                                decoration: BoxDecoration(
                                    image: DecorationImage(
                                        image: AssetImage(
                                            'assets/background_new.png'),
                                        fit: BoxFit.cover)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: <Widget>[
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.09),
                                    Container(
                                      width: 300.0,
                                      height: 300.0,
                                      decoration: new BoxDecoration(
                                        color: Colors.lightBlue[50]!
                                            .withOpacity(0.25),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Column(
                                        children: <Widget>[
                                          SizedBox(height: 20),
                                          Visibility(
                                            visible: statusPhoto,
                                            child: CachedNetworkImage(
                                              imageUrl: networkImageUrl,
                                              imageBuilder:
                                                  (context, imageProvider) =>
                                                      Container(
                                                width: 150.0,
                                                height: 150.0,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  image: DecorationImage(
                                                    image: imageProvider,
                                                    fit: BoxFit.cover,
                                                    colorFilter:
                                                        ColorFilter.mode(
                                                            Colors.grey,
                                                            BlendMode.dst),
                                                  ),
                                                  color: Colors.grey[300],
                                                ),
                                              ),
                                              placeholder: (context, url) =>
                                                  Container(
                                                width: 150.0,
                                                height: 150.0,
                                                decoration: new BoxDecoration(
                                                  color: Colors.grey[300],
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.person_outline,
                                                  color: Colors.white,
                                                  size: 120.0,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Visibility(
                                            visible: statusIcon,
                                            child: Container(
                                              width: 150.0,
                                              height: 150.0,
                                              decoration: new BoxDecoration(
                                                color: Colors.grey[300],
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.person_outline,
                                                color: Colors.white,
                                                size: 120.0,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                          Text(state.nama,
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold)),
                                          Text(state.jabatan,
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          SizedBox(height: 20),

                                          // StreamBuilder<DateTime>(
                                          //   stream: Stream.periodic(Duration(seconds: 1)),
                                          //   builder: (context, snapshot) {
                                          //     if (snapshot.hasData) {
                                          //       return Text(
                                          //         '${snapshot.data!.hour}:${snapshot.data!.minute}:${snapshot.data!.second}',
                                          //         style: TextStyle(color: Colors.white,
                                          //         fontSize: 25,
                                          //         fontWeight: FontWeight.bold),
                                          //       );
                                          //     } else {
                                          //       return Text('Loading...');
                                          //     }
                                          //   },
                                          // ),

                                          Text(_timeString.toString(),
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 25,
                                                  fontWeight: FontWeight.bold
                                                ),
                                              ),
                                          
                                          Text(_hariTanggal.toString(),
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12))
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      state.message,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    Expanded(child: SizedBox()),
                                    // Padding(
                                    //   padding:
                                    //       const EdgeInsets.only(bottom: 15.0),
                                    //   child: Row(
                                    //     mainAxisAlignment:
                                    //         MainAxisAlignment.center,
                                    //     children: [
                                    //       Visibility(
                                    //         visible: state.statusBreak == '1'
                                    //             ? true
                                    //             : false,
                                    //         child: Visibility(
                                    //           visible: state.clockIn == '--:--'
                                    //               ? false
                                    //               : true,
                                    //           child: Column(
                                    //             children: [
                                    //               Shimmer.fromColors(
                                    //                 baseColor: Colors.grey,
                                    //                 highlightColor:
                                    //                     Colors.white,
                                    //                 child: FloatingActionButton(
                                    //                   backgroundColor: state
                                    //                               .breakOut !=
                                    //                           ''
                                    //                       ? Colors.grey
                                    //                       : Color(0xff12cad6),
                                    //                   heroTag: 'breakOut',
                                    //                   onPressed: () {},
                                    //                   child: Text('Break\nOut',
                                    //                       textAlign:
                                    //                           TextAlign.center),
                                    //                   shape:
                                    //                       RoundedRectangleBorder(
                                    //                     borderRadius:
                                    //                         BorderRadius
                                    //                             .circular(10),
                                    //                   ),
                                    //                 ),
                                    //               ),
                                    //               Padding(
                                    //                 padding:
                                    //                     const EdgeInsets.only(
                                    //                         top: 8.0),
                                    //                 child: Shimmer.fromColors(
                                    //                   baseColor: Colors.grey,
                                    //                   highlightColor:
                                    //                       Colors.white,
                                    //                   child: SizedBox(
                                    //                       height: 5, width: 10),
                                    //                 ),
                                    //               ),
                                    //             ],
                                    //           ),
                                    //         ),
                                    //       ),
                                    //       SizedBox(
                                    //           width: MediaQuery.of(context)
                                    //                   .size
                                    //                   .width /
                                    //               3),
                                    //       Visibility(
                                    //         visible: state.statusBreak == '1'
                                    //             ? true
                                    //             : false,
                                    //         child: Visibility(
                                    //           visible: state.clockIn == '--:--'
                                    //               ? false
                                    //               : true,
                                    //           child: Column(
                                    //             children: [
                                    //               Shimmer.fromColors(
                                    //                 baseColor: Colors.grey,
                                    //                 highlightColor:
                                    //                     Colors.white,
                                    //                 child: FloatingActionButton(
                                    //                   backgroundColor: (state
                                    //                               .breakOut ==
                                    //                           '')
                                    //                       ? Colors.grey
                                    //                       : (state.breakIn !=
                                    //                               '')
                                    //                           ? Colors.grey
                                    //                           : Color(
                                    //                               0xff12cad6),
                                    //                   heroTag: 'breakIn',
                                    //                   onPressed: () {},
                                    //                   child: Text('Break\nIn',
                                    //                       textAlign:
                                    //                           TextAlign.center),
                                    //                   shape:
                                    //                       RoundedRectangleBorder(
                                    //                     borderRadius:
                                    //                         BorderRadius
                                    //                             .circular(10),
                                    //                   ),
                                    //                 ),
                                    //               ),
                                    //               Padding(
                                    //                 padding:
                                    //                     const EdgeInsets.only(
                                    //                         top: 8.0),
                                    //                 child: Shimmer.fromColors(
                                    //                   baseColor: Colors.grey,
                                    //                   highlightColor:
                                    //                       Colors.white,
                                    //                   child: SizedBox(
                                    //                       height: 5, width: 20),
                                    //                 ),
                                    //               ),
                                    //             ],
                                    //           ),
                                    //         ),
                                    //       ),
                                    //     ],
                                    //   ),
                                    // )
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                    left: 20, right: 20, top: 15),
                                child: Column(
                                  children: <Widget>[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: <Widget>[
                                        Column(children: <Widget>[
                                          Shimmer.fromColors(
                                            baseColor: Colors.grey,
                                            highlightColor: Colors.white,
                                            child: Container(
                                              margin:
                                                  EdgeInsets.only(bottom: 5),
                                              height: 15,
                                              width: 80,
                                              decoration: BoxDecoration(
                                                color: Colors.grey,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  15,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Shimmer.fromColors(
                                            baseColor: Colors.grey,
                                            highlightColor: Colors.white,
                                            child: Container(
                                              margin:
                                                  EdgeInsets.only(bottom: 5),
                                              height: 15,
                                              width: 50,
                                              decoration: BoxDecoration(
                                                color: Colors.grey,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  15,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Shimmer.fromColors(
                                            baseColor: Colors.grey,
                                            highlightColor: Colors.white,
                                            child: Container(
                                              margin:
                                                  EdgeInsets.only(bottom: 5),
                                              height: 15,
                                              width: 80,
                                              decoration: BoxDecoration(
                                                color: Colors.grey,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  15,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ]),
                                        Container(
                                          height: 10,
                                          width: 10,
                                        ),
                                        Column(children: <Widget>[
                                          Shimmer.fromColors(
                                            baseColor: Colors.grey,
                                            highlightColor: Colors.white,
                                            child: Container(
                                              margin:
                                                  EdgeInsets.only(bottom: 5),
                                              height: 15,
                                              width: 80,
                                              decoration: BoxDecoration(
                                                color: Colors.grey,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  15,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Shimmer.fromColors(
                                            baseColor: Colors.grey,
                                            highlightColor: Colors.white,
                                            child: Container(
                                              margin:
                                                  EdgeInsets.only(bottom: 5),
                                              height: 15,
                                              width: 50,
                                              decoration: BoxDecoration(
                                                color: Colors.grey,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  15,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Shimmer.fromColors(
                                            baseColor: Colors.grey,
                                            highlightColor: Colors.white,
                                            child: Container(
                                              margin:
                                                  EdgeInsets.only(bottom: 5),
                                              height: 15,
                                              width: 80,
                                              decoration: BoxDecoration(
                                                color: Colors.grey,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  15,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ]),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    }),

                    floatingActionButton: Visibility(
                      visible: _visibleButton,
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey,
                        highlightColor: Colors.white,
                        child: FloatingActionButton(
                          onPressed: () => {},
                          tooltip: _toolTip,
                          backgroundColor: _colorButton,
                          child: Icon(Icons.alarm_on,
                              color: Colors.white, size: 40),
                        ),
                      ),
                    ),
                    floatingActionButtonLocation:
                        FloatingActionButtonLocation.centerDocked,
                    bottomNavigationBar: BottomAppBar(
                      shape: const CircularNotchedRectangle(),
                      child: Container(height: 50.0),
                    ),
                  );
                default:
              }

              return Scaffold(
                appBar: AppBar(
                  title: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/logo_png_ontime.png',
                          fit: BoxFit.contain,
                          width: MediaQuery.of(context).size.width / 4,
                          height: MediaQuery.of(context).size.height / 14,
                        ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(0, 0, 50, 0),
                        )
                      ]),
                  iconTheme: new IconThemeData(color: Colors.white),
                  flexibleSpace: Container(
                    decoration: new BoxDecoration(
                        gradient: new LinearGradient(
                            colors: [
                              const Color(0xFFFF1744),
                              const Color(0xFFF44336)
                            ],
                            begin: const FractionalOffset(0.0, 0.0),
                            end: const FractionalOffset(1.0, 0.0),
                            stops: [0.0, 1.0],
                            tileMode: TileMode.clamp)),
                  ),
                ),
                drawer: Drawer(
                  elevation: 1.5,
                  child: Column(
                    children: <Widget>[
                      DrawerHeader(
                        padding: EdgeInsets.zero,
                        decoration: BoxDecoration(color: Colors.red[700]),
                        child: Row(
                          children: <Widget>[
                            SizedBox(width: 15),
                            new CircleAvatar(
                              radius: 30.0,
                              child: ClipOval(
                                // child: CachedNetworkImage(
                                //   imageUrl:
                                //       '${Endpoint.urlProfile}/${state.fotoProfil}',
                                //   imageBuilder: (context, imageProvider) =>
                                //       Container(
                                //     width: 60.0,
                                //     height: 60.0,
                                //     decoration: BoxDecoration(
                                //       shape: BoxShape.circle,
                                //       image: DecorationImage(
                                //         image: imageProvider,
                                //         fit: BoxFit.cover,
                                //         colorFilter: ColorFilter.mode(
                                //             Colors.grey, BlendMode.dst),
                                //       ),
                                //       color: Colors.grey[300],
                                //     ),
                                //   ),
                                //   placeholder: (context, url) =>
                                //       Shimmer.fromColors(
                                //     baseColor: Colors.grey,
                                //     highlightColor: Colors.white,
                                //     child: Container(
                                //       width: 60.0,
                                //       height: 60.0,
                                //       decoration: BoxDecoration(
                                //         shape: BoxShape.circle,
                                //         color: Colors.grey[300],
                                //       ),
                                //       child: Icon(Icons.person_outline_rounded),
                                //     ),
                                //   ),
                                //   errorWidget:
                                //(context, url, error) =>
                                //       Container(
                                //     width: 60.0,
                                //     height: 60.0,
                                //     decoration: BoxDecoration(
                                //       shape: BoxShape.circle,
                                //       color: Colors.grey[300],
                                //     ),
                                //     child: Icon(
                                //       Icons.person_outline_rounded,
                                //       size: 40,
                                //     ),
                                //   ),
                                // ),
                                child: Image.network(
                                  Endpoint.urlProfile + "/" + state.fotoProfil,
                                  width: 125,
                                  height: 125,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 60.0,
                                    height: 60.0,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey[300],
                                    ),
                                    child: Icon(
                                      Icons.person_outline_rounded,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),
                              backgroundColor: Colors.transparent,
                            ),
                            SizedBox(width: 10),
                            Flexible(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    state.nama,
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    state.jabatan,
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: <Widget>[
                            ListTile(
                                leading: Icon(Icons.alarm_on),
                                title: Text('Absen'),
                                onTap: () => absen()),
                            ListTile(
                                leading: Icon(Icons.add_to_home_screen),
                                title: Text('HR System'),
                                onTap: () => goToHR(context)),
                            ListTile(
                                leading: Icon(Icons.group_work_outlined),
                                title: Text('Trusmiverse'),
                                onTap: () => goToTrusmiverse(context)),
                            ListTile(
                                leading: Icon(Icons.account_balance),
                                title: Text('WFH'),
                                onTap: () => wfh(context)),
                            ListTile(
                                leading: Icon(Icons.exit_to_app),
                                title: Text('Log Out'),
                                onTap: () => logout())
                          ],
                        ),
                      ),
                      Container(
                        child: Align(
                          alignment: FractionalOffset.bottomCenter,
                          child: Container(
                            child: Column(
                              children: <Widget>[
                                Divider(),
                                ListTile(
                                  title: new Center(child: Text(version)),
                                )
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                body: LayoutBuilder(builder:
                    (BuildContext context, BoxConstraints viewportConstraints) {
                  String networkImageUrl = Endpoint.urlFoto + '/' + imageUrl;
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          minHeight: viewportConstraints.maxHeight),
                      child: Column(
                        children: <Widget>[
                          Container(
                            width: MediaQuery.of(context).size.width,
                            height: (MediaQuery.of(context).size.height / 1.5),
                            decoration: BoxDecoration(
                                image: DecorationImage(
                                    image:
                                        AssetImage('assets/background_new.png'),
                                    fit: BoxFit.cover)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.09),
                                Container(
                                  width: 300.0,
                                  height: 300.0,
                                  decoration: new BoxDecoration(
                                    color:
                                        Colors.lightBlue[50]!.withOpacity(0.25),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Column(
                                    children: <Widget>[
                                      SizedBox(height: 20),
                                      Visibility(
                                        visible: statusPhoto,
                                        child: Container(
                                          width: 150.0,
                                          height: 150.0,
                                          padding: EdgeInsets.all(2.5),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            shape: BoxShape.circle,
                                            image: DecorationImage(
                                              fit: BoxFit.cover,
                                              image: new NetworkImage(
                                                networkImageUrl,
                                              ),
                                            ),
                                          ),
                                          // child: CachedNetworkImage(
                                          //   imageUrl: networkImageUrl,
                                          //   errorWidget:
                                          //       (context, url, error) => Icon(
                                          //     Icons.person_outline,
                                          //     size: 100,
                                          //     color: Colors.grey,
                                          //   ),
                                          //   placeholder: (context, url) =>
                                          //       Shimmer.fromColors(
                                          //     child: Icon(
                                          //       Icons.person_outline,
                                          //       size: 100,
                                          //       color: Colors.grey,
                                          //     ),
                                          //     baseColor: Colors.grey,
                                          //     highlightColor: Colors.white,
                                          //   ),
                                          // ),
                                        ),
                                      ),
                                      Visibility(
                                        visible: statusIcon,
                                        child: Container(
                                          width: 150.0,
                                          height: 150.0,
                                          decoration: new BoxDecoration(
                                            color: Colors.grey[300],
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.person_outline,
                                            color: Colors.white,
                                            size: 120.0,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Text(state.nama,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                      Text(state.jabatan,
                                          style:
                                              TextStyle(color: Colors.white)),
                                      SizedBox(height: 20),

                                      
                                      Text(_timeString.toString(),
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 25,
                                              fontWeight: FontWeight.bold)),
                                      
                                      Text(_hariTanggal.toString(),
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12))
                                    ],
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  state.message,
                                  style: TextStyle(color: Colors.white),
                                ),
                                Expanded(child: SizedBox()),

                              ],
                            ),
                          ),
                          Padding(
                            padding:
                                EdgeInsets.only(left: 20, right: 20, top: 15),
                            child: Column(
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    Column(children: <Widget>[
                                      Text("Start Time",
                                          style: TextStyle(fontSize: 18)),
                                      Text(clockin.toString(),
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                      Text(
                                        state.dateIn,
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ]),
                                    Container(
                                      height: 10,
                                      width: 10,
                                    ),
                                    Column(children: <Widget>[
                                      Text("End Time",
                                          style: TextStyle(fontSize: 18)),
                                      Text(state.clockOut,
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                      Text(
                                        state.dateOut,
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ]),
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                }),
                floatingActionButton: Visibility(
                  visible: _visibleButton,
                  child: FloatingActionButton(
                    onPressed: () async {
                      checkStatus(userID);
                      // NotificationController.createNewNotification(context),
                    },
                    tooltip: _toolTip,
                    backgroundColor: _colorButton,
                    child:
                        Icon(Icons.alarm_on, color: Colors.white, size: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30.0))
                    ),
                  ),
                ),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.centerDocked,
                bottomNavigationBar: AnimatedBottomNavigationBar(
                    icons: [
                      // Icon(Icons.alarm_on, color: Colors.white, size: 40),
                      Icons.logout,
                      Icons.notifications_active_rounded,
                    ],
                  activeIndex: 1,
                  onTap: (int ) {
                    checkStatus(userID);
                    setState(() {

                    });
                  },
                  gapLocation: GapLocation.center,
                  notchSmoothness: NotchSmoothness.defaultEdge,
                ),

                // BottomAppBar(
                //   shape: const CircularNotchedRectangle(),
                //   child: Container(height: 60.0),
                //   // child: Padding(
                //   //   padding: const EdgeInsets.all(8.0),
                //   //   child: Row(
                //   //     mainAxisSize: MainAxisSize.max,
                //   //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   //     children: [
                //   //       Wrap(
                //   //         crossAxisAlignment: WrapCrossAlignment.center,
                //   //         direction: Axis.vertical,
                //   //         children: [
                //   //           IconButton(
                //   //             onPressed: () {},
                //   //             icon: Icon(
                //   //               Icons.add_to_home_screen_outlined,
                //   //               size: 30,
                //   //             ),
                //   //             color: Colors.grey,
                //   //           ),
                //   //           Text(
                //   //             "HR System",
                //   //             style: TextStyle(fontSize: 10),
                //   //           ),
                //   //         ],
                //   //       ),
                //   //       Wrap(
                //   //         crossAxisAlignment: WrapCrossAlignment.center,
                //   //         direction: Axis.vertical,
                //   //         children: [
                //   //           IconButton(
                //   //             onPressed: () {},
                //   //             icon: Icon(
                //   //               Icons.group_work_outlined,
                //   //               size: 30,
                //   //             ),
                //   //             color: Colors.grey,
                //   //           ),
                //   //           Text(
                //   //             "Trusmiverse",
                //   //             style: TextStyle(fontSize: 10),
                //   //           ),
                //   //         ],
                //   //       ),
                //   //       Padding(padding: EdgeInsets.symmetric(horizontal: 25)),
                //   //       Wrap(
                //   //         crossAxisAlignment: WrapCrossAlignment.center,
                //   //         direction: Axis.vertical,
                //   //         children: [
                //   //           IconButton(
                //   //             onPressed: () {},
                //   //             icon: Icon(
                //   //               Icons.account_balance,
                //   //               size: 30,
                //   //             ),
                //   //             color: Colors.grey,
                //   //           ),
                //   //           Text(
                //   //             "WFH",
                //   //             style: TextStyle(fontSize: 10),
                //   //           ),
                //   //         ],
                //   //       ),
                //   //       Wrap(
                //   //         crossAxisAlignment: WrapCrossAlignment.center,
                //   //         direction: Axis.vertical,
                //   //         children: [
                //   //           IconButton(
                //   //             onPressed: () {},
                //   //             icon: Icon(
                //   //               Icons.exit_to_app,
                //   //               size: 30,
                //   //             ),
                //   //             color: Colors.grey,
                //   //           ),
                //   //           Text(
                //   //             "Logout",
                //   //             style: TextStyle(fontSize: 10),
                //   //           ),
                //   //         ],
                //   //       ),
                //   //     ],
                //   //   ),
                //   // ),
                // ),
              );
            },
          ),
        ),
      ),
    );
  }

}
