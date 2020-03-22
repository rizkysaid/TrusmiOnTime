import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:login_absen/core/services/ApiService.dart';
import 'package:login_absen/core/utils/toast_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(body: SingleChildScrollView(child: LoginBody())),
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
    SharedPreferences pref = await SharedPreferences.getInstance();
    final username = pref.getString('username');
    if(username != null){
      Navigator.pushNamedAndRemoveUntil(context, "/profile", (Route<dynamic>routes) => false);
    }
  }

  Future<void> prosesLogin() async{
    
    if(usernameController.text.isNotEmpty && passwordController.text.isNotEmpty){

      ToastUtils.show("Check Login ...");

      ApiServices services = ApiServices();
      var response = await services.Login(usernameController.text, passwordController.text);
      String usrId = response.data[0].userId.toString();

      if(response.status == true){
        savePref(usernameController.text.toString(), usrId);
        Future.delayed(const Duration(microseconds: 2000),(){
          Navigator.pushNamedAndRemoveUntil(context, "/profile", (Route<dynamic>routes)=>false);
        });
      }else{
        print("error ");
      }

    }else{
      ToastUtils.show("Please Input All Fields");
    }

    Future.delayed(const Duration(microseconds: 2000),(){
      Navigator.pushNamedAndRemoveUntil(context, "/profile", (Route<dynamic>routes)=>false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // bagian header
        Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height / 4,
          color: Colors.lightBlue,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.alarm_on, size: 60, color: Colors.white),
                SizedBox(height: 10),
                Text(
                  "onTime",
                  style: TextStyle(
                      fontSize: 35,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
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
            hintText: 'username', labelText: 'username'
          ),
          style: TextStyle(
            fontSize: 20.0, color: Colors.black
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
          hintText: 'password', labelText: 'password'
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
            color: Colors.blueAccent,
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

 