import 'package:shared_preferences/shared_preferences.dart';

class Endpoint{
  String ip;

 static String _baseIP = "http://103.39.50.142"; //public
//   static String _baseIP = "http://192.168.23.23"; //local

  static String _baseURL = "$_baseIP/absensi2/api/";
  static String login = "$_baseURL/login";
  static String checkin = "$_baseURL/check_in";
  static String checkout = "$_baseURL/check_out";
  static String profil = "$_baseURL/profil";
  static String cek_con = "$_baseURL/cek_con";
  static String base_url = "$_baseURL";
  static String base_ip = "$_baseIP";
  static String url_foto = "$_baseIP/hr_upload";
 static String url_gif = "$_baseIP/img";
  static String url_profile = "$_baseIP/hr/uploads/profile/";

  getIP()async{
    SharedPreferences pref = await SharedPreferences.getInstance();
    ip = pref.getString('IpAddress');

  }
}
