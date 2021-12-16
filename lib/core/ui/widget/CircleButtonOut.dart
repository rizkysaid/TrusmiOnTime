// import 'package:flutter/material.dart';

// class CircleButtonOut extends StatelessWidget {
//   final String text;
//   final Function onClick;

//   CircleButtonOut({@required this.text, @required this.onClick});

//   @override
//   Widget build(BuildContext context) {
//     double circleBoxSize = 90.0;
//     return new Column(
//       children: <Widget>[
//         ElevatedButton(
//           // splashColor: Colors.transparent,
//           // highlightColor: Colors.transparent,
//           onPressed: onClick,
//           child: new Container(
//             width: circleBoxSize,
//             height: circleBoxSize,
//             decoration: new BoxDecoration(
//               gradient: LinearGradient(
//                   begin: Alignment.bottomLeft,
//                   end: Alignment.topRight,
//                   colors: [
//                     Color.fromRGBO(0, 219, 57, 1),
//                     Color.fromRGBO(80, 240, 97, 1)
//                   ]),
//               shape: BoxShape.circle,
//               color: Color.fromRGBO(227, 230, 238, 1),
//             ),
//             child: Icon(
//               Icons.stop,
//               color: Colors.white,
//               size: 50,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
