import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:login_absen/core/ui/screens/preview_screen.dart';
import 'ScreenArguments.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(CameraScreen());
}

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController controller;
  late List cameras;
  late int selectedCameraIndex;
  late String imgPath;

//  String userID;
//  String username;
//  static String date = new DateTime.now().toIso8601String().substring(0, 10);

  @override
  void initState() {
    super.initState();

    availableCameras().then((availableCameras) {
      cameras = availableCameras;

      if (cameras.length > 0) {
        setState(() {
          selectedCameraIndex = 1;
        });
        _initCameraController(cameras[selectedCameraIndex]).then((void v) {
          if (!mounted) {
            return;
          }
        });
      } else {
        print('No camera available');
      }
    }).catchError((err) {
      print('Error :${err.code}Error message : ${err.message}');
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
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
    return Stack(
      // crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        _cameraPreviewWidget(),
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Row(
            children: <Widget>[
              _cameraToggleRowWidget(),
              _cameraControlWidget(context),
              Spacer(),
            ],
          ),
        )
      ],
    );
  }

  /// Display Camera preview.
  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final size = MediaQuery.of(this.context).size;
    final deviceRatio = size.width / size.height;
    final xScale = controller.value.aspectRatio / deviceRatio;
    // Modify the yScale if you are in Landscape
    final yScale = 1.0;

    return AspectRatio(
      aspectRatio: deviceRatio,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(xScale, yScale, 1),
        child: CameraPreview(controller),
      ),
    );
  }

  /// Display the control bar with buttons to take pictures
  Widget _cameraControlWidget(context) {
    return Expanded(
      child: Align(
        alignment: Alignment.bottomCenter,
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
        alignment: Alignment.bottomLeft,
        child: TextButton.icon(
          onPressed: _onSwitchCamera,
          icon: Icon(
            _getCameraLensIcon(lensDirection),
            color: Colors.black,
            size: 24,
          ),
          label: Text(
            '${lensDirection.toString().substring(lensDirection.toString().indexOf('.') + 1).toUpperCase()}',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
          ),
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
    final args = ModalRoute.of(context)!.settings.arguments as ScreenArguments;
    final image = await controller.takePicture();
    try {
      // final path =
      //     join((await getTemporaryDirectory()).path, '${DateTime.now()}.png');
      // await controller.takePicture().then((value) => path);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PreviewScreen(
              imgPath: image.path,
              userID: args.userID,
              status: args.status,
              clockIn: '${DateTime.now()}',
              idShift: args.idShift,
              shift: args.shift),
        ),
      );
    } on CameraException catch (e) {
      print(e);
      return null;
    }
  }

  void _onSwitchCamera() {
    selectedCameraIndex =
        selectedCameraIndex < cameras.length - 1 ? selectedCameraIndex + 1 : 0;
    CameraDescription selectedCamera = cameras[selectedCameraIndex];
    _initCameraController(selectedCamera);
  }
}
