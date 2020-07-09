import 'package:shared_preferences/shared_preferences.dart';

class Endpoint{
  String ip;
  static String _baseURL = "http://192.168.23.23/absensi2/api";
//  static String _baseURL = "http://trusmicorp.com/absensi/api";
//  static String _baseURL = "http://103.39.50.142/absensi2/api/";
  static String login = "$_baseURL/login";
  static String checkin = "$_baseURL/check_in";
  static String checkout = "$_baseURL/check_out";
  static String profil = "$_baseURL/profil";
  static String cek_con = "$_baseURL/cek_con";
  static String base_url = "$_baseURL";

  getIP()async{
    SharedPreferences pref = await SharedPreferences.getInstance();
    ip = pref.getString('IpAddress');

  }
}
