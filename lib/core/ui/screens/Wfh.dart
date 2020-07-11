import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:login_absen/core/ui/screens/PassParams.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

bool _saving = true;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(new Wfh());
}

class Wfh extends StatefulWidget {


  @override
  _WfhState createState() => new _WfhState();
}

class _WfhState extends State<Wfh> {

  InAppWebViewController webView;
  String url = "";
  double progress = 0;

  @override
  void initState(){
    super.initState();
    setState(() {
      _saving = true;
    });

  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PassParams args = ModalRoute.of(context).settings.arguments;
    String username = args.username;
    String password = args.password;
    String urlAbsen = "https://trusmicorp.com/wfh/login/auth/"+username.toString()+"/"+password.toString();

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
                      initialUrl: urlAbsen,
                      initialHeaders: {},
                      initialOptions: InAppWebViewGroupOptions(
                          crossPlatform: InAppWebViewOptions(
                            debuggingEnabled: true,
                          )
                      ),
                      onWebViewCreated: (InAppWebViewController controller) {
                        webView = controller;
                      },
                      onLoadStart: (InAppWebViewController controller, String url) {
                        setState(() {
                          this.url = url;
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
                Container(
                    padding: EdgeInsets.all(10.0),
                    child: progress < 1.0
                        ? LinearProgressIndicator(value: progress)
                        : Container()),
//              ButtonBar(
//                alignment: MainAxisAlignment.center,
//                children: <Widget>[
//                  RaisedButton(
//                    child: Icon(Icons.arrow_back),
//                    onPressed: () {
//                      if (webView != null) {
//                        webView.goBack();
//                      }
//                    },
//                  ),
//                  RaisedButton(
//                    child: Icon(Icons.arrow_forward),
//                    onPressed: () {
//                      if (webView != null) {
//                        webView.goForward();
//                      }
//                    },
//                  ),
//                  RaisedButton(
//                    child: Icon(Icons.refresh),
//                    onPressed: () {
//                      if (webView != null) {
//                        webView.reload();
//                      }
//                    },
//                  ),
//                ],
//              ),
              ])),
        ),
      ),
    );
  }
}