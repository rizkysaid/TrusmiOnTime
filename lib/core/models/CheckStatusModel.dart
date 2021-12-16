import 'dart:convert';

CheckStatusModel checkStatusModelFromJson(String str) =>
    CheckStatusModel.fromJson(json.decode(str));

String checkStatusModelToJson(CheckStatusModel data) =>
    json.encode(data.toJson());

class CheckStatusModel {
  CheckStatusModel({
    required this.status,
    required this.data,
  });

  bool status;
  Data data;

  factory CheckStatusModel.fromJson(Map<String, dynamic> json) =>
      CheckStatusModel(
        status: json["status"],
        data: Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "data": data.toJson(),
      };
}

class Data {
  Data({
    required this.aktif,
    required this.achive,
    required this.message,
  });

  String aktif;
  bool achive;
  String message;

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        aktif: json["aktif"],
        achive: json["achive"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "aktif": aktif,
        "achive": achive,
        "message": message,
      };
}
