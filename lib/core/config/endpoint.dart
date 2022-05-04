import 'package:shared_preferences/shared_preferences.dart';

class Endpoint {
  late String ip;

  // static String _baseIP = "http://103.39.50.142"; //public
<<<<<<< HEAD
  // static String _baseIP = "http://192.168.23.23"; //local
  static String _baseIP = "http://10.10.11.66"; //bali
  static String _hr = "http://192.168.23.23"; //HR
  static String _trusmiCorp = "http://103.39.50.138"; //TrusmiCorp

  // static String _baseURL = "$_baseIP/absensi2/api";
  static String _baseURL = "$_baseIP/trusmiontime/api";
=======
  static String _baseIP = "http://192.168.23.23"; //local
  // static String _baseIP = "http://10.10.11.66"; //bali
  // static String _trusmiCorp = "http://103.39.50.138"; //trusmicorppublic
  static String _trusmiCorp = "http://192.168.23.195"; //trusmicorplocal

  static String _baseURL = "$_baseIP/absensi2/api";
  // static String _baseURL = "$_baseIP/trusmiontime/api";
>>>>>>> 1e381f95f594126c439de8696796a344e8bf94e3
  static String login = "$_baseURL/login";
  static String checkin = "$_baseURL/check_in";
  static String checkout = "$_baseURL/check_out";
  static String profil = "$_baseURL/profil";
  static String cekCon = "$_baseURL/cek_con";
  static String baseUrl = "$_baseURL";
  static String baseIp = "$_baseIP";
<<<<<<< HEAD
  // static String urlFoto = "$_baseIP/hr_upload"; //trusmicorp
  static String urlFoto = "http://103.39.50.142/hr_upload"; //HR
=======
  static String urlFoto = "$_baseIP/hr_upload"; //trusmicorp
>>>>>>> 1e381f95f594126c439de8696796a344e8bf94e3
  static String urlGif = "$_baseIP/img";
  static String urlLottie = "$_baseIP/lottie/";
  static String urlProfile = "$_hr/hr/uploads/profile";
  static String breakout = "$_baseURL/break_out";
  static String breakin = "$_baseURL/break_in";
<<<<<<< HEAD
  static String hrSystem = "$_hr/hr/bypass/login2";
=======
  static String hrSystem = "$_baseIP/hr/bypass/login2";
>>>>>>> 1e381f95f594126c439de8696796a344e8bf94e3
  static String wfh = "$_trusmiCorp/wfh/login/auth";

  getIP() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    ip = pref.getString('IpAddress')!;
  }
}
