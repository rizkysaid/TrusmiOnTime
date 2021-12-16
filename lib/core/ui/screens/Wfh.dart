import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:login_absen/core/ui/screens/PassParams.dart';
import 'package:webview_flutter/webview_flutter.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(new Wfh());
}

class Wfh extends StatefulWidget {
  @override
  _WfhState createState() => new _WfhState();
}

class _WfhState extends State<Wfh> {
  // InAppWebViewController webView;
  String url = "";
  double progress = 0;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as PassParams;
    String username = args.username;
    String password = args.password;
    String urlAbsen = "https://trusmicorp.com/wfh/login/auth/" +
        username.toString() +
        "/" +
        password.toString();
//  static String _baseIP = "http://192.168.23.195"; //wfh - local
//     String urlAbsen = "http://192.168.23.195/wfh/login/auth/"+username.toString()+"/"+password.toString();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          WebView(
            initialUrl: urlAbsen,
            javascriptMode: JavascriptMode.unrestricted,
            gestureNavigationEnabled: true,
            onPageStarted: (String url) {
              print('Page started loading: $url');
            },
            onPageFinished: (String url) {
              setState(() {
                _loading = false;
              });
              print('Page finished loading: $url');
            },
          ),
          (_loading)
              ? Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  color: Colors.grey[100],
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : SizedBox.shrink(),
        ],
      ),
    );

    // return MaterialApp(
    //   debugShowCheckedModeBanner: false,
    //   home: Scaffold(
    //     body: ModalProgressHUD(
    //       inAsyncCall: _saving,
    //       child: Container(
    //           child: Column(children: <Widget>[
    //             Expanded(
    //               child: Container(
    //                 child: InAppWebView(
    //                   initialUrl: urlAbsen,
    //                   initialHeaders: {},
    //                   initialOptions: InAppWebViewGroupOptions(
    //                       crossPlatform: InAppWebViewOptions(
    //                         debuggingEnabled: true,
    //                       )
    //                   ),
    //                   onWebViewCreated: (InAppWebViewController controller) {
    //                     webView = controller;
    //                   },
    //                   onLoadStart: (InAppWebViewController controller, String url) {
    //                     setState(() {
    //                       this.url = url;
    //                     });
    //                   },
    //                   onLoadStop: (InAppWebViewController controller, String url) async {
    //                     setState(() {
    //                       this.url = url;
    //                       _saving = false;
    //                     });
    //                   },
    //                   onProgressChanged: (InAppWebViewController controller, int progress) {
    //                     setState(() {
    //                       this.progress = progress / 100;
    //                     });
    //                   },
    //                 ),
    //               ),
    //             ),
    //             Container(
    //                 child: progress < 1.0
    //                     ? LinearProgressIndicator(value: progress)
    //                     : Container()),
    //           ])),
    //     ),
    //   ),
    // );
  }
}
