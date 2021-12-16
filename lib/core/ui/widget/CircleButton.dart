// import 'package:flutter/material.dart';

// class CircleButton extends StatelessWidget {
//   final String text;
//   final Function onClick;

//   CircleButton({
//     @required this.text,
//     @required this.onClick,
//   });

//   @override
//   Widget build(BuildContext context) {
//     double circleBoxSize = 90.0;
//     return new Column(
//       children: <Widget>[
//         TextButton(
//           onPressed: onClick,
//           child: new Container(
//             width: circleBoxSize,
//             height: circleBoxSize,
//             decoration: new BoxDecoration(
//               gradient: LinearGradient(
//                   begin: Alignment.bottomLeft,
//                   end: Alignment.topRight,
//                   colors: [
//                     Color.fromRGBO(79, 172, 254, 1),
//                     Color.fromRGBO(0, 242, 245, 1)
//                   ]),
//               shape: BoxShape.circle,
//               color: Color.fromRGBO(227, 230, 238, 1),
//             ),
//             child: Icon(
//               Icons.alarm_on,
//               color: Colors.white,
//               size: 50,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
