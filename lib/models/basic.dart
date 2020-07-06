import 'package:flutter/material.dart';

class IconLabel {
  IconLabel(this.icon, this.label, {this.value, this.color, this.total});
  final IconData icon;
  final String label;
  final dynamic value;
  final Color color;
  final int total;

  @override
  String toString() => label;

  @override
  bool operator ==(Object other) => identical(this, other) ||
    (other is IconLabel && runtimeType == other.runtimeType && other.icon == icon && other.label == label);
}