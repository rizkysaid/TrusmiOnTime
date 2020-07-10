import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:login_absen/core/config/endpoint.dart';
import 'package:login_absen/core/database/database_helper.dart';
import 'package:login_absen/core/services/ApiService.dart';
import 'package:login_absen/core/ui/screens/preview_screen.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ScreenArguments.dart';

bool _saving = false;
class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  
  CameraController controller;
  List cameras;
  int selectedCameraIndex;
  String imgPath;

  String userID;
  String username;
  static String date = new DateTime.now().toIso8601String().substring(0, 10);

  @override
  void initState(){
    super.initState();
    availableCameras().then((availableCameras){
      cameras = availableCameras;

      if(cameras.length > 0){
        setState(() {
          selectedCameraIndex = 1;
        });
        _initCameraController(cameras[selectedCameraIndex]).then((void v){});

      }else{
        print('No camera available');
      }
    }).catchError((err){
      print('Error :${err.code}Error message : ${err.message}');
    });

    getPref();

    setState(() {
      _saving = true;
    });

  }

  @override
  void dispose() {

    controller.dispose();
    super.dispose();
  }

  getPref()async {
    String ip;
    final dbHelper = DatabaseHelper.instance;
    final allRows = await dbHelper.queryAllRows();

    if(allRows.length != 0){

      allRows.forEach((row) => print(row));
      ip = allRows[0]['ip_address'];
      SharedPreferences pref = await SharedPreferences.getInstance();
      setState(() {
        username = pref.getString('username');
        userID = pref.getString('userID');
      });

    }else{
      ip = Endpoint.base_url;
    }


    print('userId nyee '+userID);
    print('IP nyee '+ip);
    print('date nyee '+date);

    ApiServices services = ApiServices();
    var response = await services.Profil(ip, userID, date);
    if (response == null) {

      Future.delayed(const Duration(microseconds: 2000), () {
        Navigator.pushNamedAndRemoveUntil(
            this.context, "/invalid_ip", (Route<dynamic>routes) => false);
      });
    } else {
      setState(() {
        _saving = false;
      });
    }
  }

  Future _initCameraController(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }
    controller = CameraController(cameraDescription, ResolutionPreset.medium);

    controller.addListener(() {
      if (mounted) {
        setState(() {});
      }

      if (controller.value.hasError) {
        print('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: ModalProgressHUD(
        inAsyncCall: _saving,
        child: Container(
          color: Colors.black,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(

                  child: _cameraPreviewWidget(),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 120,
                    width: double.infinity,

                    color: Colors.black,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        _cameraToggleRowWidget(),
                        _cameraControlWidget(context),
                        Spacer()
                      ],
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

  /// Display Camera preview.
  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Loading',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.w900,
        ),
      );
    }

    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: CameraPreview(controller),
    );
  }

  /// Display the control bar with buttons to take pictures
  Widget _cameraControlWidget(context) {
    return Expanded(
      child: Align(
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            FloatingActionButton(
              child: Icon(
                Icons.camera,
                color: Colors.black,
              ),
              backgroundColor: Colors.white,
              onPressed: () {
                _onCapturePressed(context);
              },
            )
          ],
        ),
      ),
    );
  }

  /// Display a row of toggle to select the camera (or a message if no camera is available).

  Widget _cameraToggleRowWidget() {
    if (cameras == null || cameras.isEmpty) {
      return Spacer();
    }
    CameraDescription selectedCamera = cameras[selectedCameraIndex];
    CameraLensDirection lensDirection = selectedCamera.lensDirection;

    return Expanded(
      child: Align(
        alignment: Alignment.centerLeft,
        child: FlatButton.icon(
          onPressed: _onSwitchCamera,
          icon: Icon(
            _getCameraLensIcon(lensDirection),
            color: Colors.white,
            size: 24,
          ),
          label: Text(
            '${lensDirection.toString().substring(lensDirection.toString().indexOf('.') + 1).toUpperCase()}',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500
            ),),
        ),
      ),
    );
  }

  IconData _getCameraLensIcon(CameraLensDirection direction) {
    switch (direction) {
      case CameraLensDirection.back:
        return CupertinoIcons.switch_camera;
      case CameraLensDirection.front:
        return CupertinoIcons.switch_camera_solid;
      case CameraLensDirection.external:
        return Icons.camera;
      default:
        return Icons.device_unknown;
    }
  }

  void _showCameraException(CameraException e) {
    String errorText = 'Error:${e.code}\nError message : ${e.description}';
    print(errorText);
  }

  void _onCapturePressed(context) async {
    final ScreenArguments args = ModalRoute.of(context).settings.arguments;
    try {
      final path =
      join((await getTemporaryDirectory()).path, '${DateTime.now()}.png');
      await controller.takePicture(path);

      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PreviewScreen(
              imgPath: path,
              userID: args.userID,
              status: args.status,
              clockIn: '${DateTime.now()}',
              idShift: args.idShift,
              shift: args.shift
            )),
      );
    } catch (e) {
      _showCameraException(e);
    }
  }

  void _onSwitchCamera() {
    selectedCameraIndex =
    selectedCameraIndex < cameras.length - 1 ? selectedCameraIndex + 1 : 0;
    CameraDescription selectedCamera = cameras[selectedCameraIndex];
    _initCameraController(selectedCamera);
  }




}
