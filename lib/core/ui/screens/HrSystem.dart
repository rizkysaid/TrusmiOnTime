import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:login_absen/core/config/endpoint.dart';
import 'package:login_absen/core/ui/screens/PassParams.dart';
import 'package:flutter_webview_pro/webview_flutter.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(new HrSystem());
}

class HrSystem extends StatefulWidget {
  @override
  _HrSystemState createState() => new _HrSystemState();
}

class _HrSystemState extends State<HrSystem> {
  // InAppWebViewController webView;
  String url = "";
  double progress = 0;

  bool _loading = true;

  @override
  void initState() {
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
    super.initState();
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
    String urlAbsen = Endpoint.hrSystem +
        "?a=" +
        username.toString() +
        "&z=" +
        password.toString();
    print("ip=" + urlAbsen);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // WebView(
          //   initialUrl: urlAbsen,
          //   javascriptMode: JavascriptMode.unrestricted,
          //   gestureNavigationEnabled: true,
          //   onPageStarted: (String url) {
          //     print('Page started loading: $url');
          //   },
          //   onPageFinished: (String url) {
          //     setState(() {
          //       _loading = false;
          //     });
          //     print('Page finished loading: $url');
          //   },
          // ),
          // (_loading)
          //     ? Container(
          //         width: MediaQuery.of(context).size.width,
          //         height: MediaQuery.of(context).size.height,
          //         color: Colors.grey[100],
          //         child: Center(
          //           child: CircularProgressIndicator(),
          //         ),
          //       )
          //     : SizedBox.shrink(),

          // WebViewX(
          //   initialContent: urlAbsen,
          //   initialSourceType: SourceType.url,
          //   height: MediaQuery.of(context).size.height,
          //   width: MediaQuery.of(context).size.width,
          //   onPageFinished: (String url) {
          //     setState(() {
          //       _loading = false;
          //     });
          //   },
          // ),
          // (_loading)
          //     ? Container(
          //         width: MediaQuery.of(context).size.width,
          //         height: MediaQuery.of(context).size.height,
          //         color: Colors.grey[100],
          //         child: Center(
          //           child: CircularProgressIndicator(),
          //         ),
          //       )
          //     : SizedBox.shrink(),

          // WebViewPlus(
          //   javascriptMode: JavascriptMode.unrestricted,
          //   onWebViewCreated: (controller){
          //     controller.loadUrl(urlAbsen);
          //   },
          // ),

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
    //         Expanded(
    //           child: Container(
    //             child: InAppWebView(
    //               initialUrl: urlAbsen,
    //               initialHeaders: {},
    //               initialOptions: InAppWebViewGroupOptions(
    //                   crossPlatform: InAppWebViewOptions(
    //                 debuggingEnabled: true,
    //               )),
    //               onWebViewCreated: (InAppWebViewController controller) {
    //                 webView = controller;
    //               },
    //               onLoadStart: (InAppWebViewController controller, String url) {
    //                 setState(() {
    //                   this.url = url;
    //                 });
    //               },
    //               onLoadStop:
    //                   (InAppWebViewController controller, String url) async {
    //                 setState(() {
    //                   this.url = url;
    //                   _saving = false;
    //                 });
    //               },
    //               onProgressChanged:
    //                   (InAppWebViewController controller, int progress) {
    //                 setState(() {
    //                   this.progress = progress / 100;
    //                 });
    //               },
    //             ),
    //           ),
    //         ),
    //         Container(
    //             child: progress < 1.0
    //                 ? LinearProgressIndicator(value: progress)
    //                 : Container()),
    //       ],
    //       ),
    //       ),
    //     ),
    //   ),
    // );
  }
}
