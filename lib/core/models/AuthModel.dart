import 'dart:convert';

AuthModel authModelFromJson(String str) => AuthModel.fromJson(json.decode(str));

String authModelToJson(AuthModel data) => json.encode(data.toJson());

class AuthModel {
  bool status;
  String message;
  List<Datum> data;

  AuthModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) => AuthModel(
        status: json["status"],
        message: json["message"],
        data: List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
      };
}

class Datum {
  String username;
  String password;
  String userId;

  Datum({
    required this.username,
    required this.password,
    required this.userId,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        username: json["username"],
        password: json["password"],
        userId: json["user_id"],
      );

  Map<String, dynamic> toJson() => {
        "username": username,
        "password": password,
        "user_id": userId,
      };
}
