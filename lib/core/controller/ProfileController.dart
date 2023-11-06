import 'dart:async';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:login_absen/core/bloc/profile/profile_bloc.dart';
import 'package:login_absen/core/config/endpoint.dart';
import 'package:login_absen/core/database/database_helper.dart';
import 'package:http/http.dart' as http;

class ProfileController{

  Future<void> getProfil(userID, date, profileBloc, apiToken) async {
    profileBloc.add(InitialProfile());
    String ip;
    final dbHelper = DatabaseHelper.instance;
    final allRows = await dbHelper.queryAllRows();

    if (allRows.length != 0) {
      ip = allRows[0]['ip_address'];
    } else {
      ip = Endpoint.baseUrl;
    }

    profileBloc.add(
      GetProfile(
        ip: ip,
        userID: userID,
        date: date,
        apiToken: apiToken,
      ),
    );
  }

  Future<void> openCamera(_status, userID, date, idShift, shift, profileBloc, apiToken) async {
    // Capture a photo
    var imageFile;
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
      maxWidth: 500,
      maxHeight: 500,
      preferredCameraDevice: CameraDevice.front,
    );

    // setState(() {
    // imageFile!.copy(pickedFile!.path);

    var picker = pickedFile;
    if (picker != null) {
      imageFile = File(pickedFile!.path);
    } else {
      imageFile = null;
      ProfileController().getProfil(userID, date, profileBloc, apiToken);
    }

    // PROSES CHECKIN / CHECKOUT
    // var image = imageFile;
    if (imageFile != null) {
      profileBloc.add(InitialProfile());
      if (_status == 'checkin') {
        // prosesCheckin(userID, '${DateTime.now()}', imageFile!, idShift, shift);
        ProfileController().prosesCheckin(
            usrId: userID,
            clockIn: '${DateTime.now()}',
            imageFile: imageFile!,
            idShift: idShift,
            shift: shift);
      } else {
        // prosesCheckout(userID, '${DateTime.now()}', imageFile!, idShift, shift);
        ProfileController().prosesCheckout(
            usrId: userID,
            clockOut: '${DateTime.now()}',
            imageFile: imageFile!,
            idShift: idShift,
            shift: shift);
      }
    }
  }

  Future<dynamic> prosesCheckin({required String usrId, required String clockIn, required File imageFile, required String idShift, required String shift, profileBloc, apiToken}) async {
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

  Future<dynamic> prosesCheckout({required String usrId, required String clockOut, required File imageFile, required String idShift, required String shift, profileBloc, apiToken}) async {
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
  Future<dynamic> prosesBreakOut(
      String usrId, String breakOut, String idShift, String shift, profileBloc, apiToken) async {
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
  Future<dynamic> prosesBreakIn(
      String usrId, String breakIn, String idShift, String shift, profileBloc, apiToken) async {
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