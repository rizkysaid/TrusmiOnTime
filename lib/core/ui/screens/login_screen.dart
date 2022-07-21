import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:login_absen/core/bloc/login/login_bloc.dart';
import 'package:login_absen/core/config/endpoint.dart';
import 'package:login_absen/core/database/database_helper.dart';
import 'package:login_absen/core/utils/toast_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:login_absen/core/config/about.dart';
import 'package:fluttertoast/fluttertoast.dart';

// bool _saving = false;

final LoginBloc _loginBloc = LoginBloc();
CancelToken apiToken = CancelToken();

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    getPref();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  void _onRefresh() async {
    await Future.delayed(Duration(milliseconds: 1000));

    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    await Future.delayed(Duration(milliseconds: 1000));

    _refreshController.loadComplete();
  }

  var usernameController = TextEditingController();
  var passwordController = TextEditingController();

  String username = '';
  String password = '';

  savePref(
      String username, String userID, String pass, String departmentId) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      pref.setString('username', username);
      pref.setString('userID', userID);
      pref.setString('password', pass);
      pref.setString('departmentId', departmentId);
      pref.setString('id_shift', '1');
    });
  }

  getPref() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    var username = pref.getString('username');
    if (username != null) {
      Future.delayed(const Duration(microseconds: 2000), () {
        Navigator.pushNamedAndRemoveUntil(
            context, "/profile", (Route<dynamic> routes) => false);
      });
    }
  }

  Future<void> prosesLogin() async {
    if (usernameController.text != '' && passwordController.text != '') {
      String ip;
      // ToastUtils.show("Check Login ...");
      final dbHelper = DatabaseHelper.instance;
      final allRows = await dbHelper.queryAllRows();
      // print('query all rows: ' + allRows.toList().toString());
      // print('Length = ' + allRows.length.toString());

      if (allRows.length != 0) {
        allRows.forEach((row) => print(row));
        ip = allRows[0]['ip_address'];
      } else {
        ip = Endpoint.baseUrl;
      }

      _loginBloc.add(LoadLogin());

      _loginBloc.add(CheckAuth(
          ip: ip,
          username: usernameController.text,
          password: passwordController.text,
          apiToken: apiToken));
    } else {
      ToastUtils.show("Please Input All Fields");
    }
  }

  String version = About.version;

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
      enablePullDown: true,
      enablePullUp: false,
      header: WaterDropMaterialHeader(),
      controller: _refreshController,
      onRefresh: _onRefresh,
      onLoading: _onLoading,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
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
                      Image(
                          alignment: Alignment.center,
                          height: MediaQuery.of(context).size.width / 8,
                          width: MediaQuery.of(context).size.width / 2,
                          image: AssetImage("assets/logo_png_ontime.png")),
                      Text(version, style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),

              //bagian field
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
          ),
        ),
      ),
    );
  }

  Widget _username(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: TextFormField(
        controller: usernameController,
        validator: (value) => "Username harus diisi",
        onSaved: (value) {
          username = value!;
        },
        key: Key('username'),
        decoration: InputDecoration(
            hintText: 'username',
            labelText: 'username',
            labelStyle: TextStyle(color: Colors.red[900]),
            enabledBorder:
                UnderlineInputBorder(borderSide: BorderSide(color: Colors.red)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.red))),
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
          onSaved: (value) {
            password = value!;
          },
          key: Key('password'),
          decoration: InputDecoration(
              hintText: 'password',
              labelText: 'password',
              labelStyle: TextStyle(color: Colors.red[900]),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.red)),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.red))),
          style: TextStyle(fontSize: 20.0, color: Colors.black),
          obscureText: true),
    );
  }

  Widget _buttonLogin(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      bloc: _loginBloc,
      listener: (context, state) {
        switch (state.status) {
          case LoginStatus.success:
            // ToastUtils.show(state.message);
            Fluttertoast.showToast(
              msg: state.message,
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.TOP,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.blue,
              textColor: Colors.white,
              // fontSize: 16.0,
            );
            // print('listener_success');
            // print(state.message);
            Navigator.pop(context);
            savePref(usernameController.text.toString(), state.userId,
                passwordController.text, state.departmentId);
            Future.delayed(const Duration(microseconds: 2000), () {
              Navigator.pushNamedAndRemoveUntil(
                  context, "/profile", (Route<dynamic> routes) => false);
            });
            break;
          case LoginStatus.failure:
            ToastUtils.show(state.message);
            // print('listener_filure');
            // print(state.message);
            Navigator.pop(context);
            break;
          case LoginStatus.loading:
            // print('listener_loading');
            // print(state.message);
            showProgressDialog(context);
            break;
          default:
            Navigator.pop(context);
            print('listener initial');
        }
      },
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: new InkWell(
          onTap: () {
            prosesLogin();
          },
          child: new BlocBuilder<LoginBloc, LoginState>(
            bloc: _loginBloc,
            builder: (context, state) {
              switch (state.status) {
                default:
                  return Container(
                    height: 50.0,
                    decoration: new BoxDecoration(
                      color: Colors.red[800],
                      border: new Border.all(color: Colors.white, width: 2.0),
                      borderRadius: new BorderRadius.circular(10.0),
                    ),
                    child: new Center(
                      child: new Text(
                        'Login',
                        style:
                            new TextStyle(fontSize: 18.0, color: Colors.white),
                      ),
                    ),
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
}
