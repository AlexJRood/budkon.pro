// tms_app/todo/view/model/member_lite_model.dart

import 'package:flutter/material.dart';

@immutable
class MemberLite {
  final int id;
  final String name;
  final String? email;
  final String? avatar;

  const MemberLite({
    required this.id,
    required this.name,
    this.email,
    this.avatar,
  });
}
