import 'package:flutter/material.dart';
import 'package:flutter_webview_pro/webview_flutter.dart';

class Trusmiverse extends StatefulWidget {
  final String url;
  const Trusmiverse({Key? key, required this.url}) : super(key: key);

  @override
  State<Trusmiverse> createState() => _TrusmiverseState();
}

class _TrusmiverseState extends State<Trusmiverse> {
  @override
  Widget build(BuildContext context) {
    String url = widget.url;
    // double progress = 0;
    bool _loading = true;
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          WebView(
            initialUrl: url,
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
  }
}
