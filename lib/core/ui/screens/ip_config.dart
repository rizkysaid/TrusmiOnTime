import 'package:flutter/material.dart';
import 'package:login_absen/core/config/endpoint.dart';
import 'package:login_absen/core/database/database_helper.dart';
import 'package:login_absen/core/services/ApiService.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IpConfig extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: BodyIpConfig());
  }
}

class BodyIpConfig extends StatefulWidget {
  @override
  _BodyIpConfigState createState() => _BodyIpConfigState();
}

class _BodyIpConfigState extends State<BodyIpConfig> {
  late String userID;
  // static String date = new DateTime.now().toIso8601String().substring(0, 10);

  final dbHelper = DatabaseHelper.instance;

  var ipconfig = TextEditingController();
  static bool showConSuccess = false;
  static bool showConFailed = false;

  @override
  initState() {
    super.initState();

    getPref();
  }

  @override
  void dispose() {
    super.dispose();
  }

  getPref() async {
    showIp();

    ApiServices services = ApiServices();
    var response = await services.checkKoneksi(Endpoint.baseUrl);
    if (response.data.userId.isEmpty) {
      Future.delayed(const Duration(microseconds: 2000), () {
        Navigator.pushNamedAndRemoveUntil(
            context, "/invalid_ip", (Route<dynamic> routes) => false);
      });
    } else {
      SharedPreferences pref = await SharedPreferences.getInstance();
      var username = pref.getString('username');
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
  }

  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  void _onRefresh() async {
    await Future.delayed(Duration(milliseconds: 1000));

    _refreshController.refreshCompleted();
    checkConnection();
  }

  void _onLoading() async {
    await Future.delayed(Duration(milliseconds: 1000));

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
      child: Scaffold(
        appBar: AppBar(
          title: Text('IP Configuration'),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: ipconfig,
                  key: Key('ip_address'),
                  decoration: InputDecoration(
                      hintText: 'IP Address',
                      labelText: 'IP Address',
                      labelStyle: TextStyle(color: Colors.red[900]),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red)),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red))),
                  style: TextStyle(
                    fontSize: 20.0,
                    color: Colors.black,
                  ),
                ),
              ),
              ElevatedButton(
                child: Text(
                  'Connect',
                  style: TextStyle(fontSize: 20),
                ),
                onPressed: () {
                  checkConnection();
                },
              ),
              Visibility(
                visible: showConSuccess,
                child: Column(
                  children: <Widget>[
                    Icon(
                      Icons.done,
                      color: Colors.green,
                      size: 30.0,
                      semanticLabel: 'Connection success!',
                    ),
                    Text(
                      'Connection success!',
                      style: TextStyle(color: Colors.green),
                    ),
                    ElevatedButton(
                      child: Text(
                        'Ok',
                        style: TextStyle(fontSize: 20),
                      ),
                      onPressed: () {
                        Future.delayed(const Duration(microseconds: 2000), () {
                          Navigator.pushNamedAndRemoveUntil(context, "/login",
                              (Route<dynamic> routes) => false);
                        });
                      },
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: showConFailed,
                child: Column(
                  children: <Widget>[
                    Icon(
                      Icons.close,
                      color: Colors.red,
                      size: 30.0,
                      semanticLabel: 'Connection failed!',
                    ),
                    Text(
                      'Connection failed!',
                      style: TextStyle(color: Colors.red),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showIp() async {
    ipconfig.text = Endpoint.baseUrl;
  }

  void checkConnection() async {
    ApiServices services = ApiServices();

    var ip = ipconfig.text;
    var response = await services.checkKoneksi(ip);
    print('response check_connection ip_config = ' + response.toString());

    if (response.data.userId.isEmpty) {
      print('stts sccss:' + showConSuccess.toString());
      setState(() {
        showConSuccess = true;
        showConFailed = false;
      });

      final rowsDeleted = await dbHelper.deleteAll();
      print('deleted $rowsDeleted row(s): row ');

      //insert new IP
      Map<String, dynamic> row = {
        DatabaseHelper.instance.columnIpAddress: ip,
        DatabaseHelper.instance.columnName: '',
        DatabaseHelper.instance.columnIsActive: 1
      };
      final id = await dbHelper.insert(row);
      print('inserted row id (ip_config/checkconnection): $id');
    } else {
      setState(() {
        showConSuccess = false;
        showConFailed = true;
      });
    }
  }
}
