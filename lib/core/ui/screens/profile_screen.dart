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
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'PassParams.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:date_format/date_format.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

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
  bool _isCheckout = false;
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
      maxHeight: 1080,
      maxWidth: 1080,
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
      if (_status == 'checkin') {
        prosesCheckin(userID, '${DateTime.now()}', imageFile!, idShift, shift);
      } else {
        prosesCheckout(userID, '${DateTime.now()}', imageFile!, idShift, shift);
      }
    }

    _profileBloc.add(InitialProfile());
  }

  Future<void> prosesCheckin(String usrId, String clockIn, File imageFile,
      String idShift, String shift) async {
    var uri = Uri.parse(Endpoint.checkin);
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

    print('proses checkin => ' + response.statusCode.toString());

    if (response.statusCode == 201) {
      getProfil(usrId, date);
    } else {
      print(response.statusCode);
    }
  }

  Future<void> prosesCheckout(String usrId, String clockIn, File imageFile,
      String idShift, String shift) async {
    var uri = Uri.parse(Endpoint.checkout);
    var request = new http.MultipartRequest("POST", uri);

    var multiPartFile = new http.MultipartFile.fromBytes(
      "foto",
      imageFile.readAsBytesSync(),
      filename: imageFile.path,
    );

    request.files.add(multiPartFile);
    request.fields['employee_id'] = usrId;
    request.fields['clock_out'] = clockIn;
    request.fields['id_shift'] = idShift;
    request.fields['shift'] = shift;

    var response = await request.send();

    print('response.status.checkout => ' + response.statusCode.toString());

    if (response.statusCode == 200) {
      getProfil(usrId, date);
    } else {
      print(response.statusCode);
    }
  }

  // bool _saving = false;

  List<ProfileModel> productProfile = [];
  final ProfileBloc _profileBloc = ProfileBloc();

  @override
  void initState() {
    super.initState();

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
    await Future.delayed(Duration(milliseconds: 3000));

    _refreshController.refreshCompleted();
    _profileBloc.add(InitialProfile());
    getProfil(userID, date);
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
      userID = pref.getString('userID').toString();
      // clockin = pref.getString('clock_in')!;
      imageUrl = pref.getString('imageUrl')!;
      _status = pref.getString('status')!;
      // _isCheckin = pref.getBool('isCheckin');
      // _isCheckout = pref.getBool('isCheckout');
    });

    // print("_isCheckin = " + _isCheckin.toString());
    // print("_isCheckout = " + _isCheckout.toString());

    print('userID => ' + userID);

    if (username != '') {
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
          bloc: _profileBloc,
          listener: (context, state) {
            switch (state.status) {
              case ProfileStatus.success:
                setState(() {
                  userID = state.userId;
                  idShift = state.idShift;
                });
                if (state.idShift != '3') {
                  if (state.clockIn != dateId) {
                    if (state.clockIn == "--:--") {
                      setState(() {
                        _isCheckin = false;
                        _isCheckout = false;
                      });

                      if (_isCheckin == true && state.clockIn == "--:--") {
                        Future.delayed(const Duration(microseconds: 3000), () {
                          Navigator.pushNamedAndRemoveUntil(context, "/profile",
                              (Route<dynamic> routes) => false);
                        });
                      } else {
                        statusPhoto = false;
                        statusIcon = true;
                        imageUrl = "";
                        _colorButton = Colors.red;
                        clockout = state.clockOut;
                        clockin = state.clockIn;
                        // statusTotalWork = false;
                        _visibleButton = true;
                        _status = "checkin";
                        shift = shiftIn;
                        // pref.remove('shift');
                        // pref.setString('shift', shiftIn);

                        // _saving = false;
                      }

                      print('con. 2 => state.clockIn = ' +
                          state.clockIn +
                          ' dataClockout = ' +
                          state.clockOut);
                      //kondisi belum checkin

                    } else if (state.clockOut == "--:--") {
                      if (_isCheckin == true) {
                        setState(() {
                          _isCheckout = false;
                        });
                      }

                      if (_isCheckout == true && state.clockOut == "--:--") {
                        Future.delayed(const Duration(microseconds: 3000), () {
                          Navigator.pushNamedAndRemoveUntil(context, "/profile",
                              (Route<dynamic> routes) => false);
                        });
                      } else {
                        clockin = state.clockIn;
                        clockout = state.clockOut;
                        statusPhoto = true;
                        statusIcon = false;
                        imageUrl = state.photoIn;
                        _colorButton = Colors.deepOrange;
                        // statusTotalWork = false;
                        _visibleButton = true;
                        _status = "checkout";
                        shift = shiftOut;
                        // pref.remove('shift');
                        // pref.setString('shift', shiftOut);

                        // _saving = false;
                      }

                      print('con. 3 => state.clockIn = ' +
                          state.clockIn +
                          ' dataClockout = ' +
                          state.clockOut);
                      //kondisi sudah checkin & belum checkout

                    } else {
                      if (state.clockIn != "--:--" &&
                          state.clockOut != "--:--") {
                        clockin = state.clockIn;
                        clockout = state.clockOut;
                        statusPhoto = true;
                        statusIcon = false;
                        imageUrl = state.photoIn;
                        _colorButton = Colors.red;
                        // statusTotalWork = true;
                        _visibleButton = false;
                        _status = "checkin";
                        shift = shiftIn;
                        // pref.remove('shift');
                        // pref.setString('shift', shiftIn);

                        // _saving = false;

                        print('con. 1 => state.clockIn = ' +
                            state.clockIn +
                            ' dataClockout = ' +
                            state.clockOut);
                        //kondisi sudah checkin & sudah checkout

                      }
                    }
                  }
                } else {
                  //KONDISI SIFT 3

                  if (state.clockIn == "--:--" && state.clockOut == "--:--") {
                    setState(() {
                      _isCheckin = false;
                      _isCheckout = false;
                    });

                    if (_isCheckin == true && state.clockIn == "--:--") {
                      Future.delayed(const Duration(microseconds: 3000), () {
                        Navigator.pushNamedAndRemoveUntil(context, "/profile",
                            (Route<dynamic> routes) => false);
                      });
                    } else {
                      statusPhoto = false;
                      statusIcon = true;
                      imageUrl = "";
                      _colorButton = Colors.red;
                      clockout = state.clockOut;
                      clockin = state.clockIn;
                      // statusTotalWork = false;
                      _visibleButton = true;
                      _status = "checkin";
                      shift = shiftIn;
                      // pref.remove('shift');
                      // pref.setString('shift', shiftIn);

                      // _saving = false;
                    }

                    print('con. 2 => state.clockIn = ' +
                        state.clockIn +
                        ' dataClockout = ' +
                        state.clockOut);
                    //kondisi belum checkin

                  } else if (state.clockIn != "--:--" &&
                      state.clockOut == "--:--") {
                    if (_isCheckin == true) {
                      setState(() {
                        _isCheckout = false;
                      });
                    }

                    if (_isCheckout == true && state.clockOut == "--:--") {
                      Future.delayed(const Duration(microseconds: 3000), () {
                        Navigator.pushNamedAndRemoveUntil(context, "/profile",
                            (Route<dynamic> routes) => false);
                      });
                    } else {
                      clockin = state.clockIn;
                      clockout = state.clockOut;
                      statusPhoto = true;
                      statusIcon = false;
                      imageUrl = state.photoIn;
                      _colorButton = Colors.deepOrange;
                      // statusTotalWork = false;
                      _visibleButton = true;
                      _status = "checkout";
                      shift = shiftOut;
                      // pref.remove('shift');
                      // pref.setString('shift', shiftOut);

                      // _saving = false;
                    }

                    print('con. 3 => state.clockIn = ' +
                        state.clockIn +
                        ' dataClockout = ' +
                        state.clockOut);
                    //kondisi sudah checkin & belum checkout

                  } else if (dateOut != dateId) {
                    clockin = state.clockIn;
                    clockout = state.clockOut;
                    dateOut = "";
                    dateIn = "";
                    statusPhoto = true;
                    statusIcon = false;
                    imageUrl = state.photoIn;
                    _colorButton = Colors.red;
                    // statusTotalWork = false;
                    _visibleButton = true;
                    _status = "checkin";
                    shift = shiftIn;
                    // pref.remove('shift');
                    // pref.setString('shift', shiftIn);

                    // _saving = false;

                    print('con. 4 => state.clockIn = ' +
                        state.clockIn +
                        ' dataClockout = ' +
                        state.clockOut);
                    //kondisi tanggal checkout tidak sama dengan tgl hari ini

                  } else {
                    statusPhoto = true;
                    statusIcon = false;
                    clockin = state.clockIn;
                    clockout = state.clockOut;
                    imageUrl = state.photoIn;
                    _visibleButton = true;
                    // statusTotalWork = true;
                    _status = "checkin";
                    shift = shiftIn;
                    // pref.remove('shift');
                    // pref.setString('shift', shiftIn);
                    // _colorButton = Colors.red[700];

                    // _saving = false;

                    print('con. 5 => state.clockIn = ' +
                        state.clockIn +
                        ' dataClockout = ' +
                        state.clockOut);
                    //kondisi sift malam
                  }
                }
                // Navigator.pop(context);
                break;
              case ProfileStatus.failure:
                // Navigator.pop(context);
                print('listener failure ');
                Future.delayed(const Duration(microseconds: 2000), () {
                  Navigator.pushNamedAndRemoveUntil(context, "/no_connection",
                      (Route<dynamic> routes) => false);
                });
                break;
              default:
                // showProgressDialog(context);
                getPref();
                print('initial');
            }
          },
          child: BlocBuilder<ProfileBloc, ProfileState>(
            bloc: _profileBloc,
            builder: (context, state) {
              print('state.status => ' + state.status.toString());
              switch (state.status) {
                case ProfileStatus.success:
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
                                    (MediaQuery.of(context).size.height / 10),
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
                                    SizedBox(height: 20),
                                    Text(
                                      state.message,
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
                      // shape: const CircularNotchedRectangle(),
                      child: Container(height: 50.0),
                    ),
                    floatingActionButton: Stack(
                      fit: StackFit.expand,
                      children: [
                        Visibility(
                          visible: state.statusBreak == '1' ? true : false,
                          child: Visibility(
                            visible: state.clockIn == '--:--' ? false : true,
                            child: Positioned(
                              left: 30,
                              bottom: 20,
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Text(state.breakOut),
                                  ),
                                  FloatingActionButton(
                                    backgroundColor: state.breakOut != ''
                                        ? Colors.grey
                                        : null,
                                    heroTag: 'breakOut',
                                    onPressed: () {/* Do something */},
                                    // child: Icon(
                                    //   Icons.arrow_left,
                                    //   size: 40,
                                    // ),
                                    child: Text('Break\nOut',
                                        textAlign: TextAlign.center),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 20,
                          child: Visibility(
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
                        ),
                        Visibility(
                          visible: state.statusBreak == '1' ? true : false,
                          child: Visibility(
                            visible: state.clockIn == '--:--' ? false : true,
                            child: Positioned(
                              bottom: 20,
                              right: 30,
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Text(state.breakIn),
                                  ),
                                  FloatingActionButton(
                                    backgroundColor: (state.breakOut == '')
                                        ? Colors.grey
                                        : (state.breakIn != '')
                                            ? Colors.grey
                                            : null,
                                    heroTag: 'breakIn',
                                    onPressed: (state.breakOut == '')
                                        ? () {/* Button must disabled */}
                                        : () {/* Do something */},
                                    child: Text('Break\nIn',
                                        textAlign: TextAlign.center),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    floatingActionButtonLocation:
                        FloatingActionButtonLocation.centerDocked,
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
                    body: Shimmer.fromColors(
                      baseColor: Colors.red,
                      highlightColor: Colors.grey,
                      child: LayoutBuilder(builder: (BuildContext context,
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
                                      (MediaQuery.of(context).size.height / 10),
                                  decoration: BoxDecoration(
                                      image: DecorationImage(
                                          image: AssetImage(
                                              'assets/background.png'),
                                          fit: BoxFit.cover)),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
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
                                            Container(
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
                                            SizedBox(height: 10),
                                            Text(state.nama,
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Text(state.jabatan,
                                                style: TextStyle(
                                                    color: Colors.white)),
                                            SizedBox(height: 20),
                                            Text(_timeString.toString(),
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 25,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Text(_hariTanggal.toString(),
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12))
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      Text(
                                        state.message,
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
                                                    fontWeight:
                                                        FontWeight.bold)),
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
                                                    fontWeight:
                                                        FontWeight.bold)),
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
                    ),
                    bottomNavigationBar: Shimmer.fromColors(
                      baseColor: Colors.white,
                      highlightColor: Colors.grey,
                      child: BottomAppBar(
                        // shape: const CircularNotchedRectangle(),
                        child: Container(height: 50.0),
                      ),
                    ),
                    floatingActionButton: Shimmer.fromColors(
                      baseColor: Colors.white,
                      highlightColor: Colors.grey,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Visibility(
                            visible: state.statusBreak == '1' ? true : false,
                            child: Visibility(
                              visible: state.clockIn == '--:--' ? false : true,
                              child: Positioned(
                                left: 30,
                                bottom: 20,
                                child: Column(
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8.0),
                                      child: Text(state.breakOut),
                                    ),
                                    FloatingActionButton(
                                      backgroundColor: state.breakOut != ''
                                          ? Colors.grey
                                          : null,
                                      heroTag: 'breakOut',
                                      onPressed: () {/* Do something */},
                                      // child: Icon(
                                      //   Icons.arrow_left,
                                      //   size: 40,
                                      // ),
                                      child: Text('Break\nOut',
                                          textAlign: TextAlign.center),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 20,
                            child: Visibility(
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
                          ),
                          Visibility(
                            visible: state.statusBreak == '1' ? true : false,
                            child: Visibility(
                              visible: state.clockIn == '--:--' ? false : true,
                              child: Positioned(
                                bottom: 20,
                                right: 30,
                                child: Column(
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8.0),
                                      child: Text(state.breakIn),
                                    ),
                                    FloatingActionButton(
                                      backgroundColor: (state.breakOut == '')
                                          ? Colors.grey
                                          : (state.breakIn != '')
                                              ? Colors.grey
                                              : null,
                                      heroTag: 'breakIn',
                                      onPressed: (state.breakOut == '')
                                          ? () {/* Button must disabled */}
                                          : () {/* Do something */},
                                      child: Text('Break\nIn',
                                          textAlign: TextAlign.center),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Future showProgressDialog(BuildContext context) {
    return showDialog(
      context: context,
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
    _profileBloc.add(InitialProfile());

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
          _getFromCamera();
          // Navigator.pushNamed(context, "/camera",
          //     arguments: ScreenArguments(userID, _status, idShift, shift));
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
