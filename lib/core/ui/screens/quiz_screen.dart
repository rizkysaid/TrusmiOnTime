import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_tooltip/simple_tooltip.dart';

import '../../config/endpoint.dart';
import '../../database/database_helper.dart';
import '../../services/ApiService.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late String idQuestion;
  String question = '';
  List _options = [];
  late String userId;
  late String departmentId;
  late String url;
  final dbHelper = DatabaseHelper.instance;
  bool _isSnackbarActive = false;
  bool isQuizPasses = false;

  @override
  void initState() {
    super.initState();
    getPref();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> getPref() async {
    var pref = await SharedPreferences.getInstance();
    final allRows = await dbHelper.queryAllRows();
    if (allRows.length != 0) {
      setState(() {
        url = allRows[0]['ip_address'];
      });
    } else {
      setState(() {
        url = Endpoint.baseUrl;
      });
    }
    setState(() {
      userId = pref.getString('userID').toString();
      departmentId = pref.getString('departmentId').toString();
    });

    getQuestion(url, userId, departmentId);
  }

  Future<dynamic> getQuestion(url, userId, departmentId) async {
    showProgressDialog(context);
    ApiServices services = ApiServices();
    var response = await services.fetchQuestion(url, userId, departmentId);

    setState(() {
      idQuestion = response['id'].toString();
      question = response['question'].toString();
      _options = response['options'];
      jawaban = null;
    });

    _insertQuizTemp(idQuestion);

    // print(response['options'].toString());
  }

  String? jawaban;
  String? benar;
  List<RadioListTile> answersRadio = [];

  bool _isShowTooltip = false;

  void _cekJawaban() {
    // jika belum memilih jawaban
    if (jawaban == null || jawaban == "") {
      // jika keterangan belum memilih jawaban tidak muncul
      if (!_isSnackbarActive) {
        // munculkan keterangan belum memilih jawaban
        setState(() {
          _isSnackbarActive = true;
        });
        final snackBar = SnackBar(
          content:
              const Text('Kamu belum memilih jawaban. Pilih jawaban dulu ya!'),
          action: SnackBarAction(
            label: 'Tutup',
            onPressed: () {
              setState(() {
                _isSnackbarActive = false;
              });
            },
          ),
        );
        ScaffoldMessenger.of(context)
            .showSnackBar(snackBar)
            .closed
            .then((value) {
          setState(() {
            _isSnackbarActive = false;
          });
        });
      }
    } else {
      _insertQuiz(idQuestion, question, jawaban, benar);
    }
  }

  void _insertQuiz(idQuestion, question, jawaban, benar) async {
    showProgressDialog(context);
    var formData = FormData.fromMap({
      'employee_id': userId,
      'id_question': idQuestion,
      'question': question,
      'answer': jawaban,
      'status': benar,
    });

    Dio dio = new Dio();
    try {
      var response = await dio.post(Endpoint.insertQuiz, data: formData);

      if (response.data['status'] == true) {
        Navigator.pop(context);
        showSuccessDialog(context, benar);
        _deleteQuizTemp(userId);
      } else {
        // print(response.data['status']);
        // print(response.data['message']);
        // print('jawaban $benar');
      }
    } catch (e) {
      print(e.toString());
    }
  }

  void _insertQuizTemp(idQuestion) async {
    var formData = FormData.fromMap({
      'employee_id': userId,
      'id_question': idQuestion,
    });

    Dio dio = new Dio();
    try {
      var response = await dio.post(Endpoint.insertQuizTemp, data: formData);
      Navigator.pop(context);
      print('insert quiz temp ${response.data['status'].toString()}');
    } catch (e) {
      print(e.toString());
    }
  }

  void _deleteQuizTemp(usedId) async {
    Dio dio = new Dio();
    try {
      var response = await dio.delete('${Endpoint.insertQuizTemp}/$usedId');
      print('delete quiz temp ${response.data['status'].toString()}');
    } catch (e) {
      print(e.toString());
    }
  }

  showSuccessDialog(context, status) {
    late DialogType dialogType;
    late String title;
    late String desc;
    late String btnOkText;
    late Color btnColor;
    if (status == '0') {
      dialogType = DialogType.error;
      title = "Upss..";
      desc = "Jawaban kamu salah!";
      btnOkText = "Ulangi";
      btnColor = Color(0XFFFF0000);
    } else {
      dialogType = DialogType.success;
      title = "Selamat";
      desc = "Jawaban kamu benar";
      btnOkText = "Lanjutkan absen";
      btnColor = Colors.green;
    }

    return AwesomeDialog(
      context: context,
      dialogType: dialogType,
      animType: AnimType.bottomSlide,
      title: title,
      desc: desc,
      btnOkColor: btnColor,
      btnOkText: btnOkText,
      btnOkIcon:
          status == '0' ? Icons.refresh_outlined : Icons.camera_alt_outlined,
      btnOkOnPress: () async {
        if (benar == '0') {
          // Jika Salah => generate ulang Soal
          getPref();
        } else {
          // Jika Benar
          var pref = await SharedPreferences.getInstance();
          setState(() {
            pref.setBool('isQuizPasses', true);
          });
          Navigator.pop(context);
        }
      },
      dismissOnBackKeyPress: false,
      dismissOnTouchOutside: false,
    )..show();
  }

  Future showProgressDialog(BuildContext loadContext) {
    return showDialog(
      context: loadContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isShowTooltip = false;
        });
      },
      child: Scaffold(
        appBar: AppBar(
          iconTheme: new IconThemeData(
            color: Color.fromARGB(255, 240, 245, 249),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background_login.png'),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30.0),
                bottomRight: Radius.circular(30.0),
              ),
            ),
          ),
          leading: GestureDetector(
            onTap: () {
              if (!_isSnackbarActive) {
                Navigator.pop(context);
              }
            },
            child: Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: Icon(
                Icons.arrow_back_outlined,
              ),
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Row(
              children: [
                Text("Quiz"),
                SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    if (!_isShowTooltip) {
                      setState(() {
                        _isShowTooltip = true;
                      });
                    } else {
                      setState(() {
                        _isShowTooltip = false;
                      });
                    }
                  },
                  child: SimpleTooltip(
                    tooltipTap: () {
                      setState(() {
                        _isShowTooltip = false;
                      });
                    },
                    animationDuration: Duration(seconds: 1),
                    hideOnTooltipTap: true,
                    show: _isShowTooltip,
                    tooltipDirection: TooltipDirection.right,
                    child: Icon(
                      Icons.info,
                      color: Colors.white.withOpacity(0.8),
                      size: 18.0,
                    ),
                    backgroundColor: Colors.grey.shade900.withOpacity(0.3),
                    borderColor: Colors.grey.shade900.withOpacity(0.1),
                    arrowTipDistance: 3,
                    ballonPadding: EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    content: Text(
                      "Jawablah pertanyaan dengan benar untuk dapat melakukan absen pulang!",
                      style: TextStyle(
                        color: Color.fromARGB(255, 244, 240, 240),
                        fontSize: 12,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
          ),
          toolbarHeight: 120,
        ),
        body: Container(
          padding: const EdgeInsets.all(14.0),
          height: double.infinity,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    question,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                for (var n in _options)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.0),
                            border: Border.all(
                              color: jawaban == n['option']
                                  ? Color(0XFFFF0000)
                                  : Color(0XFF121212),
                              width: 1.0,
                            ),
                          ),
                          child: RadioListTile<String>(
                            activeColor: Color(0XFFFF0000),
                            value: n['option'],
                            groupValue: jawaban,
                            onChanged: (val) {
                              setState(() {
                                jawaban = val;
                              });
                              if (val != null) {
                                benar = n['status'];
                              } else {
                                benar = val;
                              }
                            },
                            title: Text(
                              n['option'],
                              style: TextStyle(fontSize: 14.0),
                            ),
                            toggleable: true,
                            selected: jawaban == n['option'],
                          ),
                        ),
                        SizedBox(
                          height: 20.0,
                        )
                      ],
                    ),
                  ),
                SizedBox(height: 70.0),
              ],
            ),
          ),
        ),
        floatingActionButtonLocation:
            FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 30.0, left: 50, right: 50),
          child: ElevatedButton(
            style: ButtonStyle(
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              minimumSize:
                  MaterialStateProperty.all(Size(double.infinity, 50)),
              backgroundColor:
                  MaterialStateProperty.all(Color.fromARGB(255, 212, 0, 0)),
              // elevation: MaterialStateProperty.all(3),
              shadowColor: MaterialStateProperty.all(Colors.redAccent),
            ),
            onPressed: () {
              _cekJawaban();
            },
            child: Padding(
              padding: const EdgeInsets.only(
                top: 10,
                bottom: 10,
              ),
              child: Text(
                "Submit",
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
        // bottomNavigationBar: BottomAppBar(
        //   shape: CircularNotchedRectangle(),
        //   notchMargin: 8.0,
        //   child: Row(
        //     mainAxisSize: MainAxisSize.max,
        //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //     children: <Widget>[
        //       IconButton(
        //         icon: Icon(Icons.menu),
        //         onPressed: () {
        //           // Do something when the menu button is pressed
        //         },
        //       ),
        //       IconButton(
        //         icon: Icon(Icons.search),
        //         onPressed: () {
        //           // Do something when the search button is pressed
        //         },
        //       ),
        //     ],
        //   ),
        // ),
      ),
    );
  }
}
