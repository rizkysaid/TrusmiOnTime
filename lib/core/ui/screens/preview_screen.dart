import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:login_absen/core/config/endpoint.dart';
import 'package:login_absen/core/database/database_helper.dart';
import 'package:login_absen/core/services/ApiService.dart';
import 'package:login_absen/core/ui/screens/profile_screen.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

// bool _saving = false;
bool hariBesar = false;

class PreviewScreen extends StatefulWidget {
  final String imgPath;
  final String userID;
  final String clockIn;
  final String imageUrl;
  final String status;
  final bool isCheckin = false;
  final bool isCheckout = false;
  final String idShift;
  final String shift;

  PreviewScreen(
      {required this.imgPath,
      required this.userID,
      required this.clockIn,
      required this.imageUrl,
      required this.status,
      required this.idShift,
      required this.shift});

  @override
  _PreviewScreenState createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  late bool statusHariBesar;
  late String title;
  late String msg;
  late String gif;
  // static bool status_get_profil;

  static String date = new DateTime.now().toIso8601String().substring(0, 10);

  @override
  void initState() {
    checkHolidays();

    super.initState();
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

    String usrId = basename(widget.userID);

    ApiServices services = ApiServices();
    var response = await services.checkHolidays(ip, usrId);

    if (response.data.isEmpty) {
      return null;
    } else {
      statusHariBesar = response.status;

      if (statusHariBesar == true) {
        setState(() {
          hariBesar = true;
          title = response.title.toString();
          msg = response.message.toString();
          gif = response.gif.toString();
        });
      } else {
        setState(() {
          hariBesar = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        titleStyle: TextStyle(color: Colors.green));

    return Container(
      color: Colors.red[700],
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          iconTheme: new IconThemeData(color: Colors.white),
          backgroundColor: Colors.red[700],
        ),
        body: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                flex: 2,
                child: Image.file(
                  File(widget.imgPath),
                  fit: BoxFit.cover,
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  height: 60.0,
                  color: Colors.red[700],
                  child: Center(
                    child: IconButton(
                      icon: Icon(
                        Icons.check,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        // setState(() {
                        //   _saving = true;
                        // });
                        FocusScope.of(context).requestFocus(new FocusNode());
                        getBytesFromFile().then((bytes) {
                          String clockIn = widget.clockIn.substring(0, 19);
                          String usrId = basename(widget.userID);
                          String idShift = basename(widget.idShift);
                          String shift = basename(widget.shift);

                          print('clockIn => ' + clockIn);
                          print('usrId => ' + usrId);
                          print('idShift => ' + idShift);
                          print('shift => ' + shift);

                          if (widget.status == "checkin") {
                            if (prosesCheckin(usrId, clockIn,
                                    File(widget.imgPath), idShift, shift) ==
                                true) {
                              savePref(clockIn.substring(11, 16), true, false,
                                  widget.imgPath, widget.status);
                              Alert(
                                  context: context,
                                  style: alertStyle,
                                  type: AlertType.success,
                                  title: "Success Check In",
                                  buttons: [
                                    DialogButton(
                                      child: Text(
                                        "OK",
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 20),
                                      ),
                                      onPressed: () => {
                                        if (hariBesar == true)
                                          {
                                            showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (BuildContext context) =>
                                                  AlertDialog(
                                                title: Text(
                                                  title.toString(),
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontSize: 20.0,
                                                      fontWeight:
                                                          FontWeight.w700),
                                                ),
                                                content: SingleChildScrollView(
                                                  child: ListBody(
                                                    children: [
                                                      Image.network(
                                                          Endpoint.urlGif +
                                                              "/" +
                                                              gif),
                                                      Text(
                                                        msg.toString(),
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                            fontSize: 18.0,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w400),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                actions: <Widget>[
                                                  TextButton(
                                                    child: const Text('OK'),
                                                    onPressed: () {
                                                      Future.delayed(
                                                          const Duration(
                                                              seconds: 2), () {
                                                        // setState(() {
                                                        //   _saving = false;
                                                        // });
                                                        ProfileScreen()
                                                            .createState()
                                                            .getProfil(
                                                                usrId, date);
                                                        Navigator
                                                            .pushNamedAndRemoveUntil(
                                                                context,
                                                                "/profile",
                                                                (Route<dynamic>
                                                                        routes) =>
                                                                    false);
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                            )
                                          }
                                        else
                                          {
                                            Future.delayed(
                                                const Duration(seconds: 2), () {
                                              // setState(() {
                                              //   _saving = false;
                                              // });
                                              ProfileScreen()
                                                  .createState()
                                                  .getProfil(usrId, date);
                                              Navigator.pushNamedAndRemoveUntil(
                                                  context,
                                                  "/profile",
                                                  (Route<dynamic> routes) =>
                                                      false);
                                            })
                                          }
                                      },
                                      width: 120,
                                    )
                                  ]).show();
                            }
                          } else {
                            if (prosesCheckout(usrId, clockIn,
                                    File(widget.imgPath), idShift, shift) ==
                                true) {
                              savePref(clockIn.substring(11, 16), true, true,
                                  widget.imgPath, widget.status);
                              Alert(
                                  context: context,
                                  style: alertStyle,
                                  type: AlertType.success,
                                  title: "Success Check Out",
//                                    desc: "Thank you for your efforts, Your dedication is imperative for the growth of our company",
                                  buttons: [
                                    DialogButton(
                                      child: Text(
                                        "OK",
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 20),
                                      ),
                                      onPressed: () => {
                                        // if(_get_profil == true){
                                        Future.delayed(Duration(seconds: 2),
                                            () {
                                          // setState(() {
                                          //   _saving = false;
                                          // });
                                          ProfileScreen()
                                              .createState()
                                              .getProfil(usrId, date);
                                          Navigator.pushNamedAndRemoveUntil(
                                              context,
                                              "/profile",
                                              (Route<dynamic> routes) => false);
                                        })
                                        // }else{
                                        //   Alert(
                                        //     context: context,
                                        //     style: alertStyle,
                                        //     type: AlertType.error,
                                        //     title: "Network Error!",
                                        //     desc: "Network not connected! Reload and try again!",
                                        //
                                        //   )
                                        // }
                                      },
                                      width: 120,
                                    )
                                  ]).show();
                            }
                          }
                        });
                      },
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  savePref(String clockIn, bool isCheckin, bool isCheckout, String imageUrl,
      String status) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      pref.setBool('isCheckin', isCheckin);
      pref.setBool('isCheckout', isCheckout);
      pref.setString('imageUrl', imageUrl);
      pref.setString('status', status);
    });
  }

  Future<Uint8List> getBytesFromFile() async {
    Uri myUri = Uri.parse(widget.imgPath);
    File photoFile = new File.fromUri(myUri);
    late Uint8List bytes;
    await photoFile.readAsBytes().then((value) {
      bytes = Uint8List.fromList(value);
      print('reading of bytes is completed');
      print(bytes.toString());
    }).catchError((onError) {
      print('Exception Error while reading audio from path:' +
          onError.toString());
    });
    return bytes;
  }

  Future<bool> prosesCheckin(String usrId, String clockIn, File imageFile,
      String idShift, String shift) async {
    var uri = Uri.parse(Endpoint.checkin);
    var request = new http.MultipartRequest("POST", uri);

    var multiPartFile = new http.MultipartFile.fromBytes(
      "foto",
      imageFile.readAsBytesSync(),
      filename: basename(imageFile.path),
    );

    request.files.add(multiPartFile);
    request.fields['employee_id'] = usrId;
    request.fields['clock_in'] = clockIn;
    request.fields['id_shift'] = idShift;
    request.fields['shift'] = shift;

    var response = await request.send();

    if (response.statusCode == 201) {
      return true;
    } else {
      print(response.statusCode);
      return false;
    }
  }

  Future<bool> prosesCheckout(String usrId, String clockIn, File imageFile,
      String idShift, String shift) async {
    var uri = Uri.parse(Endpoint.checkout);
    var request = new http.MultipartRequest("POST", uri);

    var multiPartFile = new http.MultipartFile.fromBytes(
      "foto",
      imageFile.readAsBytesSync(),
      filename: basename(imageFile.path),
    );

    request.files.add(multiPartFile);
    request.fields['employee_id'] = usrId;
    request.fields['clock_out'] = clockIn;
    request.fields['id_shift'] = idShift;
    request.fields['shift'] = shift;

    var response = await request.send();

    // if(response.statusCode == 201){
    //   SharedPreferences pref = await SharedPreferences.getInstance();
    //   var ip = pref.getString('IpAddress');
    //
    //   ApiServices services = ApiServices();
    //   var response = await services.Profil(ip, usrId, date);
    //   try {
    //     if (response.status == true) {
    //       setState(() {
    //         return true;
    //       });
    //     }
    //   } catch (err) {
    //     print("Cannot read");
    //   }
    //
    // }else{
    //   print(response.statusCode);
    //   return null;
    // }

    if (response.statusCode == 201) {
      return true;
    } else {
      print(response.statusCode);
      return false;
    }
  }
}
