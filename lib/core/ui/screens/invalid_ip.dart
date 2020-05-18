import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:login_absen/core/database/database_helper.dart';
import 'package:login_absen/core/services/ApiService.dart';
import 'package:login_absen/core/utils/toast_util.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InvalidIP extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return Scaffold(
        body: BodyInvalidIP()
    );
  }
}

class BodyInvalidIP extends StatefulWidget {

  @override
  _BodyInvalidIPState createState() => _BodyInvalidIPState();
}

class _BodyInvalidIPState extends State<BodyInvalidIP> {

  String userID;
  static String date = new DateTime.now().toIso8601String().substring(0, 10);

  final dbHelper = DatabaseHelper.instance;

  @override
  initState() {
    super.initState();
//    checkConnection();
  }

  @override
  void dispose() {
    super.dispose();

  }

  getPref()async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    final username = pref.getString('username');
    userID = pref.getString('userID');

//    final allRows = await dbHelper.queryAllRows();
//    print('query all rows:');
//    allRows.forEach((row) => print(row));
//    var ip = allRows[0]['ip_address'];
    var ip = pref.getString('IpAddress');

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
      child: Column(
        children: <Widget>[
          // bagian header
          SizedBox(height: 50,),
          Container(
            child: Image(
                alignment: Alignment.center,
                height: MediaQuery.of(context).size.height/2,
                width: MediaQuery.of(context).size.width,
                image: AssetImage("assets/no_connection.png")
            ),
          ),
          SizedBox(height: 20,),
          RaisedButton(
            onPressed: () {
              Future.delayed(const Duration(microseconds: 2000),(){
                Navigator.pushNamedAndRemoveUntil(context, "/ip_config", (Route<dynamic>routes)=>false);
              });
            },
            textColor: Colors.white,
            padding: const EdgeInsets.all(0.0),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    Color(0xFF0D47A1),
                    Color(0xFF1976D2),
                    Color(0xFF42A5F5),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(10.0),
              child:
              const Text('Setting IP Address', style: TextStyle(fontSize: 20)),
            ),
          ),
        ],
      ),
    );
  }

//  void show_ip() async {
//    final allRows = await dbHelper.queryAllRows();
//    print('query all rows:');
//    allRows.forEach((row) => print(row));
//    ip = allRows[0]['ip_address'];
//    print(ip);
//  }
}

