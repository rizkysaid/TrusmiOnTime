import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:login_absen/core/config/endpoint.dart';
import 'package:login_absen/core/database/database_helper.dart';
import 'package:login_absen/core/services/ApiService.dart';
import 'package:login_absen/core/ui/screens/profile_screen.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:async/async.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:giffy_dialog/giffy_dialog.dart';

bool _saving = false;
bool _hari_besar = false;

class PreviewScreen extends StatefulWidget{
  final String imgPath;
  final String userID;
  final String clockIn;
  final String imageUrl;
  final String status;
  final bool isCheckin = false;
  final bool isCheckout = false;
  final String idShift;
  final String shift;

  PreviewScreen({this.imgPath, this.userID, this.clockIn, this.imageUrl, this.status, this.idShift, this.shift});

  @override
  _PreviewScreenState createState() => _PreviewScreenState();

}
class _PreviewScreenState extends State<PreviewScreen>{

  static bool status_hari_besar;
  static String title;
  static String msg;
  static String gif;
  // static bool status_get_profil;

  static String date = new DateTime.now().toIso8601String().substring(0, 10);


  @override
  void initState(){

    checkHolidays();

  }

  Future<void>checkHolidays() async{
    String ip;
    final dbHelper = DatabaseHelper.instance;
    final allRows = await dbHelper.queryAllRows();

    if(allRows.length != 0){

      allRows.forEach((row) => print(row));
      ip = allRows[0]['ip_address'];

    }else{
      ip = Endpoint.base_url;
    }

    String usrId = basename(widget.userID);

    ApiServices services = ApiServices();
    var response = await services.CheckHolidays(ip, usrId);

    if(response == null){
      return null;

    }else{

      status_hari_besar = response.status;

      if(status_hari_besar == true){
        setState(() {
          _hari_besar = true;
          title = response.title.toString();
          msg = response.message.toString();
          gif = response.gif.toString();
        });
      }else{
        setState(() {
          _hari_besar = false;
        });
      }

    }

    // print('status_hari_besar = '+status_hari_besar.toString());
    // print('_hari_besar = '+_hari_besar.toString());
    // print('msg = '+msg.toString());
    // print('gif = '+gif.toString());
  }

  // Future<void>getProfil(userID) async{
  //   String ip;
  //   final dbHelper = DatabaseHelper.instance;
  //   final allRows = await dbHelper.queryAllRows();
  //   print('query all rows get profil profile screen:');
  //   print('Length = '+allRows.length.toString());
  //
  //   if(allRows.length != 0){
  //
  //
  //     ip = allRows[0]['ip_address'];
  //
  //   }else{
  //     ip = Endpoint.base_url;
  //
  //   }
  //
  //   // ApiServices services = ApiServices();
  //   // var response = await services.Profil(ip, userID, date);
  //
  //   // if(response == null){
  //   //   return null;
  //   //
  //   // }else{
  //   //
  //   //   status_get_profil = response.status;
  //   //
  //   //   if(status_get_profil == true){
  //   //     setState(() {
  //   //       _get_profil = true;
  //   //     });
  //   //   }else{
  //   //     setState(() {
  //   //       _get_profil = false;
  //   //     });
  //   //   }
  //   //
  //   // }
  //
  // }

  @override
  Widget build(BuildContext context) {

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
        color: Colors.green
      )
    );

    return Container(
      color: Colors.red[700],
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: true,
            iconTheme: new IconThemeData(color: Colors.white),
            backgroundColor: Colors.black,
          ),
          body: ModalProgressHUD(
            inAsyncCall: _saving,
            child: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: Image.file(File(widget.imgPath),fit: BoxFit.cover,),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      height: 60.0,
                      color: Colors.black,
                      child: Center(
                        child: IconButton(
                          icon: Icon(Icons.check,color: Colors.white,),
                          onPressed: (){
                            setState(() {
                              _saving = true;
                            });
                            FocusScope.of(context).requestFocus(new FocusNode());
                            getBytesFromFile().then((bytes){
                              String clock_in = widget.clockIn.substring(0,19);
                              String usrId = basename(widget.userID);
                              String idShift = basename(widget.idShift);
                              String shift = basename(widget.shift);

                              if(widget.status == "checkin"){
                                if(prosesCheckin(usrId, clock_in, File(widget.imgPath), idShift, shift) != null){
                                  savePref(clock_in.substring(11,16), true, false, widget.imgPath, widget.status);
                                  Alert(
                                      context: context,
                                      style: alertStyle,
                                      type: AlertType.success,
                                      title: "Success Check In",
//                                    desc: "You have been Preseent, have a nice Day",
                                      buttons: [
                                        DialogButton(
                                          child: Text(
                                            "OK",
                                            style: TextStyle(color: Colors.white, fontSize: 20),
                                          ),
                                          onPressed: () => {

                                            if(_hari_besar == true){

                                                showDialog(
                                                  context: context,builder: (_) =>
                                                    NetworkGiffyDialog(
                                                      image: Image.network(Endpoint.url_gif+"/"+gif) ,
                                                      title: Text(title.toString(),
                                                        textAlign: TextAlign.center,
                                                        style: TextStyle(
                                                          fontSize: 20.0,
                                                            fontWeight: FontWeight.w700),
                                                        ),
                                                      description: Text(msg.toString(),
                                                        textAlign: TextAlign.center,
                                                        style: TextStyle(
                                                          fontSize: 18.0,
                                                            fontWeight: FontWeight.w400),
                                                          ),
                                                      entryAnimation: EntryAnimation.BOTTOM_RIGHT,
                                                      // description: Text(
                                                      //   msg.toString(),
                                                      //   textAlign: TextAlign.center,
                                                      //   style: TextStyle(),
                                                      // ),
                                                      onlyOkButton: true,
                                                      onOkButtonPressed: () {
                                                        Future.delayed(const Duration(seconds: 2),(){
                                                          setState(() {
                                                            _saving = false;
                                                          });
                                                          ProfileScreen().createState().getProfil(usrId, date);
                                                          Navigator.pushNamedAndRemoveUntil(context, "/profile", (Route<dynamic>routes)=>false);
                                                        });
                                                      },
                                                    ),
                                                )

                                            }else{
                                              Future.delayed(const Duration(seconds: 2),(){
                                                setState(() {
                                                  _saving = false;
                                                });
                                                ProfileScreen().createState().getProfil(usrId, date);
                                                Navigator.pushNamedAndRemoveUntil(context, "/profile", (Route<dynamic>routes)=>false);
                                              })
                                            }
                                          },
                                          width: 120,
                                        )
                                      ]
                                  ).show();
                                }
                              }else{

                                if(prosesCheckout(usrId, clock_in, File(widget.imgPath), idShift, shift) != null){
                                  savePref(clock_in.substring(11,16), true, true, widget.imgPath, widget.status);
                                  Alert(
                                      context: context,
                                      style: alertStyle,
                                      type: AlertType.success,
                                      title: "Success Check Out",
//                                    desc: "Thank you for your efforts, Your dedication is imperative for the growth of our company",
                                      buttons: [
                                        DialogButton(
                                          child: Text(
                                            "OK",
                                            style: TextStyle(color: Colors.white, fontSize: 20),
                                          ),
                                          onPressed: ()=> {

                                            // if(_get_profil == true){
                                              Future.delayed(Duration(seconds: 2),(){
                                                setState(() {
                                                  _saving = false;
                                                });
                                                ProfileScreen().createState().getProfil(usrId, date);
                                                Navigator.pushNamedAndRemoveUntil(context, "/profile", (Route<dynamic>routes)=>false);
                                              })
                                            // }else{
                                            //   Alert(
                                            //     context: context,
                                            //     style: alertStyle,
                                            //     type: AlertType.error,
                                            //     title: "Network Error!",
                                            //     desc: "Network not connected! Reload and try again!",
                                            //
                                            //   )
                                            // }
                                          },
                                          width: 120,
                                        )
                                      ]
                                  ).show();
                                }
                              }

                            });
                          },
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  savePref(String clock_in, bool isCheckin, bool isCheckout, String imageUrl, String status) async{
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {

      pref.setBool('isCheckin', isCheckin);
      pref.setBool('isCheckout', isCheckout);
      pref.setString('imageUrl', imageUrl);
      pref.setString('status', status);
    });
  }

  Future<ByteData> getBytesFromFile() async{
    Uint8List bytes = File(widget.imgPath).readAsBytesSync() as Uint8List;
    return ByteData.view(bytes.buffer);
  }

  Future prosesCheckin(String usrId, String clock_in, File imageFile, String idShift, String shift) async{

   var stream = new http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
   var length = await imageFile.length();
   var uri = Uri.parse(Endpoint.checkin);
   var request = new http.MultipartRequest("POST", uri);

   var multiPartFile = new http.MultipartFile("foto", stream, length, filename: basename(imageFile.path));
   // String date = new DateTime.now().toIso8601String().substring(0, 10);

   request.files.add(multiPartFile);
   request.fields['employee_id'] = usrId;
   request.fields['clock_in'] = clock_in;
   request.fields['id_shift'] = idShift;
   request.fields['shift'] = shift;

   var response = await request.send();

    SharedPreferences pref = await SharedPreferences.getInstance();
    var ip = pref.getString('IpAddress');

   if(response.statusCode == 201){
     return true;

   }else{
     print(response.statusCode);
     return null;
   }
  }


  Future prosesCheckout(String usrId, String clock_in, File imageFile, String idShift, String shift) async{

    var stream = new http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
    var length = await imageFile.length();
    var uri = Uri.parse(Endpoint.checkout);
    var request = new http.MultipartRequest("POST", uri);

    var multiPartFile = new http.MultipartFile("foto", stream, length, filename: basename(imageFile.path));
    // String date = new DateTime.now().toIso8601String().substring(0, 10);

    request.files.add(multiPartFile);
    request.fields['employee_id'] = usrId;
    request.fields['clock_out'] = clock_in;
    request.fields['id_shift'] = idShift;
    request.fields['shift'] = shift;

    var response = await request.send();

    // if(response.statusCode == 201){
    //   SharedPreferences pref = await SharedPreferences.getInstance();
    //   var ip = pref.getString('IpAddress');
    //
    //   ApiServices services = ApiServices();
    //   var response = await services.Profil(ip, usrId, date);
    //   try {
    //     if (response.status == true) {
    //       setState(() {
    //         return true;
    //       });
    //     }
    //   } catch (err) {
    //     print("Cannot read");
    //   }
    //
    // }else{
    //   print(response.statusCode);
    //   return null;
    // }

    if(response.statusCode == 201){
      return true;

    }else{
      print(response.statusCode);
      return null;
    }

  }

}