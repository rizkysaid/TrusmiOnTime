import 'dart:convert';

import 'package:login_absen/core/models/AuthModel.dart';
import 'package:login_absen/core/models/CheckHolidaysModel.dart';

import 'package:login_absen/core/models/CheckKoneksiModel.dart';
import 'package:login_absen/core/models/CheckStatusModel.dart';
import 'package:login_absen/core/models/ProfileModel.dart';
import 'package:http/http.dart' as http;

class ApiServices {
  Future<AuthModel> login(ip, username, password) async {
    try {
      var response = await http.post(Uri.parse(ip + '/login'),
          body: {'username': username, 'password': password});

      if (response.statusCode == 200) {
        AuthModel responseRequest =
            AuthModel.fromJson(jsonDecode(response.body));
        return responseRequest;
      } else {
        AuthModel responseRequest =
            AuthModel.fromJson(jsonDecode(response.body));
        return responseRequest;
      }
    } catch (e) {
      print("Error: " + e.toString());
      return null;
    }
  }

  Future<ProfileModel> profil(ip, userID, date) async {
    print('ip => ' + ip);
    print('userID => ' + userID);
    print('date => ' + date);
    try {
      var response =
          await http.get(Uri.parse(ip + '/profil/' + userID + '/' + date));
      print("Response Status : ${response.statusCode}");
      print("Response Body : ${response.body}");
      if (response.statusCode == 200) {
        ProfileModel responseRequest =
            ProfileModel.fromJson(jsonDecode(response.body));
        return responseRequest;
      } else {
        return null;
      }
    } catch (e) {
      print("Error get profile: " + e.toString());
      print('IP in ApiService - Profil - Error = ' + ip.toString());
      return null;
    }
  }

  Future<CheckKoneksiModel> checkKoneksi(ip) async {
    try {
      var response = await http.get(Uri.parse(ip + "/cek_con"));
      print("Response Status : ${response.statusCode}");
      print("Response Body : ${response.body}");
      if (response.statusCode == 200) {
        CheckKoneksiModel responseRequest =
            CheckKoneksiModel.fromJson(jsonDecode(response.body));
        return responseRequest;
      } else {
        print("No connection ");
        return null;
      }
    } catch (e) {
      print("Error Cek Koneksi: " + e.toString());
      return null;
    }
  }

  Future<CheckStatusModel> checkStatus(ip, userID) async {
    try {
      var response = await http.get(Uri.parse(ip + '/check_in/' + userID));
      print("Response CekStatus Status : ${response.statusCode}");
      print("Response CekStatus Body : ${response.body}");
      if (response.statusCode == 200) {
        CheckStatusModel responseRequest =
            CheckStatusModel.fromJson(jsonDecode(response.body));
        return responseRequest;
      } else {
        return null;
      }
    } catch (e) {
      print("Error Check Status: " + e.toString());
      print('IP in ApiService - CheckStatus - Error = ' + ip.toString());
      return null;
    }
  }

  Future<CheckHolidaysModel> checkHolidays(ip, userID) async {
    try {
      var response =
          await http.get(Uri.parse(ip + '/check_holidays/' + userID));
      // print('ip => ' + ip);
      // print('userId => ' + userID);
      // print("Response CekHolidays Status : ${response.statusCode}");
      // print("Response CekHolidays Body : ${response.body}");
      if (response.statusCode == 200) {
        CheckHolidaysModel responseBirthday =
            CheckHolidaysModel.fromJson(jsonDecode(response.body));
        return responseBirthday;
      } else {
        return null;
      }
    } catch (e) {
      print("Error Check Holidays: " + e.toString());
      print('IP in ApiService - CheckHolidays - Error = ' + ip.toString());
      return null;
    }
  }
}
