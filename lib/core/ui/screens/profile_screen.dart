import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:login_absen/core/services/ApiService.dart';
import 'package:login_absen/core/ui/widget/CircleButton.dart';
import 'package:login_absen/core/ui/widget/CircleButtonOut.dart';
import 'package:login_absen/core/ui/widget/primary_button.dart';
import 'package:login_absen/core/utils/toast_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ScreenArguments.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  String username;
  String userID;
  static String nama;
  static String jabatan;
  static String clockin;
  static String imageUrl;
  static String message;
  static String _status;
  static bool statusPhoto = false;
  static bool statusIcon = true;
  static Color _colorButton = Colors.blue;

  static String date = new DateTime.now().toIso8601String().substring(0, 10);
  static String _toolTip = "Check In";

  @override
  void initState() {
    super.initState();
    getPref();
  }


  Future<void> getProfil(userID, date) async {
    ApiServices services = ApiServices();
    var response = await services.Profil(userID, date);
    String dataNama = response.data.nama.toString();
    String dataJabatan = response.data.jabatan.toString();
    String dataClockIn = response.data.clockIn.toString();
    String dataImageUrl = response.data.photoIn.toString();
    message = response.message.toString();

    if (dataClockIn == "--:--"){
      statusPhoto = false;
      statusIcon = true;
      imageUrl = "";
      _colorButton = Colors.blue;
    } else{
      clockin = dataClockIn;
      statusPhoto = true;
      statusIcon = false;
      imageUrl = dataImageUrl;
      _colorButton = Colors.deepOrange;
    }

    try {
      if (response.status == true) {
        setState(() {
          nama = dataNama;
          jabatan = dataJabatan;
        });
      }
    } catch (err) {
      print("Cannot read");
    }

  }

  getPref() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    setState(() {
      username = pref.getString('username');
      userID = pref.getString('userID');
      clockin = pref.get('clock_in');
      imageUrl = pref.getString('imageUrl');
      _status = pref.getString('status');
    });

    if (username != null) {
      getProfil(userID, date);
    } else {
      Navigator.pushNamedAndRemoveUntil(
          context, "/login", (Route<dynamic> routes) => false);
    }

    if(clockin == null){
      clockin = "--:--";
    }

    if(imageUrl == "-"){
      imageUrl = "";
    }

    if(_status == null){
      _status = "checkin";
    }else{
      _status = "checkout";
    }


    print("_status : "+_status);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title : Text("onTime",
          style: TextStyle(color: Colors.white),
        ),
      iconTheme: new IconThemeData(color: Colors.white),
//        backgroundColor: Colors.blue,
      flexibleSpace: Container(
        decoration: new BoxDecoration(
          gradient: new LinearGradient(
            colors: [
              const Color(0xFF3366FF),
              const Color(0xFF00CCFF)
            ],
            begin: const FractionalOffset(0.0, 0.0),
            end: const FractionalOffset(1.0, 0.0),
            stops: [0.0, 1.0],
            tileMode: TileMode.clamp
          )
        ),
      ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: new CircleAvatar(),
              decoration: BoxDecoration(
                color: Colors.blue
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.exit_to_app),
                title: Text('Log Out'),
                onTap: () => logout()
              ),
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints viewportConstraints){
          return SingleChildScrollView(
            child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: viewportConstraints.maxHeight
          ),
              child: Column(
                children: <Widget>[
                  // bagian header
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: (MediaQuery.of(context).size.height / 2) +
                        (MediaQuery.of(context).size.height / 16),
                    color: Colors.blue,
//            child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(height: 20),
                        Container(
                          width: 300.0,
                          height: 300.0,
                          decoration: new BoxDecoration(
                            color: Colors.lightBlue[50].withOpacity(0.2),
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
                                      image: new NetworkImage(imageUrl.toString()),
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
                                  style: TextStyle(color: Colors.white)),
                              SizedBox(height: 20),
                              Text(date.toString(),
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold)),
                              Text("Jumat, 17-12-2020",
                                  style: TextStyle(color: Colors.white, fontSize: 12))
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          message.toString(),
                          style: TextStyle(
                              color: Colors.white
                          ),                )
                      ],
                    ),
//            ),
                  ),

                  //bagian field
                  Padding(
                    padding: EdgeInsets.only(left: 20, right: 20, top: 20),
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Column(children: <Widget>[
                              Text("Start Time", style: TextStyle(fontSize: 18)),
                              Text(clockin.toString(),
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold)),
                            ]),
                            Container(
                                height: 30,
                                child: VerticalDivider(
                                  color: Colors.lightBlue,
                                  thickness: 3,
                                )),
                            Column(children: <Widget>[
                              Text("End Time", style: TextStyle(fontSize: 18)),
                              Text("--:--",
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold)),
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
        }
      ),
      bottomNavigationBar:
      BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Container(height: 50.0),
      ),
      floatingActionButton:
      Container(
        height: 80,
        width: 80,
        child: FloatingActionButton(
          onPressed: () => {
          Navigator.pushNamed(context, "/camera",
                arguments: ScreenArguments(userID, _status)
            )
          },
          tooltip: _toolTip,
          backgroundColor: _colorButton,
          child: Icon(Icons.alarm_on, color: Colors.white, size: 40),
        )
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );

  }

  logout() {
    ToastUtils.show("waiting logout...");
    savePref();

    Future.delayed(const Duration(microseconds: 2000), () {
      ToastUtils.show("Success logout...");
      Navigator.pushNamedAndRemoveUntil(
          context, "/login", (Route<dynamic> routes) => false);
    });
  }

  savePref() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      pref.remove('username');
      pref.remove('clock_in');
    });
  }
}
