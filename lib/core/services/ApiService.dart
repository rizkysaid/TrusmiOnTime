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
      dio.options.connectTimeout = 10000 as Duration?; //10s
      dio.options.receiveTimeout = 5000 as Duration?;

      return await dio.post(url, cancelToken: apiToken);
    } on DioException catch (e) {
      // print(e.toString() + ' | ' + url.toString());

      if (e.type == DioExceptionType.badResponse) {
        int? statusCode = e.response!.statusCode;
        if (statusCode == 404) {
          throw "Api not found";
        } else if (statusCode == 500) {
          throw "Internal Server Error";
        } else {
          throw e.error.toString();
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw e.message.toString();
      } else if (e.type == DioExceptionType.cancel) {
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
      dio.options.connectTimeout = 10000 as Duration?; //10s
      dio.options.receiveTimeout = 5000 as Duration?;

      return await dio.post(url, data: data, cancelToken: apiToken);
    } on DioException catch (e) {
      //print(e.toString()+' | '+url.toString());
      if (e.type == DioExceptionType.badResponse) {
        int? statusCode = e.response!.statusCode;
        if (statusCode == 404) {
          throw "Api not found";
        } else if (statusCode == 500) {
          throw "Internal Server Error";
        } else {
          throw e.error.toString();
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw e.message.toString();
      } else if (e.type == DioExceptionType.cancel) {
        throw 'cancel';
      }
      throw connErr;
    } finally {
      dio.close();
    }
  }

  Future<dynamic> login(ip, username, password, fcmToken, apiToken) async {
    String url = ip + '/login';
    var postData = {
      'username': username,
      'password': password,
      'fcmToken': fcmToken,
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
      // dio.options.connectTimeout = 30000; //10s
      // dio.options.receiveTimeout = 5000;
      response = await dio.get(url, cancelToken: apiToken);
      if (response.data['status'] == true) {
        return response.data['data'];
      } else {
        throw response.data['message'];
      }
    } catch (e) {
      return e.toString();
      // throw "Terjadi kesalahan";
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
      // print('ip => ' + ip);
      // print('userId => ' + userID);
      // print("Response CekHolidays Status : ${response.data['status']}");
      // print("Response CekHolidays Body : ${response.data}");
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<dynamic> checkBestBadEmployee(ip, userId) async {
    try {
      var dio = new Dio();
      // dio.options.headers['content-Type'] = 'application/x-www-form-urlencoded';
      dio.options.connectTimeout = 10000 as Duration?; //10s
      dio.options.receiveTimeout = 5000 as Duration?;
      var response = await dio.get(ip + '/check_bad_emp/' + userId);
      return response.data;
    } catch (e) {
      return null;
    }
    // finally {
    //   dio.close();
    // }
  }

  Future<dynamic> getBestMktRsp(ip, apiToken) async {
    try {
      var url = '$ip/best_mkt_rsp';
      dio.options.connectTimeout = 10000 as Duration?; //10s
      dio.options.receiveTimeout = 10000 as Duration?;
      // var response = await dio.get(url);
      var response = await dio.get(url, cancelToken: apiToken);
      return response.data;
    } catch (e) {
      return null;
    }
  }

  // QUESTION
  Future<dynamic> fetchQuestion(url, userId, departmentId) async {
    final uri = Uri.parse('$url/quiz');
    var map = new Map<String, dynamic>();
    map['user_id'] = userId;
    map['department_id'] = departmentId;
    return http.post(uri, body: map).then((response) {
      try {
        var data = json.decode(response.body);
        // var question = QuestionModel(
        //   id: data['id'],
        //   question: data['question'],
        //   options: Map.fromEntries(data['options']),
        // );

        return data;
      } catch (e) {
        throw e.toString();
      }
    });
  }
  // QUESTION

  // TRUSMIVERSE
  Future<dynamic> trusmiverseLogin(username, password, apiToken) async {
    try {
      var url = "http://trusmiverse.com/apps/login/auth_api";
      var formData = FormData.fromMap({
        'username': username,
        'password': password,
      });
      var response = await dio.post(url, data: formData, cancelToken: apiToken);
      return response;
      // if (response.data['result']) {
      //   return response.data['link'];
      // } else {
      //   throw "Username or password is not valid";
      // }
    } catch (e) {
      return null;
    }
  }
  // TRUSMIVERSE


  // FCM TOKEN
  Future<dynamic> updateFcmToken(url, userId, fireBaseToken, apiToken) async {
    final uri = Uri.parse('$url/fcm_token');
    var map = new Map<String, dynamic>();
    map['user_id'] = userId;
    map['token'] = fireBaseToken;
    return http.post(uri, body: map).then((response) {
      try {
        var data = json.decode(response.body);
        // var question = QuestionModel(
        //   id: data['id'],
        //   question: data['question'],
        //   options: Map.fromEntries(data['options']),
        // );

        return data;
      } catch (e) {
        throw e.toString();
      }
    });
  }
}
