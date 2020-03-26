import 'dart:convert';

import 'package:login_absen/core/models/AuthModel.dart';
import 'package:login_absen/core/config/endpoint.dart';
import 'package:login_absen/core/models/ProfileModel.dart';
import 'package:login_absen/core/utils/toast_util.dart';
import 'package:http/http.dart' as http;

class ApiServices{

  Future<AuthModel> Login(username, password) async{
    try{
      var response = await http.post(
          Endpoint.login,
          body: {'username' : username, 'password' : password}
      );
//      print("Response Status : ${response.statusCode}");
//      print("Response Body : ${response.body}");
      if (response.statusCode == 200) {
        AuthModel responseRequest = AuthModel.fromJson(jsonDecode(response.body));
        return responseRequest;
      } else {
        AuthModel responseRequest = AuthModel.fromJson(jsonDecode(response.body));
        return responseRequest;
      }

    }catch(e){
      print("Error: "+e.toString());
      ToastUtils.show("Username or password is not valid");
    }
  }

  Future<ProfileModel> Profil(userID, date) async{
    try{
      var response = await http.get(Endpoint.profil+'/'+userID+'/'+date);
      print("Response Status : ${response.statusCode}");
      print("Response Body : ${response.body}");
      if (response.statusCode == 200) {
        ProfileModel responseRequest = ProfileModel.fromJson(jsonDecode(response.body));
        return responseRequest;
      } else {
        return null;
      }

    }catch(e){
      print("Error: "+e.toString());

      ToastUtils.show("Error Profile");
    }
  }


}