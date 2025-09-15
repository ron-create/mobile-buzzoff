import 'package:flutter/material.dart';

class Responsive {
  static double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  static double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;

  static double font(BuildContext context, double size) {
    // Base size is for 375px width (iPhone 11/12/13/14)
    double baseWidth = 375.0;
    return size * (screenWidth(context) / baseWidth);
  }

  static double padding(BuildContext context, double value) {
    double baseWidth = 375.0;
    return value * (screenWidth(context) / baseWidth);
  }

  static double icon(BuildContext context, double size) {
    double baseWidth = 375.0;
    return size * (screenWidth(context) / baseWidth);
  }

  // For vertical spacing
  static double vertical(BuildContext context, double value) {
    double baseHeight = 812.0;
    return value * (screenHeight(context) / baseHeight);
  }

  // For horizontal spacing
  static double horizontal(BuildContext context, double value) {
    double baseWidth = 375.0;
    return value * (screenWidth(context) / baseWidth);
  }
} 