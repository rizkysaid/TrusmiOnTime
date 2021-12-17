import 'dart:convert';

import 'package:login_absen/core/models/AuthModel.dart';
import 'package:login_absen/core/models/CheckHolidaysModel.dart';

import 'package:login_absen/core/models/CheckKoneksiModel.dart';
import 'package:login_absen/core/models/CheckStatusModel.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

class ApiServices {
  Dio dio = new Dio();
  late Response response;
  String connErr = 'Please check your internet connection and try again';

  Future<Response> getConnect(url, apiToken) async {
    print('getConnect url : ' + url.toString());
    try {
      dio.options.headers['content-Type'] = 'application/x-www-form-urlencoded';
      dio.options.connectTimeout = 30000; //5s
      dio.options.receiveTimeout = 25000;

      return await dio.post(url, cancelToken: apiToken);
    } on DioError catch (e) {
      // print(e.toString() + ' | ' + url.toString());

      if (e.type == DioErrorType.response) {
        int? statusCode = e.response!.statusCode;
        if (statusCode == 404) {
          throw "Api not found";
        } else if (statusCode == 500) {
          throw "Internal Server Error";
        } else {
          throw e.error.message.toString();
        }
      } else if (e.type == DioErrorType.connectTimeout) {
        throw e.message.toString();
      } else if (e.type == DioErrorType.cancel) {
        throw 'cancel';
      }
      throw connErr;
    } finally {
      dio.close();
    }
  }

  Future<Response> postConnect(url, data, apiToken) async {
    print('PostConnect url : ' + url.toString());
    print('postData : ' + data.toString());
    try {
      dio.options.headers['content-Type'] = 'application/x-www-form-urlencoded';
      dio.options.connectTimeout = 30000; //5s
      dio.options.receiveTimeout = 25000;

      return await dio.post(url, data: data, cancelToken: apiToken);
    } on DioError catch (e) {
      //print(e.toString()+' | '+url.toString());
      if (e.type == DioErrorType.response) {
        int? statusCode = e.response!.statusCode;
        if (statusCode == 404) {
          throw "Api not found";
        } else if (statusCode == 500) {
          throw "Internal Server Error";
        } else {
          throw e.error.message.toString();
        }
      } else if (e.type == DioErrorType.connectTimeout) {
        throw e.message.toString();
      } else if (e.type == DioErrorType.cancel) {
        throw 'cancel';
      }
      throw connErr;
    } finally {
      dio.close();
    }
  }

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
      throw response.data['message'];
    }
  }

  // Future<List<ProfileModel>> profil(
  //     String ip, String userID, String date, CancelToken apiToken) async {
  //   String uri = ip + '/profil/' + userID + '/' + date;
  //   try {
  //     var response = await dio.post(uri, cancelToken: apiToken);
  //     dio.options.headers['content-Type'] = 'application/x-www-form-urlencoded';
  //     dio.options.connectTimeout = 30000; //5s
  //     dio.options.receiveTimeout = 25000;

  //     if (response.statusCode == 200) {
  //       List responseList = response.data['data'];
  //       List<ProfileModel> listData =
  //           responseList.map((f) => ProfileModel.fromJson(f)).toList();
  //       return listData;
  //     } else {
  //       throw response.data['message'];
  //     }
  //   } on DioError catch (e) {
  //     //print(e.toString()+' | '+url.toString());
  //     if (e.type == DioErrorType.response) {
  //       int? statusCode = e.response!.statusCode;
  //       if (statusCode == 404) {
  //         throw "Api not found";
  //       } else if (statusCode == 500) {
  //         throw "Internal Server Error";
  //       } else {
  //         throw e.error.message.toString();
  //       }
  //     } else if (e.type == DioErrorType.connectTimeout) {
  //       throw e.message.toString();
  //     } else if (e.type == DioErrorType.cancel) {
  //       throw 'cancel';
  //     }
  //     throw connErr;
  //   } finally {
  //     dio.close();
  //   }
  // }

  Future<dynamic> profil(
      String ip, String userID, String date, apiToken) async {
    String url = ip + '/profil/' + userID + '/' + date;
    response = await dio.get(url);
    if (response.data['status'] == true) {
      return response.data['data'];
    } else {
      throw response.data['message'];
    }
  }

  Future<CheckKoneksiModel> checkKoneksi(ip) async {
    var response = await http.get(Uri.parse(ip + "/cek_con"));
    // print("Response Status : ${response.statusCode}");
    // print("Response Body : ${response.body}");
    if (response.statusCode == 200) {
      CheckKoneksiModel responseRequest =
          CheckKoneksiModel.fromJson(jsonDecode(response.body));
      return responseRequest;
    } else {
      throw response.statusCode.toString();
    }
  }

  Future<CheckStatusModel> checkStatus(ip, userID) async {
    var response = await http.get(Uri.parse(ip + '/check_in/' + userID));
    // print("Response CekStatus Status : ${response.statusCode}");
    // print("Response CekStatus Body : ${response.body}");
    if (response.statusCode == 200) {
      CheckStatusModel responseRequest =
          CheckStatusModel.fromJson(jsonDecode(response.body));
      return responseRequest;
    } else {
      throw response.statusCode.toString();
    }
  }

  Future<CheckHolidaysModel> checkHolidays(ip, userID) async {
    var response = await http.get(Uri.parse(ip + '/check_holidays/' + userID));
    // print('ip => ' + ip);
    // print('userId => ' + userID);
    // print("Response CekHolidays Status : ${response.statusCode}");
    // print("Response CekHolidays Body : ${response.body}");
    if (response.statusCode == 200) {
      CheckHolidaysModel responseBirthday =
          CheckHolidaysModel.fromJson(jsonDecode(response.body));
      return responseBirthday;
    } else {
      throw response.statusCode;
    }
  }
}
