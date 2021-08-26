import 'package:flutter/material.dart';
import 'package:gmap/pages/Home.dart';

void main() {
  runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        "/" : (context) => Home()
      },
  ));
}
