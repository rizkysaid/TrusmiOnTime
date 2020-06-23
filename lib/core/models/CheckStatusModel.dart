// To parse this JSON data, do
//
//     final checkStatusModel = checkStatusModelFromJson(jsonString);

import 'dart:convert';

CheckStatusModel checkStatusModelFromJson(String str) => CheckStatusModel.fromJson(json.decode(str));

String checkStatusModelToJson(CheckStatusModel data) => json.encode(data.toJson());

class CheckStatusModel {
  CheckStatusModel({
    this.status,
    this.data,
  });

  bool status;
  Data data;

  factory CheckStatusModel.fromJson(Map<String, dynamic> json) => CheckStatusModel(
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
    this.aktif,
  });

  String aktif;

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    aktif: json["aktif"],
  );

  Map<String, dynamic> toJson() => {
    "aktif": aktif,
  };
}
