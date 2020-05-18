import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:login_absen/core/config/endpoint.dart';
import 'package:login_absen/core/database/database_helper.dart';
import 'package:login_absen/core/services/ApiService.dart';
import 'package:login_absen/core/utils/toast_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  @override
  void initState() {
    super.initState();
    checkConnection();

  }


  @override
  void dispose() {
    super.dispose();

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
  void initState(){
    super.initState();
     getPref();
  }


  savePref(String username, String userID) async{
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      pref.setString('username', username);
      pref.setString('userID', userID);
    });
  }

  getPref() async{

    String ip;
    final dbHelper = DatabaseHelper.instance;
    final allRows = await dbHelper.queryAllRows();
    print('query all rows:' +allRows.toList().toString());
    print('Length = '+allRows.length.toString());

    if(allRows.length != 0){

      allRows.forEach((row) => print(row));
      ip = allRows[0]['ip_address'];

    }else{
      ip = Endpoint.base_url;
    }

    print('Check IP in getPref LoginScreen = '+ip.toString());

    ApiServices services = ApiServices();
    var response = await services.CheckKoneksi(ip);
    if(response == null){
      Future.delayed(const Duration(microseconds: 2000),(){
        Navigator.pushNamedAndRemoveUntil(context, "/invalid_ip", (Route<dynamic>routes)=>false);
      });
    }else{
      SharedPreferences pref = await SharedPreferences.getInstance();
      var username = pref.getString('username');
      if(username != null){
        Future.delayed(const Duration(microseconds: 2000),(){
          Navigator.pushNamedAndRemoveUntil(context, "/profile", (Route<dynamic>routes)=>false);
        });
      }
    }


  }

  Future<void> prosesLogin() async{
    
    if(usernameController.text.isNotEmpty && passwordController.text.isNotEmpty){
      String ip;
      ToastUtils.show("Check Login ...");
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
      var response = await services.Login(ip, usernameController.text, passwordController.text);
      String usrId = response.data[0].userId.toString();
      String messageLogin = response.message.toString();


      if(response.status == true){
        savePref(usernameController.text.toString(), usrId);
        Future.delayed(const Duration(microseconds: 2000),(){
          Navigator.pushNamedAndRemoveUntil(context, "/profile", (Route<dynamic>routes)=>false);
        });
      }else{
        ToastUtils.show(messageLogin);
      }

    }else{
      ToastUtils.show("Please Input All Fields");
    }

//    Future.delayed(const Duration(microseconds: 2000),(){
//      Navigator.pushNamedAndRemoveUntil(context, "/profile", (Route<dynamic>routes)=>false);
//    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // bagian header
        Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height / 4,
//          color: Colors.red,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background_login.png'),
              fit: BoxFit.cover
            )
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image(
                  alignment: Alignment.center,
                    height: MediaQuery.of(context).size.width / 4,
                    width: MediaQuery.of(context).size.width / 2,
                    image: AssetImage("assets/logo_png_ontime.png")
                )
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
    );
  }

Widget _username(BuildContext context){
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: TextFormField(
          controller: usernameController,
          validator: validateUser,
          onSaved: (String value){
            username = value;
          },
          key: Key('username'),
          decoration: InputDecoration(
            hintText: 'username', labelText: 'username',
            labelStyle: TextStyle(color: Colors.red[900]),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.red[900])),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.red[900]))
          ),
          style: TextStyle(
            fontSize: 20.0, color: Colors.black,
          ),
        ),
      );
  }

  Widget _password(BuildContext context){
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: TextFormField(
        controller: passwordController,
        onSaved: (String value){
          password = value;
        },
        key: Key('password'),
        decoration: InputDecoration(
          hintText: 'password', labelText: 'password',
          labelStyle: TextStyle(color: Colors.red[900]),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.red[900])),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.red[900]))
        ),
        style: TextStyle(
          fontSize: 20.0, color: Colors.black
        ),
        obscureText: true
      ),
    );
  }

  Widget _buttonLogin(BuildContext context){
    return Padding(
      padding: EdgeInsets.all(8.0),
      child:new InkWell(
        onTap: () => prosesLogin(),
        child: new Container(
          height: 50.0,
          decoration: new BoxDecoration(
            color: Colors.red[800],
            border: new Border.all(color: Colors.white, width: 2.0),
            borderRadius: new BorderRadius.circular(10.0),
          ),
          child: new Center(
            child: new Text(
              'Login',
              style: new TextStyle(fontSize: 18.0, color: Colors.white)
            )
          ),
        )
      )
    );
  }

  String validateUser(String value){
    if(value.isEmpty){
      return 'Username harus diisi';
    }
    return null;
  }

  

}

 