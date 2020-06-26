import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:login_absen/core/config/endpoint.dart';
import 'package:login_absen/core/config/about.dart';
import 'package:login_absen/core/database/database_helper.dart';
import 'package:login_absen/core/services/ApiService.dart';
import 'package:login_absen/core/utils/toast_util.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ScreenArguments.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:date_format/date_format.dart';
//import 'package:url_launcher/url_launcher.dart';
//import 'package:package_info/package_info.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>{

  String username;
  String userID;
  static String nama = '';
  static String jabatan = '';
  static String clockin;
  static String clockout;
  static String imageUrl;
  static String message = '';
  static String total_work = '';
  static String _status;
  static bool statusPhoto = false;
  static bool statusIcon = true;
  static bool _visibleButton = true;
  static bool _statusTotalWork = false;
  static Color _colorButton = Colors.red[700];
  static Timer timer;

  String date_in = '';
  String date_out = '';
  String id_shift = '';
  String shift_in = '';
  String shift_out = '';
  String shift;

  static String date = new DateTime.now().toIso8601String().substring(0, 10);
  static String _toolTip = "Check In";
  String photo_profile;

  String _timeString;
  String _hariTanggal;

  String dateId = formatDate(DateTime.now(), [dd, '/', mm, '/', yy]);

  @override
  void initState() {

    super.initState();

    checkConnection();

      getPref();

      _timeString = _formatDateTime(DateTime.now());
      _hariTanggal = _formatHariTanggal(DateTime.now());
      timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
        final DateTime now = DateTime.now();
        final DateTime HTnow = DateTime.now();
        final String formattedDateTime = _formatDateTime(now);
        final String formattedHariTanggal = _formatHariTanggal(HTnow);

        _hariTanggal = formattedHariTanggal;
        _timeString = formattedDateTime;
        if(this.mounted) {
          setState(() {
            _timeString = formattedDateTime;
          });
        }
      });

  }

  @override
  void dispose(){
    super.dispose();
//    timer.cancel();
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
      String ip;
      final dbHelper = DatabaseHelper.instance;
      final allRows = await dbHelper.queryAllRows();
      print('query all rows: '+allRows.toList().toString());
      print('Length = '+allRows.length.toString());

      if(allRows.length != 0){

        allRows.forEach((row) => print(row));
        ip = allRows[0]['ip_address'];

      }else{
        ip = Endpoint.base_url;
      }


      ApiServices services = ApiServices();
      var response = await services.Profil(ip, userID, date);
      print("IP in profile_screen = "+ip);
      print("UserID in profile_screen = "+userID.toString());
      print("date in profile_screen = "+date.toString());
      print("Hari ini = "+dateId.toString());

      if(userID == null){
        Future.delayed(const Duration(microseconds: 2000),(){
          Navigator.pushNamedAndRemoveUntil(context, "/login", (Route<dynamic>routes)=>false);
        });
      }else{
        if(response == null){
          ToastUtils.show("Error Connecting To Server");
          Future.delayed(const Duration(microseconds: 2000),(){
            Navigator.pushNamedAndRemoveUntil(context, "/invalid_ip", (Route<dynamic>routes)=>false);
          });
        }
      }

    }
  }

  RefreshController _refreshController = RefreshController(initialRefresh: false);


  void _onRefresh() async{
    // monitor network fetch
    await Future.delayed(Duration(milliseconds: 1000));
    // if failed,use refreshFailed()
    _refreshController.refreshCompleted();
    checkConnection();
  }

  void _onLoading() async{
    // monitor network fetch
    await Future.delayed(Duration(milliseconds: 1000));
    // if failed,use loadFailed(),if no data return,use LoadNodata()

    _refreshController.loadComplete();
  }

  Future<void> getProfil(userID, date) async {

      String ip;
      final dbHelper = DatabaseHelper.instance;
      final allRows = await dbHelper.queryAllRows();
      print('query all rows:');
      print('Length = '+allRows.length.toString());

      if(allRows.length != 0){

//        allRows.forEach((row) => print(row));
        ip = allRows[0]['ip_address'];

      }else{
        ip = Endpoint.base_url;
      }

      ApiServices services = ApiServices();
      var response = await services.Profil(ip, userID, date);

      if(response == null){
        Future.delayed(const Duration(microseconds: 2000),(){
          Navigator.pushNamedAndRemoveUntil(context, "/invalid_ip", (Route<dynamic>routes)=>false);
        });
      }else{
        print('Ini responsnya : '+response.toString());
        String dataNama = response.data.nama.toString();
        String dataJabatan = response.data.jabatan.toString();
        String dataClockIn = response.data.clockIn.toString();
        String dataClockOut = response.data.clockOut.toString();
        String dataImageUrl = response.data.photoIn.toString();
        message = response.message.toString();
        total_work = response.data.totalWork.toString();
        photo_profile = response.data.fotoProfil.toString();
        date_in = response.data.dateIn.toString();
        date_out = response.data.dateOut.toString();

        id_shift = response.data.idShift.toString();
        shift_in = response.data.shiftIn.toString();
        shift_out = response.data.shiftOut.toString();

        SharedPreferences pref = await SharedPreferences.getInstance();
        setState(() {
          pref.setString('id_shift', id_shift);
//          pref.setString('shift_in', shift_in);
//          pref.setString('shift_out', shift_out);
        });

        nama = dataNama;
        jabatan = dataJabatan;

        if (dataClockIn == "--:--"){
          statusPhoto = false;
          statusIcon = true;
          imageUrl = "";
          _colorButton = Colors.red[700];
          clockout = dataClockOut;
          clockin = dataClockIn;
          _statusTotalWork = false;
          _visibleButton = true;
          _status = "checkin";
          shift = shift_in;
          pref.remove('shift');
          pref.setString('shift', shift_in);
        }else if (dataClockOut == "--:--"){
          clockin = dataClockIn;
          clockout = dataClockOut;
          statusPhoto = true;
          statusIcon = false;
          imageUrl = dataImageUrl;
          _colorButton = Colors.deepOrange;
          _statusTotalWork = false;
          _visibleButton = true;
          _status = "checkout";
          shift = shift_out;
          pref.remove('shift');
          pref.setString('shift', shift_out);
        }else if (date_out != dateId){
          clockin = dataClockIn;
          clockout = "--:--";
          date_out = "";
          statusPhoto = true;
          statusIcon = false;
          imageUrl = dataImageUrl;
          _colorButton = Colors.red[700];
          _statusTotalWork = false;
          _visibleButton = true;
          _status = "checkin";
          shift = shift_in;
          pref.remove('shift');
          pref.setString('shift', shift_in);
        }else if(id_shift == '3'){
          statusPhoto = true;
          statusIcon = false;
          clockin = dataClockIn;
          clockout = dataClockOut;
          imageUrl = dataImageUrl;
          _visibleButton = true;
          _statusTotalWork = true;
          _status = "checkin";
          shift = shift_in;
          pref.remove('shift');
          pref.setString('shift', shift_in);
          _colorButton = Colors.red[700];
        }else{
          statusPhoto = true;
          statusIcon = false;
          clockin = dataClockIn;
          clockout = dataClockOut;
          imageUrl = dataImageUrl;
          _visibleButton = false;
          _statusTotalWork = true;
          shift = shift_in;
          pref.remove('shift');
          pref.setString('shift', shift_in);
          _colorButton = Colors.red[700];
          _status = "checkin";
        }

        try {
          if (response.status == true) {
            setState(() {
              nama = dataNama;
              jabatan = dataJabatan;
            });
          }else{
            Future.delayed(const Duration(microseconds: 2000),(){
              Navigator.pushNamedAndRemoveUntil(context, "/no_connection", (Route<dynamic>routes)=>false);
            });
          }
        } catch (err) {
          print("Cannot read");
        }
      }

//    }

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

      if(clockout == null){
        clockout = "--:--";
      }

      if(imageUrl == "-"){
        imageUrl = "";
      }

      if(_status == null){
        _status = "checkin";
      }


//      PackageInfo packageInfo = await PackageInfo.fromPlatform();
//
//      String appName = packageInfo.appName;
//      String packageName = packageInfo.packageName;
//      String version = packageInfo.version;
//      String buildNumber = packageInfo.buildNumber;

  }

  @override
  Widget build(BuildContext context) {

    String version = About.version;

    return SmartRefresher(
      enablePullDown: true,
      enablePullUp: false,
      header: WaterDropMaterialHeader(),
      footer: CustomFooter(
        builder: (BuildContext context,LoadStatus mode){
          Widget body ;
          if(mode==LoadStatus.idle){
            body =  Text("pull up load");
          }
          else if(mode==LoadStatus.loading){
            body =  CupertinoActivityIndicator();
          }
          else if(mode == LoadStatus.failed){
            body = Text("Load Failed!Click retry!");
          }
          else if(mode == LoadStatus.canLoading){
            body = Text("release to load more");
          }
          else{
            body = Text("No more Data");
          }
          return Container(
            height: 55.0,
            child: Center(child:body),
          );
        },
      ),
      controller: _refreshController,
      onRefresh: _onRefresh,
      onLoading: _onLoading,
      child: Scaffold(
        appBar: AppBar(
          brightness: Brightness.dark,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo_png_ontime.png',
                fit: BoxFit.contain,
                width: MediaQuery.of(context).size.width/4,
                height: MediaQuery.of(context).size.height/14,
              ),
              Container(padding: const EdgeInsets.fromLTRB(0, 0, 50, 0),)
            ]
          ),
        iconTheme: new IconThemeData(color: Colors.white),
//        backgroundColor: Colors.blue,
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
              tileMode: TileMode.clamp
            )
          ),
        ),
        ),
        drawer: Drawer(
          elevation: 1.5,
          child: Column(
            children: <Widget>[
              DrawerHeader(
                padding: EdgeInsets.zero,
                decoration: BoxDecoration(
                    color: Colors.red[700]
                ),
                child: Row(
                  children: <Widget>[
                    SizedBox(width: 15),
                    new CircleAvatar(
                      radius: 30.0,
                      child: ClipOval(
                        child: Image.network(photo_profile.toString(),
                            width: 125,
                            height: 125,
                            fit: BoxFit.cover
                        ),
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
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          jabatan.toString(),
                          textAlign: TextAlign.left,
                          style: TextStyle(fontSize: 14, color: Colors.white),
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
                      leading: Icon(Icons.exit_to_app),
                      title: Text('Log Out'),
                        onTap: () => logout()
                    )
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
                          title: new Center(
                              child: Text(version)
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              )
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
                            (MediaQuery.of(context).size.height / 6),
//                    color: Colors.red[900],
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/background.png'),
                            fit: BoxFit.cover
                          )
                        ),

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
                                  Text(_timeString.toString(),
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 25,
                                          fontWeight: FontWeight.bold)),
                                  Text(_hariTanggal.toString(),
                                      style: TextStyle(color: Colors.white, fontSize: 12))
                                ],
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              message.toString(),
                              style: TextStyle(
                                  color: Colors.white
                              ),
                            ),
                            SizedBox(height: 20),
                            Visibility(
                              visible: _statusTotalWork,
                              child: Column(children: <Widget>[
                                Text("Total Work", style: TextStyle(fontSize: 16, color: Colors.white)),
                                Text(total_work.toString(),
                                    style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white
                                    )
                                ),
                              ]),
                            ),
                          ],
                        ),
//            ),
                      ),

                      //bagian field
                      Padding(
                        padding: EdgeInsets.only(left: 20, right: 20, top: 15),
                        child: Column(
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                Column(children: <Widget>[
                                  Text("Start Time", style: TextStyle(fontSize: 18)),
                                  Text(clockin.toString(),
                                      style: TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.bold)
                                  ),
                                  Text(date_in.toString(),
                                      style: TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ]),
                                Container(
                                    height: 10,
                                    width: 10,
//                                    child: VerticalDivider(
//                                      color: Colors.redAccent,
//                                      thickness: 3,
//                                    ),
                                ),
                                Column(children: <Widget>[
                                  Text("End Time", style: TextStyle(fontSize: 18)),
                                  Text(clockout.toString(),
                                      style: TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.bold)
                                  ),
                                  Text(date_out.toString(),
                                    style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold),
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
            }
          ),
        bottomNavigationBar:
        BottomAppBar(
          shape: const CircularNotchedRectangle(),
          child: Container(height: 50.0),
        ),
        floatingActionButton:
        Visibility(
          visible: _visibleButton,
          child: Container(
            height: 80,
            width: 80,
            child: FloatingActionButton(
              onPressed: () => {
                check_status(userID)
              },
              tooltip: _toolTip,
              backgroundColor: _colorButton,
              child: Icon(Icons.alarm_on, color: Colors.white, size: 40),
            )
          ),
        ),

        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  String _formatDateTime(DateTime dateTime){
    return DateFormat('HH:mm:ss').format(dateTime);
  }
  String _formatHariTanggal(DateTime dateTime){
    return DateFormat('EEE, dd MMM yyyy').format(dateTime);
  }

  logout() {
    savePref();

    Future.delayed(const Duration(microseconds: 2000), () {
      Navigator.pushNamedAndRemoveUntil(
          context, "/login", (Route<dynamic> routes) => false);
    });
  }

  savePref() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      pref.remove('username');
      pref.remove('clock_in');
//      pref.remove('_status');
    });
  }

//  goToWebsite() async{
//    const url = "http://192.168.23.23/hr/admin";
//    if(await canLaunch(url)){
//      await launch(url);
//    }else{
//      ToastUtils.show("Can not launch website");
//    }
//  }

  check_status(userId) async{
    String ip;
    final dbHelper = DatabaseHelper.instance;
    final allRows = await dbHelper.queryAllRows();
    print('query all rows:');
    print('Length = '+allRows.length.toString());

    if(allRows.length != 0){

//        allRows.forEach((row) => print(row));
      ip = allRows[0]['ip_address'];

    }else{
      ip = Endpoint.base_url;
    }

    ApiServices services = ApiServices();
    var response = await services.CheckStatus(ip, userID);

    print(response.data.aktif);

    if(response.data.aktif == '1'){
        Navigator.pushNamed(context, "/camera",
          arguments: ScreenArguments(userID, _status, id_shift, shift)
        );
//        print("shift="+shift+" - idshift="+id_shift+" - status="+_status)
    }else{
      Alert(
          context: context,
          style: alertStyle,
          type: AlertType.error,
          title: "Anda tidak bisa melakukan absen!",
          desc: "User anda telah dinonaktifkan.",
          buttons: [
            DialogButton(
              child: Text(
                "Logout",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              onPressed: ()=> {
//                Future.delayed(const Duration(microseconds: 2000),(){
//                  Navigator.pushNamedAndRemoveUntil(context, "/profile", (Route<dynamic>routes)=>false);
//                })
                logout()
              },
              width: 120,
            )
          ]
      ).show();
    }

  }
  var alertStyle = AlertStyle(
      animationType: AnimationType.fromTop,
      isCloseButton: false,
      isOverlayTapDismiss: false,
      descStyle: TextStyle(fontWeight: FontWeight.bold),
      animationDuration: Duration(milliseconds: 400),
      alertBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0.0),
        side: BorderSide(
            color: Colors.grey
        ),
      ),
      titleStyle: TextStyle(
          color: Colors.red
      )
  );

}


