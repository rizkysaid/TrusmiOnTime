import 'package:flutter/material.dart';
import 'package:flutter_webview_pro/webview_flutter.dart';

class Trusmiverse extends StatefulWidget {
  final String url;
  final String token;
  const Trusmiverse({Key? key, required this.url, required this.token})
      : super(key: key);

  @override
  State<Trusmiverse> createState() => _TrusmiverseState();
}

class _TrusmiverseState extends State<Trusmiverse> {
  int loadingPrecentage = 0;
  @override
  Widget build(BuildContext context) {
    String url = widget.url;
    String token = widget.token;

    // return Scaffold();

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            WebView(
              // initialUrl: url,
              javascriptMode: JavascriptMode.unrestricted,
              gestureNavigationEnabled: true,
              onWebViewCreated: (controller) {
                Map<String, String> headers = {
                  "Authorization": "Bearer $token"
                };
                controller.loadUrl(url, headers: headers);
              },
              onPageStarted: (String url) {
                print('Page started loading: $url');
                setState(() {
                  loadingPrecentage = 0;
                });
              },
              onProgress: (int progress) {
                print('Page progress: $progress');
                setState(() {
                  loadingPrecentage = progress;
                });
              },
              onPageFinished: (String url) {
                setState(() {
                  loadingPrecentage = 100;
                });
                print('Page finished loading: $url');
              },
            ),
            loadingPrecentage < 100
                ? Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    color: Colors.grey[100],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 15),
                          Text('${loadingPrecentage.toString()}%'),
                          SizedBox(height: 10),
                          Text('Loading, please wait...'),
                        ],
                      ),
                    ),
                  )
                : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
