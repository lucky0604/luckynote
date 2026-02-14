import 'package:flutter/material.dart';

class NoteListLoading extends StatelessWidget {
  const NoteListLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
  }
}
