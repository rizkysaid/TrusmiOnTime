import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:login_absen/core/bloc/profile/profile_bloc.dart';
import 'package:login_absen/core/config/endpoint.dart';
import 'package:login_absen/core/config/about.dart';
import 'package:login_absen/core/database/database_helper.dart';
import 'package:login_absen/core/models/ProfileModel.dart';
import 'package:login_absen/core/services/ApiService.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'PassParams.dart';
import 'ScreenArguments.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:date_format/date_format.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  CancelToken apiToken = CancelToken();

  late String username;
  late String password;
  late String userID;
  static String nama = '';
  static String jabatan = '';
  String clockin = '--:--';
  String clockout = '--:--';
  late String imageUrl;
  static String message = '';
  // static String totalWork = '';
  late String _status;
  // static bool _isCheckin = false;
  // static bool _isCheckout = false;
  static bool statusPhoto = false;
  static bool statusIcon = true;
  static bool _visibleButton = true;
  // static bool statusTotalWork = false;
  static Color _colorButton = Colors.red;
  late Timer timer;

  String dateIn = '';
  String dateOut = '';
  String idShift = '';
  String shiftIn = '';
  String shiftOut = '';
  String shift = '';

  static String date = new DateTime.now().toIso8601String().substring(0, 10);
  static String _toolTip = "Check In";
  late String photoProfile;

  late String _timeString;
  late String _hariTanggal;

  String dateId = formatDate(DateTime.now(), [dd, '/', mm, '/', yy]);

  // bool _saving = false;

  List<ProfileModel> productProfile = [];
  final ProfileBloc _profileBloc = ProfileBloc();

  @override
  void initState() {
    super.initState();

    // checkConnection();

    getPref();

    // setState(() {
    //   _saving = true;
    // });

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
    await Future.delayed(Duration(milliseconds: 3000));

    _refreshController.refreshCompleted();
    // checkConnection();
    getProfil(userID, date);
    // setState(() {
    //   _saving = true;
    // });
  }

  void _onLoading() async {
    await Future.delayed(Duration(milliseconds: 3000));

    _refreshController.loadComplete();
  }

  Future<void> getProfil(userID, date) async {
    String ip;
    final dbHelper = DatabaseHelper.instance;
    final allRows = await dbHelper.queryAllRows();
    // print('query all rows get profil profile screen:');
    // print('Length = ' + allRows.length.toString());

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

    // ApiServices services = ApiServices();
    // var response = await services.profil(ip, userID, date, apiToken);

    // if (response == null) {
    //   Future.delayed(const Duration(microseconds: 2000), () {
    //     Navigator.pushNamedAndRemoveUntil(
    //         context, "/invalid_ip", (Route<dynamic> routes) => false);
    //   });
    // } else {
    //   // print('Ini responsnya : '+response.toString());
    //   String dataNama = response[0].data.nama.toString();
    //   String dataJabatan = response[0].data.jabatan.toString();
    //   String dataClockIn = response[0].data.clockIn.toString();
    //   String dataClockOut = response[0].data.clockOut.toString();
    //   String dataImageUrl = response[0].data.photoIn.toString();
    //   message = response[0].message.toString();
    //   // totalWork = response[0].data.totalWork.toString();
    //   photoProfile = response[0].data.fotoProfil.toString();
    //   dateIn = response[0].data.dateIn.toString();
    //   dateOut = response[0].data.dateOut.toString();

    //   idShift = response[0].data.idShift.toString();
    //   shiftIn = response[0].data.shiftIn.toString();
    //   shiftOut = response[0].data.shiftOut.toString();

    //   SharedPreferences pref = await SharedPreferences.getInstance();

    //   try {
    //     if (response[0].status == true) {

    //       setState(() {
    //         // _saving = true;
    //         nama = dataNama;
    //         jabatan = dataJabatan;
    //         pref.setString('idShift', idShift);

    //         if (idShift != '3') {
    //           if (dataClockIn != dateId) {
    //             if (dataClockIn == "--:--") {
    //               setState(() {
    //                 _isCheckin = false;
    //                 _isCheckout = false;
    //               });

    //               if (_isCheckin == true && dataClockIn == "--:--") {
    //                 Future.delayed(const Duration(microseconds: 3000), () {
    //                   Navigator.pushNamedAndRemoveUntil(context, "/profile",
    //                       (Route<dynamic> routes) => false);
    //                 });
    //               } else {
    //                 statusPhoto = false;
    //                 statusIcon = true;
    //                 imageUrl = "";
    //                 _colorButton = Colors.red[700];
    //                 clockout = dataClockOut;
    //                 clockin = dataClockIn;
    //                 // statusTotalWork = false;
    //                 _visibleButton = true;
    //                 _status = "checkin";
    //                 shift = shiftIn;
    //                 pref.remove('shift');
    //                 pref.setString('shift', shiftIn);

    //                 _saving = false;
    //               }

    //               print('con. 2 => dataClockIn = ' +
    //                   dataClockIn +
    //                   ' dataClockout = ' +
    //                   dataClockOut);
    //               //kondisi belum checkin

    //             } else if (dataClockOut == "--:--") {
    //               if (_isCheckin == true) {
    //                 setState(() {
    //                   _isCheckout = false;
    //                 });
    //               }

    //               if (_isCheckout == true && dataClockOut == "--:--") {
    //                 Future.delayed(const Duration(microseconds: 3000), () {
    //                   Navigator.pushNamedAndRemoveUntil(context, "/profile",
    //                       (Route<dynamic> routes) => false);
    //                 });
    //               } else {
    //                 clockin = dataClockIn;
    //                 clockout = dataClockOut;
    //                 statusPhoto = true;
    //                 statusIcon = false;
    //                 imageUrl = dataImageUrl;
    //                 _colorButton = Colors.deepOrange;
    //                 // statusTotalWork = false;
    //                 _visibleButton = true;
    //                 _status = "checkout";
    //                 shift = shiftOut;
    //                 pref.remove('shift');
    //                 pref.setString('shift', shiftOut);

    //                 _saving = false;
    //               }

    //               print('con. 3 => dataClockIn = ' +
    //                   dataClockIn +
    //                   ' dataClockout = ' +
    //                   dataClockOut);
    //               //kondisi sudah checkin & belum checkout

    //             } else {
    //               if (dataClockIn != "--:--" && dataClockOut != "--:--") {
    //                 clockin = dataClockIn;
    //                 clockout = dataClockOut;
    //                 statusPhoto = true;
    //                 statusIcon = false;
    //                 imageUrl = dataImageUrl;
    //                 _colorButton = Colors.red[700];
    //                 // statusTotalWork = true;
    //                 _visibleButton = false;
    //                 _status = "checkin";
    //                 shift = shiftIn;
    //                 pref.remove('shift');
    //                 pref.setString('shift', shiftIn);

    //                 _saving = false;

    //                 print('con. 1 => dataClockIn = ' +
    //                     dataClockIn +
    //                     ' dataClockout = ' +
    //                     dataClockOut);
    //                 //kondisi sudah checkin & sudah checkout

    //               }
    //             }
    //           }
    //         } else {
    //           //KONDISI SIFT 3

    //           if (dataClockIn == "--:--" && dataClockOut == "--:--") {
    //             setState(() {
    //               _isCheckin = false;
    //               _isCheckout = false;
    //             });

    //             if (_isCheckin == true && dataClockIn == "--:--") {
    //               Future.delayed(const Duration(microseconds: 3000), () {
    //                 Navigator.pushNamedAndRemoveUntil(
    //                     context, "/profile", (Route<dynamic> routes) => false);
    //               });
    //             } else {
    //               statusPhoto = false;
    //               statusIcon = true;
    //               imageUrl = "";
    //               _colorButton = Colors.red[700];
    //               clockout = dataClockOut;
    //               clockin = dataClockIn;
    //               // statusTotalWork = false;
    //               _visibleButton = true;
    //               _status = "checkin";
    //               shift = shiftIn;
    //               pref.remove('shift');
    //               pref.setString('shift', shiftIn);

    //               _saving = false;
    //             }

    //             print('con. 2 => dataClockIn = ' +
    //                 dataClockIn +
    //                 ' dataClockout = ' +
    //                 dataClockOut);
    //             //kondisi belum checkin

    //           } else if (dataClockIn != "--:--" && dataClockOut == "--:--") {
    //             if (_isCheckin == true) {
    //               setState(() {
    //                 _isCheckout = false;
    //               });
    //             }

    //             if (_isCheckout == true && dataClockOut == "--:--") {
    //               Future.delayed(const Duration(microseconds: 3000), () {
    //                 Navigator.pushNamedAndRemoveUntil(
    //                     context, "/profile", (Route<dynamic> routes) => false);
    //               });
    //             } else {
    //               clockin = dataClockIn;
    //               clockout = dataClockOut;
    //               statusPhoto = true;
    //               statusIcon = false;
    //               imageUrl = dataImageUrl;
    //               _colorButton = Colors.deepOrange;
    //               // statusTotalWork = false;
    //               _visibleButton = true;
    //               _status = "checkout";
    //               shift = shiftOut;
    //               pref.remove('shift');
    //               pref.setString('shift', shiftOut);

    //               _saving = false;
    //             }

    //             print('con. 3 => dataClockIn = ' +
    //                 dataClockIn +
    //                 ' dataClockout = ' +
    //                 dataClockOut);
    //             //kondisi sudah checkin & belum checkout

    //           } else if (dateOut != dateId) {
    //             clockin = dataClockIn;
    //             clockout = dataClockOut;
    //             dateOut = "";
    //             dateIn = "";
    //             statusPhoto = true;
    //             statusIcon = false;
    //             imageUrl = dataImageUrl;
    //             _colorButton = Colors.red[700];
    //             // statusTotalWork = false;
    //             _visibleButton = true;
    //             _status = "checkin";
    //             shift = shiftIn;
    //             pref.remove('shift');
    //             pref.setString('shift', shiftIn);

    //             _saving = false;

    //             print('con. 4 => dataClockIn = ' +
    //                 dataClockIn +
    //                 ' dataClockout = ' +
    //                 dataClockOut);
    //             //kondisi tanggal checkout tidak sama dengan tgl hari ini

    //           } else {
    //             statusPhoto = true;
    //             statusIcon = false;
    //             clockin = dataClockIn;
    //             clockout = dataClockOut;
    //             imageUrl = dataImageUrl;
    //             _visibleButton = true;
    //             // statusTotalWork = true;
    //             _status = "checkin";
    //             shift = shiftIn;
    //             pref.remove('shift');
    //             pref.setString('shift', shiftIn);
    //             _colorButton = Colors.red[700];

    //             _saving = false;

    //             print('con. 5 => dataClockIn = ' +
    //                 dataClockIn +
    //                 ' dataClockout = ' +
    //                 dataClockOut);
    //             //kondisi sift malam
    //           }
    //         }
    //       });
    //     } else {
    //       Future.delayed(const Duration(microseconds: 2000), () {
    //         Navigator.pushNamedAndRemoveUntil(
    //             context, "/no_connection", (Route<dynamic> routes) => false);
    //       });
    //     }
    //   } catch (err) {
    //     print('err => '+err.toString());
    //   }
    // }
  }

  getPref() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    setState(() {
      username = pref.getString('username')!;
      password = pref.getString('password')!;
      userID = pref.getString('userID')!;
      // clockin = pref.getString('clock_in')!;
      imageUrl = pref.getString('imageUrl')!;
      _status = pref.getString('status')!;
      // _isCheckin = pref.getBool('isCheckin');
      // _isCheckout = pref.getBool('isCheckout');
    });

    // print("_isCheckin = " + _isCheckin.toString());
    // print("_isCheckout = " + _isCheckout.toString());

    if (username.isNotEmpty) {
      timer = new Timer(new Duration(seconds: 1), () {
        // debugPrint("Print after 1 seconds");
        getProfil(userID, date);
      });
    } else {
      Navigator.pushNamedAndRemoveUntil(
          context, "/login", (Route<dynamic> routes) => false);
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

  @override
  Widget build(BuildContext context) {
    String version = About.version;

    return SmartRefresher(
      enablePullDown: true,
      enablePullUp: false,
      header: WaterDropMaterialHeader(),
      // footer: CustomFooter(
      //   builder: (BuildContext context, LoadStatus mode) {
      //     Widget body;
      //     if (mode == LoadStatus.idle) {
      //       body = Text("pull up load");
      //     } else if (mode == LoadStatus.loading) {
      //       body = CupertinoActivityIndicator();
      //     } else if (mode == LoadStatus.failed) {
      //       body = Text("Load Failed!Click retry!");
      //     } else if (mode == LoadStatus.canLoading) {
      //       body = Text("release to load more");
      //     } else {
      //       body = Text("No more Data");
      //     }
      //     return Container(
      //       height: 55.0,
      //       child: Center(child: body),
      //     );
      //   },
      // ),
      controller: _refreshController,
      onRefresh: _onRefresh,
      onLoading: _onLoading,
      child: BlocProvider(
        create: (BuildContext context) => ProfileBloc(),
        child: BlocListener<ProfileBloc, ProfileState>(
          bloc: ProfileBloc(),
          listener: (context, state) {
            switch (state.status) {
              case ProfileStatus.success:
                print('listener success ');
                print(state.profile);
                break;
              case ProfileStatus.failure:
                print('listener failure ');
                break;
              default:
                print('initial');
            }
          },
          child: BlocBuilder<ProfileBloc, ProfileState>(
            bloc: ProfileBloc(),
            builder: (context, state) {
              print('builder status => ' + state.status.toString());
              switch (state.status) {
                case ProfileStatus.initial:
                  return Container(
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                      ),
                    ),
                  );
                case ProfileStatus.failure:
                  return Container(
                    child: Text('failure'),
                  );
                default:
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
                                            photoProfile.toString(),
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
                                      nama.toString(),
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                    Text(
                                      jabatan.toString(),
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
                    body: LayoutBuilder(builder: (BuildContext context,
                        BoxConstraints viewportConstraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                              minHeight: viewportConstraints.maxHeight),
                          child: Column(
                            children: <Widget>[
                              Container(
                                width: MediaQuery.of(context).size.width,
                                height: (MediaQuery.of(context).size.height /
                                        2) +
                                    (MediaQuery.of(context).size.height / 6),
                                decoration: BoxDecoration(
                                    image: DecorationImage(
                                        image:
                                            AssetImage('assets/background.png'),
                                        fit: BoxFit.cover)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    SizedBox(height: 20),
                                    Container(
                                      width: 300.0,
                                      height: 300.0,
                                      decoration: new BoxDecoration(
                                        color: Colors.lightBlue[50]!
                                            .withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Column(
                                        children: <Widget>[
                                          SizedBox(height: 20),
                                          Visibility(
                                            visible: statusPhoto,
                                            child: Container(
                                              width: 160.0,
                                              height: 160.0,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                shape: BoxShape.circle,
                                                image: new DecorationImage(
                                                  fit: BoxFit.cover,
                                                  image: new NetworkImage(
                                                      Endpoint.urlFoto +
                                                          "/" +
                                                          imageUrl.toString()),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Visibility(
                                            visible: statusIcon,
                                            child: Container(
                                              width: 160.0,
                                              height: 160.0,
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
                                          Text(nama.toString(),
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold)),
                                          Text(jabatan.toString(),
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
                                    SizedBox(height: 20),
                                    Text(
                                      message.toString(),
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    SizedBox(height: 20),
                                    // Visibility(
                                    //   visible: statusTotalWork,
                                    //   child: Column(children: <Widget>[
                                    //     Text("Total Work", style: TextStyle(fontSize: 16, color: Colors.white)),
                                    //     Text(totalWork.toString(),
                                    //         style: TextStyle(
                                    //             fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white
                                    //         )
                                    //     ),
                                    //   ]),
                                    // ),
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
                                          Text("Start Time",
                                              style: TextStyle(fontSize: 18)),
                                          Text(clockin.toString(),
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold)),
                                          Text(
                                            dateIn.toString(),
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
                                          Text(clockout.toString(),
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold)),
                                          Text(
                                            dateOut.toString(),
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
                            child: Icon(Icons.alarm_on,
                                color: Colors.white, size: 40),
                          )),
                    ),
                    floatingActionButtonLocation:
                        FloatingActionButtonLocation.centerDocked,
                  );
              }
            },
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  String _formatHariTanggal(DateTime dateTime) {
    return DateFormat('EEE, dd MMM yyyy').format(dateTime);
  }

  logout() {
    savePref();

    Future.delayed(const Duration(microseconds: 2000), () {
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

  savePref() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      pref.remove('username');
      pref.remove('password');
      pref.remove('clock_in');
    });
  }

  checkStatus(userId) async {
    // setState(() {
    //   _saving = true;
    // });

    // if(_isCheckout == true){
    //   Future.delayed(const Duration(microseconds: 3000),(){
    //     Navigator.pushNamedAndRemoveUntil(context, "/profile", (Route<dynamic>routes)=>false);
    //   });
    // }else{
    String ip;
    final dbHelper = DatabaseHelper.instance;
    final allRows = await dbHelper.queryAllRows();
    // print('query all rows check status profil screen:' + dbHelper.toString());
    // print('Length = ' + allRows.length.toString());

    if (allRows.length != 0) {
      ip = allRows[0]['ip_address'];
    } else {
      ip = Endpoint.baseUrl;
    }

    ApiServices services = ApiServices();
    // var response = await services.checkStatus(ip, userID);
    var response = await services.checkStatus(ip, userID);

    if (response.data.aktif.isEmpty) {
      Future.delayed(const Duration(microseconds: 2000), () {
        Navigator.pushNamedAndRemoveUntil(
            context, "/invalid_ip", (Route<dynamic> routes) => false);
      });
    } else {
      // print('Status aktif = ' + response.data.aktif);

      // setState(() {
      //   _saving = false;
      // });

      if (response.data.aktif == '1') {
        if (response.data.achive == true) {
          Navigator.pushNamed(context, "/camera",
              arguments: ScreenArguments(userID, _status, idShift, shift));
        } else {
          Alert(
              context: context,
              style: alertStyle,
              type: AlertType.error,
              title: "Anda tidak bisa melakukan absen!",
              desc: response.data.message,
              buttons: [
                DialogButton(
                  child: Text(
                    "Kembali",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  onPressed: () => {
                    Future.delayed(const Duration(microseconds: 2000), () {
                      Navigator.pushNamedAndRemoveUntil(context, "/profile",
                          (Route<dynamic> routes) => false);
                    })
                  },
                  width: 120,
                )
              ]).show();
        }
      } else {
        Alert(
            context: context,
            style: alertStyle,
            type: AlertType.error,
            title: "Anda tidak bisa melakukan absen!",
            desc: "Akun anda telah dinonaktifkan.",
            buttons: [
              DialogButton(
                child: Text(
                  "Logout",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                onPressed: () => {logout()},
                width: 120,
              )
            ]).show();
      }
    }
    // }
  }

  var alertStyle = AlertStyle(
      animationType: AnimationType.fromTop,
      isCloseButton: false,
      isOverlayTapDismiss: false,
      descStyle: TextStyle(fontWeight: FontWeight.bold),
      animationDuration: Duration(milliseconds: 400),
      alertBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0.0),
        side: BorderSide(color: Colors.grey),
      ),
      titleStyle: TextStyle(color: Colors.red));
}
