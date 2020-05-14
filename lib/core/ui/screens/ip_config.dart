import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:login_absen/core/database/database_helper.dart';
import 'package:login_absen/core/services/ApiService.dart';
import 'package:login_absen/core/utils/toast_util.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IpConfig extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return Scaffold(
        body: BodyIpConfig()
    );
  }
}

class BodyIpConfig extends StatefulWidget {

  @override
  _BodyIpConfigState createState() => _BodyIpConfigState();
}

class _BodyIpConfigState extends State<BodyIpConfig> {

  String userID;
  static String date = new DateTime.now().toIso8601String().substring(0, 10);

  final dbHelper = DatabaseHelper.instance;

  var ipconfig = TextEditingController();
  static bool show_con_success = false;
  static bool show_con_failed = false;

  @override
  initState() {
    super.initState();
//    checkConnection();
    show_ip();
  }

  @override
  void dispose() {
    super.dispose();

  }

  getPref()async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    final username = pref.getString('username');
    userID = pref.getString('userID');

    final allRows = await dbHelper.queryAllRows();
    print('query all rows:');
    allRows.forEach((row) => print(row));
    var ip = allRows[0]['ip_address'];

    ApiServices services = ApiServices();
    var response = await services.Profil(ip, userID, date);
    if (response == null) {
//      ToastUtils.show("Error Connecting To Server");
      Future.delayed(const Duration(microseconds: 2000), () {
        Navigator.pushNamedAndRemoveUntil(
            context, "/invalid_ip", (Route<dynamic>routes) => false);
      });
    } else {
      if (username != null) {
        Future.delayed(const Duration(microseconds: 2000), () {
          Navigator.pushNamedAndRemoveUntil(
              context, "/profile", (Route<dynamic>routes) => false);
        });
      } else {
        Future.delayed(const Duration(microseconds: 2000), () {
          Navigator.pushNamedAndRemoveUntil(
              context, "/login", (Route<dynamic>routes) => false);
        });
      }
    }
  }


  Future<void>checkConnection() async{
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      // I am connected to a mobile network.
      ToastUtils.show("No office Wifi connection");

    } else if (connectivityResult == ConnectivityResult.wifi) {
      // I am connected to a wifi network.
//      Future.delayed(const Duration(microseconds: 2000),(){
//        ToastUtils.show("Connected to server");
//        Navigator.pushNamedAndRemoveUntil(context, "/profile", (Route<dynamic>routes)=>false);
//      });

      getPref();
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


  @override
  Widget build(BuildContext context) {
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
          title: Text('IP Configuration'),
        ),
        body: Center(
          child: Column(
//            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: ipconfig,
//                  validator: validateUser,
//                  onSaved: (String value){
//                    username = value;
//                  },
                  key: Key('ip_address'),
                  decoration: InputDecoration(
                      hintText: 'IP Address', labelText: 'IP Address',
                      labelStyle: TextStyle(color: Colors.red[900]),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.red[900])),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.red[900]))
                  ),
                  style: TextStyle(
                    fontSize: 20.0, color: Colors.black,
                  ),
                ),
              ),
//               RaisedButton(
//                child: Text('insert', style: TextStyle(fontSize: 20),),
//                onPressed: () {_insert();},
//              ),
              RaisedButton(
                child: Text('Connect', style: TextStyle(fontSize: 20),),
                onPressed: () {check_connection();},
              ),
//              RaisedButton(
//                child: Text('update', style: TextStyle(fontSize: 20),),
//                onPressed: () {_update();},
//              ),
//              RaisedButton(
//                child: Text('delete', style: TextStyle(fontSize: 20),),
//                onPressed: () {_delete();},
//              ),
            Visibility(
              visible: show_con_success,
              child: Column(
                children: <Widget>[
                  Icon(
                    Icons.done,
                    color: Colors.green,
                    size: 30.0,
                    semanticLabel: 'Connection success!',
                  ),
                  Text('Connection success!', style: TextStyle(color: Colors.green),),
                  RaisedButton(
                    child: Text('Ok', style: TextStyle(fontSize: 20),),
                    onPressed: () {
                      Future.delayed(const Duration(microseconds: 2000),(){
                        Navigator.pushNamedAndRemoveUntil(context, "/login", (Route<dynamic>routes)=>false);
                      });
                    },
                  ),
                ],
              ),
            ),
              Visibility(
                visible: show_con_failed,
                child: Column(
                  children: <Widget>[
                    Icon(
                      Icons.close,
                      color: Colors.red,
                      size: 30.0,
                      semanticLabel: 'Connection failed!',
                    ),
                    Text('Connection failed!', style: TextStyle(color: Colors.red),)
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  // Button onPressed methods

  void _insert() async {
    // row to insert
//    Map<String, dynamic> row = {
//      DatabaseHelper.columnIpAddress : 'http://192.168.1.117/absensi/api',
//      DatabaseHelper.columnName : 'Trusmi Holding Office',
//      DatabaseHelper.columnIsActive  : 1
//    };
//    final id = await dbHelper.insert(row);
//    print('inserted row id: $id');
  }

  void show_ip() async {
    final allRows = await dbHelper.queryAllRows();
    print('query all rows:');
    allRows.forEach((row) => print(row));
    var ip = '';
    ip = allRows[0]['ip_address'];
    print(ip);
    ipconfig.text = ip.toString();
  }

  void _update() async {
    // row to update
//    Map<String, dynamic> row = {
//      DatabaseHelper.columnId   : 1,
//      DatabaseHelper.columnName : 'Mary',
//      DatabaseHelper.columnAge  : 32
//    };
//    final rowsAffected = await dbHelper.update(row);
//    print('updated $rowsAffected row(s)');
  }

  void _delete() async {
//     Assuming that the number of rows is the id for the last row.
    final id = await dbHelper.queryRowCount();
    final rowsDeleted = await dbHelper.delete(id);
    print('deleted $rowsDeleted row(s): row $id');

  }

  void check_connection() async{
    ApiServices services = ApiServices();

    var ip = ipconfig.text;
    var response = await services.CheckKoneksi(ip);
    print('responsenya'+response.toString());

    if(response != null){

      print('stts sccss:'+show_con_success.toString());
      setState(() {
        show_con_success = true;
        show_con_failed = false;
      });

      //delete IP
      final rowsDeleted = await dbHelper.deleteAll();
      print('deleted $rowsDeleted row(s): row ');

      //insert new IP
      Map<String, dynamic> row = {
        DatabaseHelper.columnIpAddress : ip,
        DatabaseHelper.columnName : '',
        DatabaseHelper.columnIsActive  : 1
      };
      final id = await dbHelper.insert(row);
      print('inserted row id: $id');
    }else{
      setState(() {
        show_con_success = false;
        show_con_failed = true;
      });
    }

  }
}

