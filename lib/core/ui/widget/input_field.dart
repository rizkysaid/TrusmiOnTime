// import 'package:flutter/material.dart';

// class InputField extends StatelessWidget {
//   final TextEditingController controller;
//   final TextInputAction action;
//   final TextInputType type;
//   final String hintText;
//   final bool secureText;
//   final bool readOnly;
//   final Function onTap;

//   InputField(
//       {required this.controller,
//       required this.action,
//       required this.type,
//       required this.hintText,
//       required this.secureText = false,
//       required this.onTap,
//       required this.readOnly = false});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//         decoration: BoxDecoration(
//           color: Colors.grey.withOpacity(0.2),
//           shape: BoxShape.rectangle,
//           borderRadius: BorderRadius.circular(6),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.only(left: 10, right: 10),
//           child: TextField(
//             controller: controller,
//             onTap: () => onTap != null ? onTap() : {},
//             // textInputAction: action,
//             textInputAction: TextInputAction.next,
//             keyboardType: type,
//             obscureText: secureText,
//             readOnly: readOnly,
//             decoration: InputDecoration(
//               hintText: hintText,
//               border: InputBorder.none,
//             ),
//           ),
//         ));
//   }
// }
