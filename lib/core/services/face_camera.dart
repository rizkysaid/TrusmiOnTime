import 'dart:io';

import 'package:flutter/material.dart';

import 'package:face_camera/face_camera.dart';
import 'package:get/get.dart';
import 'package:login_absen/core/bloc/profile/profile_bloc.dart';
import 'package:login_absen/core/config/endpoint.dart';
import 'package:http/http.dart' as http;
import 'package:login_absen/core/controller/ProfileController.dart';
import 'package:login_absen/core/ui/screens/profile_screen.dart';
// import 'package:login_absen/core/controller/ProfileController.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FaceCamera.initialize();
  runApp(const FaceCameraWidget(statusCheckin: '', userId: '', idShift: '', shift: '',));
}

class FaceCameraWidget extends StatefulWidget {
  final String statusCheckin;
  final String userId;
  final String idShift;
  final String shift;
  const FaceCameraWidget(
      {Key? key,
      required this.statusCheckin,
      required this.userId,
      required this.idShift,
      required this.shift})
      : super(key: key);

  @override
  State<FaceCameraWidget> createState() => _FaceCameraWidgetState();
}

class _FaceCameraWidgetState extends State<FaceCameraWidget> {
  File? _capturedImage;
  final ProfileBloc profileBloc = ProfileBloc();

  @override
  void initState() {
    // if (Platform.isAndroid) WebView.platform = AndroidWebView();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        disabledColor: Colors.white24,

      ),
      home: Scaffold(
          // appBar: AppBar(
          //   title: const Text('FaceCamera example app'),
          // ),
          body: Builder(builder: (context) {
        if (_capturedImage != null) {

          return Stack(
            alignment: Alignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child:
                    Transform.flip(
                      flipX: true,
                      child: Image.file(
                        _capturedImage!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Container(
                    width: double.infinity,
                    height: 80.0,
                    // color: Colors.red[700],
                    child: Center(
                      child: IconButton(
                        icon: CircleAvatar(
                            radius: 35,
                            foregroundColor: null,
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.check, size: 32),
                            ),
                        ),
                        onPressed: (){
                          if (this.mounted) {

                            if (_capturedImage != null) {
                              profileBloc.add(InitialProfile());
                              if (widget.statusCheckin == 'checkin') {
                                ProfileController().prosesCheckin(
                                    usrId: widget.userId,
                                    clockIn: '${DateTime.now()}',
                                    imageFile: _capturedImage!,
                                    idShift: widget.idShift,
                                    shift: widget.shift);

                                if (this.mounted) {
                                  setState(() => _capturedImage = null);
                                }
                                Get.off(ProfileScreen());

                              } else {
                                ProfileController().prosesCheckout(
                                    usrId: widget.userId,
                                    clockOut: '${DateTime.now()}',
                                    imageFile: _capturedImage!,
                                    idShift: widget.idShift,
                                    shift: widget.shift);

                                if (this.mounted) {
                                  setState(() => _capturedImage = null);
                                }
                                Get.off(ProfileScreen());

                              }
                            }

                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                right: 25,
                bottom: 20,
                child: IconButton(
                  icon: Icon(Icons.camera_alt, size: 32),
                  onPressed: (){
                    if (this.mounted) {
                      // jika ingin mengulangi camera
                      setState(() => _capturedImage = null);
                    }
                  },
                ),
              ),


            ],
          );
        }
        return SmartFaceCamera(
            autoCapture: false,
            defaultCameraLens: CameraLens.front,
            imageResolution: ImageResolution.high,
            onCapture: (File? image) {
              if (this.mounted) {
                setState(() => _capturedImage = image);
              }

            },
            onFaceDetected: (Face? face) {
              //Do something
              // ScaffoldMessenger.of(context).showSnackBar(
              //     SnackBar(
              //       content: Text('Yay! A SnackBar!'),
              //     )
              // );


            },
            showCaptureControl: true,
            showCameraLensControl: false,
            showFlashControl: false,
            autoDisableCaptureControl: true,
            // messageBuilder: (context, face) {
            //   if (face == null) {
            //     return _message('Place your face in the camera');
            //   }
            //     if (!face.wellPositioned) {
            //       return _message('Center your face in the square');
            //     }
            //   return const SizedBox.shrink();
            // }
            );
      })),
    );
  }

  Widget _message(String msg) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 55, vertical: 25),
        child: Text(msg,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14, height: 1.5, fontWeight: FontWeight.w400)),
      );

  Future<dynamic> prosesCheckin(
      {required String usrId,
      required String clockIn,
      required File imageFile,
      required String idShift,
      required String shift,
      profileBloc,
      apiToken}) async {
    var uri = Uri.parse(Endpoint.checkin);
    // print('Endpoint.checkin => ' + Endpoint.checkin);
    var request = new http.MultipartRequest("POST", uri);
    var multiPartFile = new http.MultipartFile.fromBytes(
      "foto",
      imageFile.readAsBytesSync(),
      filename: imageFile.path,
    );

    request.files.add(multiPartFile);
    request.fields['employee_id'] = usrId;
    request.fields['clock_in'] = clockIn;
    request.fields['id_shift'] = idShift;
    request.fields['shift'] = shift;

    var response = await request.send();

    // if (response.statusCode == 201) {
    //   showSuccessDialog(context, 'checkin');
    // } else {
    //   showErrorDialog(context, 'checkin');
    // }

    return response.statusCode;
  }

  Future<dynamic> prosesCheckout(
      {required String usrId,
      required String clockOut,
      required File imageFile,
      required String idShift,
      required String shift,
      profileBloc,
      apiToken}) async {
    // showProgressDialog(context);

    var uri = Uri.parse(Endpoint.checkout);
    var request = new http.MultipartRequest("POST", uri);

    var multiPartFile = new http.MultipartFile.fromBytes(
      "foto",
      imageFile.readAsBytesSync(),
      filename: imageFile.path,
    );

    request.files.add(multiPartFile);
    request.fields['employee_id'] = usrId;
    request.fields['clock_out'] = clockOut;
    request.fields['id_shift'] = idShift;
    request.fields['shift'] = shift;

    var response = await request.send();

    // if (response.statusCode == 200) {
    //   // hide pop up
    //   Navigator.pop(context);
    //   showSuccessDialog(context, 'checkout');
    // } else {
    //   showErrorDialog(context, 'checkout');
    // }
    return response.statusCode;
  }

  // BREAK OUT
  Future<dynamic> prosesBreakOut(String usrId, String breakOut, String idShift,
      String shift, profileBloc, apiToken) async {
    profileBloc.add(InitialProfile());

    var uri = Uri.parse(Endpoint.breakout);
    var request = new http.MultipartRequest("POST", uri);

    request.fields['employee_id'] = usrId;
    request.fields['break_out'] = breakOut;
    request.fields['id_shift'] = idShift;
    request.fields['shift'] = shift;

    var response = await request.send();

    // if (response.statusCode == 200) {
    //   // timer = new Timer(new Duration(seconds: 2), () {
    //   getProfil(usrId, date);
    //   ToastUtils.show(
    //       "Selamat istirahat, manfaatkan waktu istirahatmu dengan baik");
    //   // });
    // } else {
    //   print(response.statusCode);
    // }

    return response.statusCode;
  }

  // BREAK OUT
  Future<dynamic> prosesBreakIn(String usrId, String breakIn, String idShift,
      String shift, profileBloc, apiToken) async {
    profileBloc.add(InitialProfile());
    var uri = Uri.parse(Endpoint.breakin);
    var request = new http.MultipartRequest("POST", uri);

    request.fields['employee_id'] = usrId;
    request.fields['break_in'] = breakIn;
    request.fields['id_shift'] = idShift;
    request.fields['shift'] = shift;

    var response = await request.send();

    print('response.status.breakout => ' + response.statusCode.toString());

    // if (response.statusCode == 200) {
    //   // timer = new Timer(new Duration(seconds: 2), () {
    //   getProfil(usrId, date);
    //   ToastUtils.show("Selamat bekerja kembali");
    //   // });
    // } else {
    //   print(response.statusCode);
    // }

    return response.statusCode;
  }
}
