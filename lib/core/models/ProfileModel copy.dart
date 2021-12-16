import 'dart:convert';

ProfileModel profileModelFromJson(String str) =>
    ProfileModel.fromJson(json.decode(str));

String profileModelToJson(ProfileModel data) => json.encode(data.toJson());

class ProfileModel {
  ProfileModel({
    required this.status,
    required this.data,
    required this.message,
  });

  bool status;
  Data data;
  String message;

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
  Data({
    required this.userId,
    required this.nama,
    required this.idShift,
    required this.fotoProfil,
    required this.jabatan,
    required this.photoIn,
    required this.dateIn,
    required this.clockIn,
    required this.shiftIn,
    required this.dateOut,
    required this.clockOut,
    required this.shiftOut,
    required this.totalWork,
  });

  String userId;
  String nama;
  String idShift;
  String fotoProfil;
  String jabatan;
  String photoIn;
  String dateIn;
  String clockIn;
  String shiftIn;
  String dateOut;
  String clockOut;
  String shiftOut;
  String totalWork;

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        userId: json["user_id"],
        nama: json["nama"],
        idShift: json["id_shift"],
        fotoProfil: json["foto_profil"],
        jabatan: json["jabatan"],
        photoIn: json["photo_in"],
        dateIn: json["date_in"],
        clockIn: json["clock_in"],
        shiftIn: json["shift_in"],
        dateOut: json["date_out"],
        clockOut: json["clock_out"],
        shiftOut: json["shift_out"],
        totalWork: json["total_work"],
      );

  Map<String, dynamic> toJson() => {
        "user_id": userId,
        "nama": nama,
        "id_shift": idShift,
        "foto_profil": fotoProfil,
        "jabatan": jabatan,
        "photo_in": photoIn,
        "date_in": dateIn,
        "clock_in": clockIn,
        "shift_in": shiftIn,
        "date_out": dateOut,
        "clock_out": clockOut,
        "shift_out": shiftOut,
        "total_work": totalWork,
      };
}
