import 'package:flutter/material.dart';

class IconLabel {
  IconLabel(this.icon, this.label, {this.value, this.color, this.total});
  final IconData icon;
  final String label;
  final dynamic value;
  final Color color;
  final int total;
}