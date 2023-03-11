import 'package:shared_preferences/shared_preferences.dart';

class Endpoint {
  late String ip;

  // static String _baseIP = "http://103.39.50.142"; //public
  static String _baseIP = "http://192.168.23.23"; //local
  // static String _baseIP = "http://10.10.11.66"; //bali
  // static String _trusmiCorp = "http://103.39.50.138"; //trusmicorppublic
  static String _trusmiCorp = "http://192.168.23.195"; //trusmicorplocal

  static String _baseURL = "$_baseIP/absensi2/api";
  // static String _baseURL = "$_baseIP/trusmiontime/api";
  static String login = "$_baseURL/login";
  static String checkin = "$_baseURL/check_in";
  static String checkout = "$_baseURL/check_out";
  static String profil = "$_baseURL/profil";
  static String cekCon = "$_baseURL/cek_con";
  static String baseUrl = "$_baseURL";
  static String baseIp = "$_baseIP";
  static String urlFoto = "$_baseIP/hr_upload"; //trusmicorp
  static String urlGif = "$_baseIP/img";
  static String urlLottie = "$_baseIP/lottie/";
  static String urlProfile = "$_baseIP/hr/uploads/profile";
  static String breakout = "$_baseURL/break_out";
  static String breakin = "$_baseURL/break_in";
  static String hrSystem = "$_baseIP/hr/bypass/login2";
  static String wfh = "$_trusmiCorp/wfh/login/auth";
  static String bestMktRsp = "$_baseURL/best_mkt_rsp";
  static String insertQuiz = "$_baseURL/insert_quiz";
  static String insertQuizTemp = "$_baseURL/insert_quiz_temp";

  getIP() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    ip = pref.getString('IpAddress')!;
  }
}
