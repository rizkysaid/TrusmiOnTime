import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:login_absen/core/bloc/profile/profile_bloc.dart';
import 'package:login_absen/core/config/endpoint.dart';
import 'package:login_absen/core/config/about.dart';
import 'package:login_absen/core/database/database_helper.dart';
import 'package:login_absen/core/models/ProfileModel.dart';
import 'package:login_absen/core/services/ApiService.dart';
import 'package:login_absen/core/ui/screens/quiz_screen.dart';
import 'package:login_absen/core/ui/screens/trusmiverse.dart';
import 'package:login_absen/core/utils/toast_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'PassParams.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:date_format/date_format.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:material_dialogs/material_dialogs.dart';
import 'package:material_dialogs/widgets/buttons/icon_button.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

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
  // static String totalWork = '';
  String _status = '';
  bool _isCheckin = false;
  // bool _isCheckout = false;
  bool statusPhoto = false;
  bool statusIcon = true;
  bool _visibleButton = true;
  // bool statusTotalWork = false;
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

  String prevMonthName = '';

  int responseTime = 15;

  String dateId = formatDate(DateTime.now(), [dd, '/', mm, '/', yy]);

  File? imageFile;

  void _openCamera() async {
    // Capture a photo
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
      maxWidth: 500,
      maxHeight: 500,
      preferredCameraDevice: CameraDevice.front,
    );

    // setState(() {
    // imageFile!.copy(pickedFile!.path);

    var picker = pickedFile;
    if (picker != null) {
      imageFile = File(pickedFile!.path);
    } else {
      imageFile = null;
      getProfil(userID, date);
    }

    // PROSES CHECKIN / CHECKOUT
    var image = imageFile;
    if (image != null) {
      _profileBloc.add(InitialProfile());
      if (_status == 'checkin') {
        prosesCheckin(userID, '${DateTime.now()}', imageFile!, idShift, shift);
      } else {
        prosesCheckout(userID, '${DateTime.now()}', imageFile!, idShift, shift);
      }
    }
  }

  bool isShowSuccessCheckin = false;
  bool isShowSuccessCheckout = false;

  late bool isQuizPasses;

  Future<void> prosesCheckin(String usrId, String clockIn, File imageFile,
      String idShift, String shift) async {
    var uri = Uri.parse(Endpoint.checkin);
    // print('Endpoint.checkin => ' + Endpoint.checkin);
    var request = new http.MultipartRequest("POST", uri);
    var multiPartFile = new http.MultipartFile.fromBytes(
      "foto",
      imageFile.readAsBytesSync(),
      filename: imageFile.path,
    );

    request.files.add(multiPartFile);
    request.fields['employee_id'] = usrId;
    request.fields['clock_in'] = clockIn;
    request.fields['id_shift'] = idShift;
    request.fields['shift'] = shift;

    var response = await request.send();

    // print('usrId => ' + usrId);
    // print('clockIn => ' + clockIn);
    // print('idShift => ' + idShift);
    // print('shift => ' + shift);

    // print('proses checkin => ' + response.statusCode.toString());
    // print('proses checkin => ' + response.toString());

    if (response.statusCode == 201) {
      showSuccessDialog(context, 'checkin');
    } else {
      showErrorDialog(context, 'checkin');
    }
  }

  Future<void> prosesCheckout(String usrId, String clockOut, File imageFile,
      String idShift, String shift) async {
    showProgressDialog(context);

    var uri = Uri.parse(Endpoint.checkout);
    var request = new http.MultipartRequest("POST", uri);

    var multiPartFile = new http.MultipartFile.fromBytes(
      "foto",
      imageFile.readAsBytesSync(),
      filename: imageFile.path,
    );

    request.files.add(multiPartFile);
    request.fields['employee_id'] = usrId;
    request.fields['clock_out'] = clockOut;
    request.fields['id_shift'] = idShift;
    request.fields['shift'] = shift;

    var response = await request.send();

    // print('response.status.checkout => ' + response.statusCode.toString());

    if (response.statusCode == 200) {
      // hide pop up
      Navigator.pop(context);
      showSuccessDialog(context, 'checkout');
    } else {
      showErrorDialog(context, 'checkout');
    }
  }

  // BREAK OUT
  Future<void> prosesBreakOut(
      String usrId, String breakOut, String idShift, String shift) async {
    _profileBloc.add(InitialProfile());

    var uri = Uri.parse(Endpoint.breakout);
    var request = new http.MultipartRequest("POST", uri);

    request.fields['employee_id'] = usrId;
    request.fields['break_out'] = breakOut;
    request.fields['id_shift'] = idShift;
    request.fields['shift'] = shift;

    var response = await request.send();

    // print('response.status.breakout => ' + response.statusCode.toString());

    if (response.statusCode == 200) {
      // timer = new Timer(new Duration(seconds: 2), () {
      getProfil(usrId, date);
      ToastUtils.show(
          "Selamat istirahat, manfaatkan waktu istirahatmu dengan baik");
      // });
    } else {
      print(response.statusCode);
    }
  }

  // BREAK OUT
  Future<void> prosesBreakIn(
      String usrId, String breakIn, String idShift, String shift) async {
    _profileBloc.add(InitialProfile());
    var uri = Uri.parse(Endpoint.breakin);
    var request = new http.MultipartRequest("POST", uri);

    request.fields['employee_id'] = usrId;
    request.fields['break_in'] = breakIn;
    request.fields['id_shift'] = idShift;
    request.fields['shift'] = shift;

    var response = await request.send();

    print('response.status.breakout => ' + response.statusCode.toString());

    if (response.statusCode == 200) {
      // timer = new Timer(new Duration(seconds: 2), () {
      getProfil(usrId, date);
      ToastUtils.show("Selamat bekerja kembali");
      // });
    } else {
      print(response.statusCode);
    }
  }

  List<ProfileModel> productProfile = [];
  final ProfileBloc _profileBloc = ProfileBloc();

  @override
  void initState() {
    super.initState();
    // _profileBloc.add(InitialProfile());
    // getPref();
    // _onRefresh();

    initConnectivity();

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

    _timeString = _formatDateTime(DateTime.now());
    _hariTanggal = _formatHariTanggal(DateTime.now());
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      final DateTime now = DateTime.now();
      final DateTime htNow = DateTime.now();
      final String formattedDateTime = _formatDateTime(now);
      final String formattedHariTanggal = _formatHariTanggal(htNow);

      _hariTanggal = formattedHariTanggal;
      _timeString = formattedDateTime;
      if (this.mounted) {
        setState(() {
          _timeString = formattedDateTime;
        });
      }
    });
  }

  Future<void> initConnectivity() async {
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
          // _profileBloc.add(InitialProfile());
          getPref();
          // _onRefresh();
        }
      } else {
        // _profileBloc.add(InitialProfile());
        getPref();
        // _onRefresh();
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

  @override
  void dispose() {
    if (!mounted) {
      _connectivitySubscription.cancel();
      timer.cancel();
    }
    super.dispose();
  }

  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  void _onRefresh() async {
    await Future.delayed(Duration(milliseconds: 2000));
    _refreshController.refreshCompleted();
    _profileBloc.add(InitialProfile());
    getProfil(userID, date);
  }

  void _onLoading() async {
    await Future.delayed(Duration(milliseconds: 2000));

    _refreshController.loadComplete();
  }

  Future<void> getProfil(userID, date) async {
    _profileBloc.add(InitialProfile());
    String ip;
    final dbHelper = DatabaseHelper.instance;
    final allRows = await dbHelper.queryAllRows();

    if (allRows.length != 0) {
      ip = allRows[0]['ip_address'];
    } else {
      ip = Endpoint.baseUrl;
    }

    _profileBloc.add(
      GetProfile(
        ip: ip,
        userID: userID,
        date: date,
        apiToken: apiToken,
      ),
    );
  }

  Future<void> getPref() async {
    _profileBloc.add(InitialProfile());
    var pref = await SharedPreferences.getInstance();
    if (pref.getString('username') == null) {
      logout();
    } else {
      setState(() {
        username = pref.getString('username')!;
        password = pref.getString('password')!;
        userID = pref.getString('userID').toString();
        departmentId = pref.getString('departmentId').toString();
      });

      getProfil(userID, date);
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

  bool isShowHariBesar = false;
  bool statusHariBesar = false;
  String title = '';
  String msg = '';
  String gif = '';
  bool hariBesar = false;

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
        getProfil(userID, date);
      }
    } else {
      _profileBloc.add(InitialProfile());
      getProfil(userID, date);
    }
  }

  void _displayBestBadEmployees(BuildContext context, response) {
    showGeneralDialog(
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
          return WillPopScope(
            onWillPop: () {
              Navigator.pop(context);
              _profileBloc.add(InitialProfile());
              getProfil(userID, date);
              return Future.value(true);
            },
            child: SafeArea(
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
                                ? _singleBestEmployee(response)
                                : _prodevBestEmployee(response),
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
                          getProfil(userID, date);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

  Widget _singleBestEmployee(response) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
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
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.3,
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 15),
                      width: double.infinity,
                      child: Center(
                        child: DefaultTextStyle(
                          child: Text('Best Employee Of The Month'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 15, bottom: 10),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Column(
                                  children: [
                                    DefaultTextStyle(
                                      child: Text("Periode"),
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Container(
                                      child: Column(
                                        children: [
                                          DefaultTextStyle(
                                            child:
                                                Text(DateFormat('MMMM').format(
                                              DateTime(
                                                0,
                                                int.parse(
                                                  response['periode']
                                                      .substring(5, 7),
                                                ),
                                              ),
                                            )),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          DefaultTextStyle(
                                            child: Text(response['periode']
                                                .substring(0, 4)),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.fromLTRB(
                              20,
                              5,
                              20,
                              0,
                            ),
                            padding: EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              backgroundImage: NetworkImage(
                                Endpoint.baseIp +
                                    '/' +
                                    response['data']['best'][0]
                                        ['profile_picture'],
                              ),
                              radius: 45.0,
                              // child: CachedNetworkImage(
                              //     imageUrl:
                              //         '${Endpoint.baseIp}/${response['data']['best'][0]['profile_picture']}'),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Center(
                                child: Column(
                                  children: [],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    DefaultTextStyle(
                      child: Text(response['data']['best'][0]['employee']),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    DefaultTextStyle(
                      child: Text(response['data']['best'][0]['jabatan']),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
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
                    getProfil(userID, date);
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.lightBlue[50]!.withOpacity(0.25),
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
            Positioned(
              top: 70,
              right: 15,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    children: [
                      DefaultTextStyle(
                        child: Text("KPI"),
                        style: TextStyle(color: Colors.white),
                      ),
                      Image(
                        image: AssetImage('assets/gold-medal.png'),
                        width: 80,
                        height: 80,
                      ),
                    ],
                  ),
                  Positioned(
                    top: 32,
                    // left: 25,
                    child: Center(
                      child: DefaultTextStyle(
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        child: Text(
                          response['data']['best'][0]['score'],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(
          height: 20,
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 5),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(bottom: 5),
                width: double.infinity,
                child: Center(
                  child: Column(
                    children: [
                      DefaultTextStyle(
                        child: Text('Bad Employee Of The Month'),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: response['data']['bad'].length,
                itemBuilder: (context, index) {
                  return Card(
                    // elevation: 5,
                    // shape: RoundedRectangleBorder(
                    //   borderRadius: BorderRadius.circular(20),
                    // ),
                    child: ListTile(
                      // contentPadding: EdgeInsets.all(10),
                      // minVerticalPadding: 5,
                      leading: Container(
                        padding: EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(
                            Endpoint.baseIp +
                                '/' +
                                response['data']['bad'][index]
                                    ['profile_picture'],
                          ),
                          radius: 30,
                        ),
                      ),
                      title: Text(response['data']['bad'][index]['employee']),
                      subtitle: Text(response['data']['bad'][index]['jabatan']),
                      trailing: Stack(
                        alignment: Alignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 5.0),
                            child: Chip(
                              label: Text(
                                response['data']['bad'][index]['score'],
                                style: TextStyle(
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                'KPI',
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(fontSize: 9, color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _prodevBestEmployee(response) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
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
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(child: Container()),
                    Container(
                      width: double.infinity,
                      child: Center(
                        child: Column(
                          children: [
                            DefaultTextStyle(
                              child: Text('Best Employee Of The Month'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            DefaultTextStyle(
                              child: Text(
                                DateFormat('MMMM').format(
                                      DateTime(
                                        0,
                                        int.parse(
                                          response['periode'].substring(5, 7),
                                        ),
                                      ),
                                    ) +
                                    ' ' +
                                    response['periode'].substring(0, 4),
                              ),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(child: Container()),
                    Container(
                      padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                      child: GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        scrollDirection: Axis.vertical,
                        childAspectRatio: 1.5,
                        children: List.generate(
                          response['data']['best'].length,
                          (index) {
                            return Card(
                              elevation: 0,
                              color: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width / 2.5,
                                    padding: EdgeInsets.all(5),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.only(right: 30),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            padding: EdgeInsets.all(2.5),
                                            child: CircleAvatar(
                                              backgroundImage: NetworkImage(
                                                Endpoint.baseIp +
                                                    '/' +
                                                    response['data']['best']
                                                            [index]
                                                        ['profile_picture'],
                                              ),
                                              radius: 30,
                                            ),
                                          ),
                                        ),
                                        DefaultTextStyle(
                                          child: Text(
                                            response['data']['best'][index]
                                                ['employee'],
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Flexible(
                                          child: DefaultTextStyle(
                                            child: Text(
                                              response['data']['best'][index]
                                                  ['jabatan'],
                                              overflow: TextOverflow.ellipsis,
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
                                            child: Text('KPI'),
                                            style: TextStyle(
                                              color: Colors.black54,
                                              fontSize: 8,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 18,
                                          child: DefaultTextStyle(
                                            child: Text(response['data']['best']
                                                [index]['score']),
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Expanded(child: Container()),
                  ],
                ),
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
                    getProfil(userID, date);
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.lightBlue[50]!.withOpacity(0.25),
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
        SizedBox(
          height: 10,
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 5),
          child: Column(
            children: [
              Container(
                // margin: EdgeInsets.only(bottom: 5),
                width: double.infinity,
                child: Center(
                  child: Column(
                    children: [
                      DefaultTextStyle(
                        child: Text('Bad Employee Of The Month'),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: response['data']['bad'].length,
                itemBuilder: (context, index) {
                  return Card(
                    // elevation: 3,
                    // shape: RoundedRectangleBorder(
                    //   borderRadius: BorderRadius.circular(20),
                    // ),
                    child: ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(1.5),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(
                            Endpoint.baseIp +
                                '/' +
                                response['data']['bad'][index]
                                    ['profile_picture'],
                          ),
                          radius: 20,
                        ),
                      ),
                      title: Text(response['data']['bad'][index]['employee']),
                      subtitle: Text(response['data']['bad'][index]['jabatan']),
                      trailing: Stack(
                        alignment: Alignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 5.0),
                            child: Chip(
                              label: Text(
                                response['data']['bad'][index]['score'],
                                style: TextStyle(
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                'KPI',
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(fontSize: 9, color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
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
      getProfil(userID, date);
    } else {
      _displayBestMktRsp(context, response);
    }
  }

  void _displayBestMktRsp(BuildContext context, response) {
    Navigator.pop(context);
    setState(() {
      prevMonthName = DateFormat('MMMM yyyy')
          .format(DateTime.now().subtract(Duration(days: 30)));
    });

    showGeneralDialog(
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
          return WillPopScope(
            onWillPop: () {
              Navigator.pop(context);
              _profileBloc.add(InitialProfile());
              getProfil(userID, date);
              return Future.value(true);
            },
            child: SafeArea(
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
                                  getProfil(userID, date);
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
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    String version = About.version;

    return SmartRefresher(
      enablePullDown: true,
      enablePullUp: false,
      header: WaterDropMaterialHeader(),
      controller: _refreshController,
      onRefresh: _onRefresh,
      onLoading: _onLoading,
      child: BlocProvider(
        create: (BuildContext context) => ProfileBloc(),
        child: BlocListener<ProfileBloc, ProfileState>(
          bloc: _profileBloc,
          listener: (context, state) {
            print('listener status =>' + state.status.toString());
            switch (state.status) {
              case ProfileStatus.success:
                Navigator.of(context, rootNavigator: true).pop(context);
                setKondisi(state);

                break;
              case ProfileStatus.failure:
                Navigator.of(context, rootNavigator: true).pop(context);
                print('listener failure ');
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
              // print('status buider => ' + state.status.toString());
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
                    bottomNavigationBar: BottomAppBar(
                      shape: const CircularNotchedRectangle(),
                      child: Container(height: 50.0),
                    ),
                    floatingActionButton: Visibility(
                      visible: _visibleButton,
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey,
                        highlightColor: Colors.white,
                        child: Container(
                            height: 80,
                            width: 80,
                            child: FloatingActionButton(
                              onPressed: () => {},
                              tooltip: _toolTip,
                              backgroundColor: _colorButton,
                              child: Icon(Icons.alarm_on,
                                  color: Colors.white, size: 40),
                            )),
                      ),
                    ),
                    floatingActionButtonLocation:
                        FloatingActionButtonLocation.centerDocked,
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
                                // Padding(
                                //   padding: const EdgeInsets.only(bottom: 15.0),
                                //   child: Row(
                                //     mainAxisAlignment: MainAxisAlignment.center,
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
                                //               FloatingActionButton(
                                //                 backgroundColor:
                                //                     state.breakOut != ''
                                //                         ? Colors.grey
                                //                         : Color(0xff12cad6),
                                //                 heroTag: 'breakOut',
                                //                 onPressed: (state.breakOut ==
                                //                         '')
                                //                     ? () {
                                //                         AwesomeDialog(
                                //                           context: context,
                                //                           dialogType: DialogType
                                //                               .QUESTION,
                                //                           animType: AnimType
                                //                               .BOTTOMSLIDE,
                                //                           title: 'Break Out',
                                //                           desc:
                                //                               'Apakah anda yakin sudah masuk jam istirahat?',
                                //                           btnCancelText:
                                //                               "Belum",
                                //                           btnOkText: "Sudah",
                                //                           btnCancelOnPress:
                                //                               () {},
                                //                           btnOkOnPress: () {
                                //                             prosesBreakOut(
                                //                                 state.userId,
                                //                                 '${DateTime.now()}',
                                //                                 state.idShift,
                                //                                 state.shiftOut);
                                //                           },
                                //                         )..show();
                                //                       }
                                //                     : () {
                                //                         /*Button break out disabled*/
                                //                       },
                                //                 child: Text('Break\nOut',
                                //                     textAlign:
                                //                         TextAlign.center),
                                //                 shape: RoundedRectangleBorder(
                                //                   borderRadius:
                                //                       BorderRadius.circular(10),
                                //                 ),
                                //               ),
                                //               Padding(
                                //                 padding: const EdgeInsets.only(
                                //                     top: 8.0),
                                //                 child: Text(
                                //                   state.breakOut,
                                //                   style: TextStyle(
                                //                       color: Colors.white),
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
                                //               FloatingActionButton(
                                //                 backgroundColor:
                                //                     (state.breakOut == '')
                                //                         ? Colors.grey
                                //                         : (state.breakIn != '')
                                //                             ? Colors.grey
                                //                             : Color(0xff12cad6),
                                //                 heroTag: 'breakIn',
                                //                 onPressed: (state.breakOut ==
                                //                             '' ||
                                //                         state.breakIn != '')
                                //                     ? () {
                                //                         /* Button must disabled */
                                //                       }
                                //                     : () {
                                //                         AwesomeDialog(
                                //                           context: context,
                                //                           dialogType: DialogType
                                //                               .QUESTION,
                                //                           animType: AnimType
                                //                               .BOTTOMSLIDE,
                                //                           title: 'Break In',
                                //                           desc:
                                //                               'Waktu istirahat sudah selesai?',
                                //                           btnCancelText:
                                //                               "Belum",
                                //                           btnOkText: "Sudah",
                                //                           btnCancelOnPress:
                                //                               () {},
                                //                           btnOkOnPress: () {
                                //                             prosesBreakIn(
                                //                                 state.userId,
                                //                                 '${DateTime.now()}',
                                //                                 state.idShift,
                                //                                 state.shiftOut);
                                //                           },
                                //                         )..show();
                                //                       },
                                //                 child: Text('Break\nIn',
                                //                     textAlign:
                                //                         TextAlign.center),
                                //                 shape: RoundedRectangleBorder(
                                //                   borderRadius:
                                //                       BorderRadius.circular(10),
                                //                 ),
                                //               ),
                                //               Padding(
                                //                 padding: const EdgeInsets.only(
                                //                     top: 8.0),
                                //                 child: Text(
                                //                   state.breakIn,
                                //                   style: TextStyle(
                                //                       color: Colors.white),
                                //                 ),
                                //               ),
                                //             ],
                                //           ),
                                //         ),
                                //       ),
                                //     ],
                                //   ),
                                // ),
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
                bottomNavigationBar: BottomAppBar(
                  shape: const CircularNotchedRectangle(),
                  child: Container(height: 60.0),
                  // child: Padding(
                  //   padding: const EdgeInsets.all(8.0),
                  //   child: Row(
                  //     mainAxisSize: MainAxisSize.max,
                  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //     children: [
                  //       Wrap(
                  //         crossAxisAlignment: WrapCrossAlignment.center,
                  //         direction: Axis.vertical,
                  //         children: [
                  //           IconButton(
                  //             onPressed: () {},
                  //             icon: Icon(
                  //               Icons.add_to_home_screen_outlined,
                  //               size: 30,
                  //             ),
                  //             color: Colors.grey,
                  //           ),
                  //           Text(
                  //             "HR System",
                  //             style: TextStyle(fontSize: 10),
                  //           ),
                  //         ],
                  //       ),
                  //       Wrap(
                  //         crossAxisAlignment: WrapCrossAlignment.center,
                  //         direction: Axis.vertical,
                  //         children: [
                  //           IconButton(
                  //             onPressed: () {},
                  //             icon: Icon(
                  //               Icons.group_work_outlined,
                  //               size: 30,
                  //             ),
                  //             color: Colors.grey,
                  //           ),
                  //           Text(
                  //             "Trusmiverse",
                  //             style: TextStyle(fontSize: 10),
                  //           ),
                  //         ],
                  //       ),
                  //       Padding(padding: EdgeInsets.symmetric(horizontal: 25)),
                  //       Wrap(
                  //         crossAxisAlignment: WrapCrossAlignment.center,
                  //         direction: Axis.vertical,
                  //         children: [
                  //           IconButton(
                  //             onPressed: () {},
                  //             icon: Icon(
                  //               Icons.account_balance,
                  //               size: 30,
                  //             ),
                  //             color: Colors.grey,
                  //           ),
                  //           Text(
                  //             "WFH",
                  //             style: TextStyle(fontSize: 10),
                  //           ),
                  //         ],
                  //       ),
                  //       Wrap(
                  //         crossAxisAlignment: WrapCrossAlignment.center,
                  //         direction: Axis.vertical,
                  //         children: [
                  //           IconButton(
                  //             onPressed: () {},
                  //             icon: Icon(
                  //               Icons.exit_to_app,
                  //               size: 30,
                  //             ),
                  //             color: Colors.grey,
                  //           ),
                  //           Text(
                  //             "Logout",
                  //             style: TextStyle(fontSize: 10),
                  //           ),
                  //         ],
                  //       ),
                  //     ],
                  //   ),
                  // ),
                ),
                floatingActionButton: Visibility(
                  visible: _visibleButton,
                  child: Container(
                      height: 80,
                      width: 80,
                      child: FloatingActionButton(
                        onPressed: () => {
                          checkStatus(userID),
                        },
                        tooltip: _toolTip,
                        backgroundColor: _colorButton,
                        child:
                            Icon(Icons.alarm_on, color: Colors.white, size: 40),
                      )),
                ),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.centerDocked,
              );
            },
          ),
        ),
      ),
    );
  }

  setKondisi(state) async {
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

  Future showProgressDialog(BuildContext loadContext) {
    return showDialog(
      context: loadContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () {
            return Future.value(false);
          },
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  showSuccessDialog(context, status) {
    String title = '';
    if (status == 'checkin') {
      title = "Check In Success ";
    } else {
      title = "Check Out Success ";
    }

    return AwesomeDialog(
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

  showHariBesar(lottie, title, message) {
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

  showErrorDialog(context, status) {
    String title = '';
    if (status == 'checkin') {
      title = "Check In Failed";
    } else {
      title = "Check Out Failed";
    }

    return AwesomeDialog(
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
        getProfil(userID, date);
      },
    )..show();
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  String _formatHariTanggal(DateTime dateTime) {
    return DateFormat('EEE, dd MMM yyyy').format(dateTime);
  }

  logout() {
    _profileBloc.add(InitialProfile());
    removePref();
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pushNamedAndRemoveUntil(
          context, "/login", (Route<dynamic> routes) => false);
    });
  }

  absen() {
    Future.delayed(const Duration(microseconds: 2000), () {
      Navigator.pushNamedAndRemoveUntil(
          context, "/profile", (Route<dynamic> routes) => false);
    });
  }

  goToHR(context) async {
    Navigator.pushNamed(context, "/hrsystem",
        arguments: PassParams(username, password));
  }

  goToTrusmiverse(context) async {
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

  wfh(context) async {
    Navigator.pushNamed(context, "/wfh",
        arguments: PassParams(username, password));
  }

  removePref() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      pref.remove('username');
      pref.remove('password');
      pref.remove('clock_in');
      pref.remove('isQuizPasses');
    });
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
                _openCamera();
              } else {
                _showQuiz();
                // Get.offAll(() => QuizScreen());
              }
            } else {
              _openCamera();
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

  void _showQuiz() {
    Future<void> future = showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      enableDrag: true,
      builder: (context) => QuizScreen(),
    );

    future.then((value) => _closeQuiz(value));
  }

  void _closeQuiz(void value) async {
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
      _openCamera();
    }
  }
}
