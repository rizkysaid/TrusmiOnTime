// To parse this JSON data, do
//
//     final checkHolidaysModel = checkHolidaysModelFromJson(jsonString);

import 'dart:convert';

CheckHolidaysModel checkHolidaysModelFromJson(String str) =>
    CheckHolidaysModel.fromJson(json.decode(str));

String checkHolidaysModelToJson(CheckHolidaysModel data) =>
    json.encode(data.toJson());

class CheckHolidaysModel {
  CheckHolidaysModel({
    required this.status,
    required this.data,
    required this.title,
    required this.message,
    required this.gif,
  });

  bool status;
  List<Datum> data;
  String title;
  String message;
  String gif;

  factory CheckHolidaysModel.fromJson(Map<String, dynamic> json) =>
      CheckHolidaysModel(
        status: json["status"],
        data: List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
        title: json["title"],
        message: json["message"],
        gif: json["gif"],
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
        "title": title,
        "message": message,
        "gif": gif,
      };
}

class Datum {
  Datum({
    required this.hbdName,
    required this.hbdAge,
    required this.hbdDate,
    required this.holidayEvent,
    required this.holidayStartdate,
    required this.holidayEnddate,
  });

  String hbdName;
  String hbdAge;
  String hbdDate;
  String holidayEvent;
  String holidayStartdate;
  String holidayEnddate;

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        hbdName: json["hbd_name"],
        hbdAge: json["hbd_age"],
        hbdDate: json["hbd_date"],
        holidayEvent: json["holiday_event"],
        holidayStartdate: json["holiday_startdate"],
        holidayEnddate: json["holiday_enddate"],
      );

  Map<String, dynamic> toJson() => {
        "hbd_name": hbdName,
        "hbd_age": hbdAge,
        "hbd_date": hbdDate,
        "holiday_event": holidayEvent,
        "holiday_startdate": holidayStartdate,
        "holiday_enddate": holidayEnddate,
      };
}
