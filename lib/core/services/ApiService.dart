import 'dart:convert';

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
      dio.options.connectTimeout = 10000; //10s
      dio.options.receiveTimeout = 5000;

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
      dio.options.connectTimeout = 10000; //10s
      dio.options.receiveTimeout = 5000;

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

  Future<dynamic> login(ip, username, password, apiToken) async {
    String url = ip + '/login';
    var postData = {
      'username': username,
      'password': password,
    };
    // try {
    var response = await dio.post(url, data: postData, cancelToken: apiToken);
    // print(response.data['status']);
    if (response.data['status'] == true) {
      return response.data['data'];
    } else {
      throw "Username or password is not valid";
    }
    // } catch (e) {
    //   print("catch error login => " + response.data['message']);
    //   throw e.toString();
    // }
  }

  Future<dynamic> profil(ip, userID, date, apiToken) async {
    String url = ip + '/profil/' + userID + '/' + date;
    try {
      dio.options.headers['content-Type'] = 'application/x-www-form-urlencoded';
      dio.options.connectTimeout = 10000; //10s
      dio.options.receiveTimeout = 5000;
      response = await dio.get(url, cancelToken: apiToken);
      if (response.data['status'] == true) {
        return response.data['data'];
      } else {
        throw response.data['message'];
      }
    } catch (e) {
      throw e.toString();
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

  Future<dynamic> checkStatus(ip, userID, responseTime) async {
    var response =
        await http.get(Uri.parse(ip + '/check_in/' + userID)).timeout(
      // set response time here
      Duration(seconds: responseTime),
      onTimeout: () {
        return http.Response('timeout', 408);
      },
    );
    // print("Response CekStatus Status : ${response.statusCode}");
    // print("Response CekStatus Body : ${response.body}");
    if (response.statusCode == 200) {
      CheckStatusModel responseRequest =
          CheckStatusModel.fromJson(jsonDecode(response.body));
      return responseRequest;
    } else {
      return response.statusCode.toString();
    }
  }

  Future<dynamic> checkHolidays(ip, userID) async {
    try {
      var response = await dio.get(ip + '/check_holidays/' + userID);
      print('ip => ' + ip);
      print('userId => ' + userID);
      print("Response CekHolidays Status : ${response.data['status']}");
      print("Response CekHolidays Body : ${response.data}");
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<dynamic> checkBestBadEmployee(ip, userId) async {
    try {
      var dio = new Dio();
      // dio.options.headers['content-Type'] = 'application/x-www-form-urlencoded';
      dio.options.connectTimeout = 10000; //10s
      dio.options.receiveTimeout = 5000;
      var response = await dio.get(ip + '/check_bad_emp/' + userId);
      return response.data;
    } catch (e) {
      return null;
    } finally {
      dio.close();
    }
  }

  Future<dynamic> getBestMktRsp(ip) async {
    try {
      var url = '$ip/best_mkt_rsp';
      dio.options.connectTimeout = 10000; //10s
      dio.options.receiveTimeout = 10000;
      var response = await dio.get(url);
      return response.data;
    } catch (e) {
      throw e;
    }
  }
}
