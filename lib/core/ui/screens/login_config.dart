import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:login_absen/core/database/database_config.dart';
import 'package:login_absen/core/utils/toast_util.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class LoginConfig extends StatefulWidget {
  @override
  _LoginConfigState createState() => _LoginConfigState();
}

class _LoginConfigState extends State<LoginConfig> {
  @override
  void initState() {
    super.initState();
//    checkConnection();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> checkConnection() async {
//    var connectivityResult = await (Connectivity().checkConnectivity());
//    if (connectivityResult == ConnectivityResult.mobile) {
//
//      Future.delayed(const Duration(microseconds: 2000),(){
//        Navigator.pushNamedAndRemoveUntil(context, "/no_connection", (Route<dynamic>routes)=>false);
//      });
//
//    } else if (connectivityResult == ConnectivityResult.wifi) {
//
//
//    }
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
      footer: CustomFooter(
        builder: (BuildContext context, LoadStatus mode) {
          Widget body;
          if (mode == LoadStatus.idle) {
            body = Text("pull up load");
          } else if (mode == LoadStatus.loading) {
            body = CupertinoActivityIndicator();
          } else if (mode == LoadStatus.failed) {
            body = Text("Load Failed!Click retry!");
          } else if (mode == LoadStatus.canLoading) {
            body = Text("release to load more");
          } else {
            body = Text("No more Data");
          }
          return Container(
            height: 55.0,
            child: Center(child: body),
          );
        },
      ),
      controller: _refreshController,
      onRefresh: _onRefresh,
      onLoading: _onLoading,
      child: Scaffold(
        body: SingleChildScrollView(child: LoginBody()),
      ),
    );
  }
}

class LoginBody extends StatefulWidget {
  @override
  _LoginBodyState createState() => _LoginBodyState();
}

class _LoginBodyState extends State<LoginBody> {
  var usernameController = TextEditingController();
  var passwordController = TextEditingController();

  String username = '';
  String password = '';

  @override
  void initState() {
    super.initState();
  }

  Future<void> prosesLogin() async {
    if (usernameController.text.isNotEmpty &&
        passwordController.text.isNotEmpty) {
      // String ip;
      ToastUtils.show("Check Login ...");
      final dbHelper = DatabaseConfigHelper.instance;
      final allRows = await dbHelper.queryAllRows();
      print('query all rows: ' + allRows.toList().toString());
      print('Length = ' + allRows.length.toString());

      allRows.forEach((row) => print(row));
      username = allRows[0]['username'];
      password = allRows[0]['password'];

      if (usernameController.text == username &&
          passwordController.text == password) {
        Future.delayed(const Duration(microseconds: 2000), () {
//          Navigator.pushNamedAndRemoveUntil(context, "/ip_config", (Route<dynamic>routes)=>false);
          Navigator.pushNamed(context, '/ip_config');
        });
      } else {
        ToastUtils.show("Username / password konfigurasi salah!");
      }
    } else {
      ToastUtils.show("Please Input All Fields");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height / 6,
          decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('assets/background_login.png'),
                  fit: BoxFit.cover)),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Login Configuration',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20),
                )
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 30),
          child: Column(
            children: <Widget>[
              _username(context),
              _password(context),
              _buttonLogin(context),
            ],
          ),
        )
      ],
    );
  }

  Widget _username(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: TextFormField(
        controller: usernameController,
        validator: validateUser,
        onSaved: (String value) {
          username = value;
        },
        key: Key('username'),
        decoration: InputDecoration(
            hintText: 'username',
            labelText: 'username',
            labelStyle: TextStyle(color: Colors.red[900]),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.red[900])),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.red[900]))),
        style: TextStyle(
          fontSize: 20.0,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _password(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: TextFormField(
          controller: passwordController,
          onSaved: (String value) {
            password = value;
          },
          key: Key('password'),
          decoration: InputDecoration(
              hintText: 'password',
              labelText: 'password',
              labelStyle: TextStyle(color: Colors.red[900]),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.red[900])),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.red[900]))),
          style: TextStyle(fontSize: 20.0, color: Colors.black),
          obscureText: true),
    );
  }

  Widget _buttonLogin(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(8.0),
        child: new InkWell(
            onTap: () => prosesLogin(),
            child: new Container(
              height: 50.0,
              decoration: new BoxDecoration(
                color: Colors.red[800],
                border: new Border.all(color: Colors.white, width: 2.0),
                borderRadius: new BorderRadius.circular(10.0),
              ),
              child: new Center(
                  child: new Text('Login',
                      style:
                          new TextStyle(fontSize: 18.0, color: Colors.white))),
            )));
  }

  String validateUser(String value) {
    if (value.isEmpty) {
      return 'Username harus diisi';
    }
    return null;
  }
}
