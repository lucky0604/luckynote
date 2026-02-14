import 'package:flutter/material.dart';

class ChatBannerContainer extends StatelessWidget {
  const ChatBannerContainer({
    super.key,
    required this.backgroundColor,
    required this.child,
  });

  final Color backgroundColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: backgroundColor,
      child: child,
    );
  }
}
