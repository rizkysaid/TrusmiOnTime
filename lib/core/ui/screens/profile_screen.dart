import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:login_absen/core/bloc/profile/profile_bloc.dart';
import 'package:login_absen/core/config/endpoint.dart';
import 'package:login_absen/core/config/about.dart';
import 'package:login_absen/core/database/database_helper.dart';
import 'package:login_absen/core/models/ProfileModel.dart';
import 'package:login_absen/core/services/ApiService.dart';
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

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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

  String dateId = formatDate(DateTime.now(), [dd, '/', mm, '/', yy]);

  File? imageFile;

  void _getFromCamera() async {
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
    _profileBloc.add(InitialProfile());
    getPref();
    _onRefresh();

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

  @override
  void dispose() {
    super.dispose();
//    timer.cancel();
  }

  // Future<void> checkConnection() async {

  //   String ip;
  //   final dbHelper = DatabaseHelper.instance;
  //   final allRows = await dbHelper.queryAllRows();

  //   if (allRows.length != 0) {
  //     ip = allRows[0]['ip_address'];
  //   } else {
  //     ip = Endpoint.baseUrl;
  //   }

  //   ApiServices services = ApiServices();
  //   var response = await services.profil(ip, userID, date);

  //   if (userID == null) {
  //     Future.delayed(const Duration(microseconds: 2000), () {
  //       Navigator.pushNamedAndRemoveUntil(
  //           context, "/login", (Route<dynamic> routes) => false);
  //     });
  //   } else {
  //     if (response == null) {
  //       ToastUtils.show("Error Connecting To Server");
  //       Future.delayed(const Duration(microseconds: 2000), () {
  //         Navigator.pushNamedAndRemoveUntil(
  //             context, "/invalid_ip", (Route<dynamic> routes) => false);
  //       });
  //     }
  //   }

  // }

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

  getPref() async {
    _profileBloc.add(InitialProfile());
    var pref = await SharedPreferences.getInstance();
    // print(pref.getString('username'));
    if (pref.getString('username') == null) {
      logout();
    } else {
      setState(() {
        username = pref.getString('username')!;
        password = pref.getString('password')!;
        userID = pref.getString('userID').toString();
        // clockin = pref.getString('clock_in')!;
        // imageUrl = pref.getString('imageUrl')!;
        // _status = pref.getString('status')!;
        // _isCheckin = pref.getBool('isCheckin');
        // _isCheckout = pref.getBool('isCheckout');
      });

      // timer = new Timer(new Duration(seconds: 1), () {
      // debugPrint("Print after 1 seconds");
      getProfil(userID, date);
      // });
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

    ApiServices services = ApiServices();
    var response = await services.checkHolidays(ip, userID);

    print('checkHolidays => ' + response.toString());
    if (response == null) {
      checkBadEmp(context);
      // getProfil(userID, date);
      return null;
    } else {
      statusHariBesar = response['status'];
      print(response['data']);
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
        checkBadEmp(context);
        // _profileBloc.add(InitialProfile());
        // getProfil(userID, date);
      }
    }
  }

  Future<void> checkBadEmp(context) async {
    String ip;
    final dbHelper = DatabaseHelper.instance;
    final allRows = await dbHelper.queryAllRows();

    if (allRows.length != 0) {
      allRows.forEach((row) => print(row));
      ip = allRows[0]['ip_address'];
    } else {
      ip = Endpoint.baseUrl;
    }

    ApiServices services = ApiServices();
    var response = await services.checkBadEmp(ip, userID);

    if (response != null) {
      if (response['status'] == true) {
        _displayBadEmployees(context, response);
      } else {
        _profileBloc.add(InitialProfile());
        getProfil(userID, date);
      }
    } else {
      _profileBloc.add(InitialProfile());
      getProfil(userID, date);
    }
  }

  _displayBadEmployees(BuildContext context, response) {
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
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Container(
                          width: MediaQuery.of(context).size.width - 50,
                          padding: EdgeInsets.all(10),
                          margin: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            image: DecorationImage(
                              image: AssetImage('assets/background.png'),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.topRight,
                                child: Material(
                                  color: Colors.transparent,
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.close_rounded,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _profileBloc.add(InitialProfile());
                                      getProfil(userID, date);
                                    },
                                  ),
                                ),
                              ),
                              Column(
                                children: [
                                  DefaultTextStyle(
                                    child: Text(
                                      'Bad Employee',
                                    ),
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  DefaultTextStyle(
                                    child: Text(
                                      'Of The Month',
                                    ),
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  DefaultTextStyle(
                                    child: Text(
                                      DateFormat('MMMM').format(
                                            DateTime(
                                              0,
                                              int.parse(response['periode']
                                                  .substring(5, 7)),
                                            ),
                                          ) +
                                          ', ' +
                                          response['periode'].substring(0, 4),
                                    ),
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 40),
                              ListView.builder(
                                shrinkWrap: true,
                                itemCount: response['data'].length,
                                itemBuilder: (context, index) {
                                  return Card(
                                    child: ListTile(
                                      contentPadding: EdgeInsets.all(10),
                                      minVerticalPadding: 10,
                                      leading: CircleAvatar(
                                        backgroundImage: NetworkImage(
                                          Endpoint.baseIp +
                                              '/' +
                                              response['data'][index]
                                                  ['profile_picture'],
                                        ),
                                        radius: 30,
                                      ),
                                      title: Text(
                                          response['data'][index]['employee']),
                                      subtitle: Text(
                                          response['data'][index]['jabatan']),
                                      trailing: Stack(
                                        children: [
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 5.0),
                                            child: Chip(
                                              label: Text(
                                                response['data'][index]
                                                    ['score'],
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 0,
                                            right: 10,
                                            left: 10,
                                            child: Text(
                                              'Score',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey),
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
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _profileBloc.add(InitialProfile());
                          getProfil(userID, date);
                        },
                        child: Text('Close'),
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.white),
                          foregroundColor:
                              MaterialStateProperty.all<Color>(Colors.black87),
                        ),
                      ),
                    ],
                  ),
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
                showProgressDialog(context);
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
                                tileMode: TileMode.clamp)),
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
                                        image:
                                            AssetImage('assets/background.png'),
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
                                            child: Container(
                                              width: 150.0,
                                              height: 150.0,
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
                                child: Image.network(
                                    Endpoint.urlProfile +
                                        "/" +
                                        state.fotoProfil,
                                    width: 125,
                                    height: 125,
                                    fit: BoxFit.cover),
                              ),
                              backgroundColor: Colors.transparent,
                            ),
                            SizedBox(width: 10),
                            Column(
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
                                Text(
                                  state.jabatan,
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.white),
                                ),
                              ],
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
                                    image: AssetImage('assets/background.png'),
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
                  child: Container(height: 50.0),
                ),
                floatingActionButton: Visibility(
                  visible: _visibleButton,
                  child: Container(
                      height: 80,
                      width: 80,
                      child: FloatingActionButton(
                        onPressed: () => {checkStatus(userID)},
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

  setKondisi(state) {
    setState(() {
      userID = state.userId;
      idShift = state.idShift;
    });
    if (state.idShift != '3') {
      if (state.clockIn != dateId) {
        if (state.clockIn == "--:--") {
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

          // print('con. 2 => state.clockIn = ' +
          //     state.clockIn +
          //     ' dataClockout = ' +
          //     state.clockOut);
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

          // print('con. 3 => state.clockIn = ' +
          //     state.clockIn +
          //     ' dataClockout = ' +
          //     state.clockOut);
          //kondisi sudah checkin & belum checkout

        } else {
          if (state.clockIn != "--:--" && state.clockOut != "--:--") {
            // print('con. 1 => state.clockIn = ' +
            //     state.clockIn +
            //     ' dataClockout = ' +
            //     state.clockOut);
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

        // print('con. 2 => state.clockIn = ' +
        //     state.clockIn +
        //     ' dataClockout = ' +
        //     state.clockOut);
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

        // print('con. 3 => state.clockIn = ' +
        //     state.clockIn +
        //     ' dataClockout = ' +
        //     state.clockOut);
        //kondisi sudah checkin & belum checkout

      } else if (dateOut != dateId) {
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

        // print('con. 4 => state.clockIn = ' +
        //     state.clockIn +
        //     ' dataClockout = ' +
        //     state.clockOut);
        //kondisi tanggal checkout tidak sama dengan tgl hari ini

      } else {
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

        // print('con. 5 => state.clockIn = ' +
        //     state.clockIn +
        //     ' dataClockout = ' +
        //     state.clockOut);
        //kondisi sift malam
      }
    }
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
      title = "Check-In Success ";
    } else {
      title = "Check-Out Success ";
    }

    return AwesomeDialog(
      context: context,
      dialogType: DialogType.SUCCES,
      animType: AnimType.BOTTOMSLIDE,
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
          // _profileBloc.add(InitialProfile());
          // getProfil(userID, date);
          checkBadEmp(context);
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
            checkBadEmp(context);
            // _profileBloc.add(InitialProfile());
            // getProfil(userID, date);
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
      title = "Check-In Failed";
    } else {
      title = "Check-Out Failed";
    }

    return AwesomeDialog(
      context: context,
      dialogType: DialogType.ERROR,
      animType: AnimType.BOTTOMSLIDE,
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
    });
  }

  checkStatus(userId) async {
    // print('checkStatus => userId = ' + userId);

    showProgressDialog(context);

    String ip;
    final dbHelper = DatabaseHelper.instance;
    final allRows = await dbHelper.queryAllRows();

    if (allRows.length != 0) {
      ip = allRows[0]['ip_address'];
    } else {
      ip = Endpoint.baseUrl;
    }

    ApiServices services = ApiServices();
    var response = await services.checkStatus(ip, userID);

    if (response.data.aktif.isEmpty) {
      Future.delayed(const Duration(microseconds: 2000), () {
        Navigator.pushNamedAndRemoveUntil(
            context, "/invalid_ip", (Route<dynamic> routes) => false);
      });
    } else {
      Navigator.of(context, rootNavigator: true).pop(context);

      if (response.data.aktif == '1') {
        if (response.data.achive == true) {
          _getFromCamera();
        } else {
          AwesomeDialog(
            context: context,
            dialogType: DialogType.ERROR,
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
          dialogType: DialogType.ERROR,
          title: "Anda tidak bisa melakukan absen!",
          desc: "Akun anda telah dinonaktifkan.",
          btnOkText: "Logout",
          btnOkOnPress: () {
            logout();
          },
        )..show();
      }
    }
  }
}
