import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:login_absen/core/config/endpoint.dart';
import 'package:login_absen/core/services/ApiService.dart';
import 'package:login_absen/core/ui/screens/profile_screen.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:async/async.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class PreviewScreen extends StatefulWidget{
  final String imgPath;
  final String userID;
  final String clockIn;
  final String imageUrl;
  final String status;
  final bool isCheckin = false;

  PreviewScreen({this.imgPath, this.userID, this.clockIn, this.imageUrl, this.status});

  @override
  _PreviewScreenState createState() => _PreviewScreenState();

}
class _PreviewScreenState extends State<PreviewScreen>{
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
        color: Colors.red
      )
    );

    return Container(
      color: Colors.lightBlue,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: true,
            iconTheme: new IconThemeData(color: Colors.white),
            backgroundColor: Colors.black,
          ),
          body: Container(
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
                          FocusScope.of(context).requestFocus(new FocusNode());
                          getBytesFromFile().then((bytes){
                            String clock_in = widget.clockIn.substring(0,19);
                            String usrId = basename(widget.userID);
                            if(prosesCheckin(usrId, clock_in, File(widget.imgPath)) != null){
                              savePref(clock_in.substring(11,16), true, widget.imgPath, widget.status);
                              Alert(
                                context: context,
                                style: alertStyle,
                                type: AlertType.success,
                                title: "Success Check In",
                                desc: "You have been Preseent, have a nice Day",
                                buttons: [
                                  DialogButton(
                                    child: Text(
                                        "OK",
                                      style: TextStyle(color: Colors.white, fontSize: 20),
                                    ),
                                    onPressed: ()=> {
                                      Future.delayed(const Duration(microseconds: 2000),(){
                                        Navigator.pushNamedAndRemoveUntil(context, "/profile", (Route<dynamic>routes)=>false);
                                      })
                                    },
                                    width: 120,
                                  )
                                ]
                              ).show();

                            };
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
    );
  }

  savePref(String clock_in, bool isCheckin, String imageUrl, String status) async{
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      pref.setString('clock_in', clock_in);
      pref.setBool('isCheckin', isCheckin);
      pref.setString('imageUrl', imageUrl);
      pref.setString('status', status);
    });
  }

  Future<ByteData> getBytesFromFile() async{
    Uint8List bytes = File(widget.imgPath).readAsBytesSync() as Uint8List;
    return ByteData.view(bytes.buffer);
  }

  Future prosesCheckin(String usrId, String clock_in, File imageFile) async{

   var stream = new http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
   var length = await imageFile.length();
   var uri = Uri.parse(Endpoint.checkin);
   var request = new http.MultipartRequest("POST", uri);

   var multiPartFile = new http.MultipartFile("foto", stream, length, filename: basename(imageFile.path));
   String date = new DateTime.now().toIso8601String().substring(0, 10);

   request.files.add(multiPartFile);
   request.fields['employee_id'] = usrId;
   request.fields['clock_in'] = clock_in;

   var response = await request.send();

   if(response.statusCode == 201){
//     return true;
     ApiServices services = ApiServices();
     var response = await services.Profil(usrId, date);
     try {
       if (response.status == true) {
         setState(() {
           return true;
         });
       }
     } catch (err) {
       print("Cannot read");
     }

   }else{
     print(response.statusCode);
     return null;
   }

  }

}