import 'dart:convert';

CheckinModel checkinModelFromJson(String str) =>
    CheckinModel.fromJson(json.decode(str));

String checkinModelToJson(CheckinModel data) => json.encode(data.toJson());

class CheckinModel {
  bool status;
  String message;

  CheckinModel({
    required this.status,
    required this.message,
  });

  factory CheckinModel.fromJson(Map<String, dynamic> json) => CheckinModel(
        status: json["status"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
      };
}
