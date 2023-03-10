import 'package:flutter/material.dart';

class QuizTooltip extends StatelessWidget {
  final Widget child;
  final String message;

  QuizTooltip({required this.child, required this.message});

  @override
  Widget build(BuildContext context) {
    final key = GlobalKey<State<Tooltip>>();
    return Tooltip(
      key: key,
      message: message,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTap(key),
        child: child,
      ),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.9),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.all(20),
      preferBelow: true,
      verticalOffset: 20,
      showDuration: Duration(seconds: 10),
    );
  }

  void _onTap(GlobalKey key) {
    final dynamic tooltip = key.currentState;
    tooltip?.ensureTooltipVisible();
  }
}
