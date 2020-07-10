import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool _saving = false;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(new HistoryAbsen());
}

class HistoryAbsen extends StatefulWidget {
  @override
  _HistoryAbsenState createState() => new _HistoryAbsenState();
}

class _HistoryAbsenState extends State<HistoryAbsen> {

  InAppWebViewController webView;
  String url = "";
  double progress = 0;

  String username = '';
  String password = '';

  @override
  void initState() {
    super.initState();
    getPref();
    setState(() {
      _saving = true;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void getPref() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      username = pref.getString('username');
      password = pref.getString('password');
    });

  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: ModalProgressHUD(
          inAsyncCall: _saving,
          child: Container(
              child: Column(children: <Widget>[
                Expanded(
                  child: Container(
                    child: InAppWebView(
                      initialUrl: "http://192.168.23.23/hr/bypass/login/"+username+"/"+password,
                      initialHeaders: {},
//                    initialOptions: InAppWebViewGroupOptions(
//                        crossPlatform: InAppWebViewOptions(
//                          debuggingEnabled: true,
//                        )
//                    ),
                      onWebViewCreated: (InAppWebViewController controller) {
                        webView = controller;
                        _saving = true;
                      },
                      onLoadStart: (InAppWebViewController controller, String url) {
                        setState(() {
                          this.url = url;
                          _saving = true;
                        });
                      },
                      onLoadStop: (InAppWebViewController controller, String url) async {
                        setState(() {
                          this.url = url;
                          _saving = false;
                        });
                      },
                      onProgressChanged: (InAppWebViewController controller, int progress) {
                        setState(() {
                          this.progress = progress / 100;
                        });
                      },
                    ),
                  ),
                ),
              ]
              )
          ),
        ),
        bottomNavigationBar:
        BottomAppBar(
          shape: const CircularNotchedRectangle(),
          child: Container(height: 50.0),
        ),
        floatingActionButton:
        Container(
            height: 80,
            width: 80,
            child: FloatingActionButton(
              onPressed: () => {
              Future.delayed(const Duration(microseconds: 2000), () {
                Navigator.pushNamedAndRemoveUntil(
                  context, "/profile", (Route<dynamic> routes) => false);
                })
              },
              backgroundColor: Colors.red,
              child: Icon(Icons.chevron_left, color: Colors.white, size: 40),
            )
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}