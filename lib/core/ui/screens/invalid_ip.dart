import 'package:flutter/material.dart';
import 'package:login_absen/core/database/database_helper.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';

// bool _saving = false;

class InvalidIP extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: BodyInvalidIP());
  }
}

class BodyInvalidIP extends StatefulWidget {
  @override
  _BodyInvalidIPState createState() => _BodyInvalidIPState();
}

class _BodyInvalidIPState extends State<BodyInvalidIP> {
  late String userID;
  // static String date = new DateTime.now().toIso8601String().substring(0, 10);

  final dbHelper = DatabaseHelper.instance;

  @override
  initState() {
    super.initState();
//    checkConnection();
    // setState(() {
    //   _saving = true;
    // });
  }

  @override
  void dispose() {
    super.dispose();
  }

  getPref() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    final username = pref.getString('username');
    userID = pref.getString('userID')!;

    if (username != null) {
      Future.delayed(const Duration(microseconds: 2000), () {
        Navigator.pushNamedAndRemoveUntil(
            context, "/profile", (Route<dynamic> routes) => false);
      });
    } else {
      Future.delayed(const Duration(microseconds: 2000), () {
        Navigator.pushNamedAndRemoveUntil(
            context, "/login", (Route<dynamic> routes) => false);
      });
    }
  }

  Future<void> checkConnection() async {
//    var connectivityResult = await (Connectivity().checkConnectivity());
//    if (connectivityResult == ConnectivityResult.mobile) {
//
//      ToastUtils.show("No office Wifi connection");
//
//    } else if (connectivityResult == ConnectivityResult.wifi) {

    // setState(() {
    //   _saving = false;
    // });
//    }
  }

  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  void _onRefresh() async {
    // monitor network fetch
    await Future.delayed(Duration(milliseconds: 1000));
    // if failed,use refreshFailed()
    _refreshController.refreshCompleted();
    getPref();
  }

  void _onLoading() async {
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
      child: Column(
        children: <Widget>[
          // bagian header
          SizedBox(
            height: 50,
          ),
          Container(
            child: Image(
                alignment: Alignment.center,
                height: MediaQuery.of(context).size.height / 2,
                width: MediaQuery.of(context).size.width,
                image: AssetImage("assets/no_connection.png")),
          ),
          SizedBox(
            height: 20,
          ),
          ElevatedButton(
            onPressed: () {
              Future.delayed(const Duration(microseconds: 2000), () {
//                Navigator.pushNamedAndRemoveUntil(context, "/login_config", (Route<dynamic>routes)=>false);
                Navigator.pushNamed(context, '/login_config');
              });
            },
            // textColor: Colors.white,
            // padding: const EdgeInsets.all(0.0),
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
              child: const Text('Setting IP Address',
                  style: TextStyle(fontSize: 20, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
