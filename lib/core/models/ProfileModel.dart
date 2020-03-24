// To parse this JSON data, do
//
//     final profileModel = profileModelFromJson(jsonString);

import 'dart:convert';

ProfileModel profileModelFromJson(String str) => ProfileModel.fromJson(json.decode(str));

String profileModelToJson(ProfileModel data) => json.encode(data.toJson());

class ProfileModel {
  bool status;
  Data data;
  String message;

  ProfileModel({
    this.status,
    this.data,
    this.message,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
    status: json["status"],
    data: Data.fromJson(json["data"]),
    message: json["message"],
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "data": data.toJson(),
    "message": message,
  };
}

class Data {
  String userId;
  String nama;
  String fotoProfil;
  String jabatan;
  String photoIn;
  String clockIn;
  String clockOut;
  String totalWork;

  Data({
    this.userId,
    this.nama,
    this.fotoProfil,
    this.jabatan,
    this.photoIn,
    this.clockIn,
    this.clockOut,
    this.totalWork,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    userId: json["user_id"],
    nama: json["nama"],
    fotoProfil: json["foto_profil"],
    jabatan: json["jabatan"],
    photoIn: json["photo_in"],
    clockIn: json["clock_in"],
    clockOut: json["clock_out"],
    totalWork: json["total_work"],
  );

  Map<String, dynamic> toJson() => {
    "user_id": userId,
    "nama": nama,
    "foto_profil": fotoProfil,
    "jabatan": jabatan,
    "photo_in": photoIn,
    "clock_in": clockIn,
    "clock_out": clockOut,
    "total_work": totalWork,
  };
}
