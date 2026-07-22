import 'package:flutter/material.dart';
import '../data/models/odbiory_model.dart';

class ProtokolStatusBadge extends StatelessWidget {
  final StatusProtokolu status;
  const ProtokolStatusBadge(this.status, {super.key});

  (Color, Color) get _colors => switch (status) {
        StatusProtokolu.roboczy => (Colors.white, const Color(0xFF3A3A3A)),
        StatusProtokolu.do_podpisu => (Colors.white, const Color(0xFF7B5E00)),
        StatusProtokolu.podpisany => (Colors.white, const Color(0xFF1E7A3A)),
        StatusProtokolu.odrzucony => (Colors.white, const Color(0xFF7B1F1F)),
      };

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status.label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
