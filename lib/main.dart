import 'package:bluetooth_pc_remote/ui/views/home_view.dart';
import 'package:flutter/material.dart';

void main() => runApp(Application());

class Application extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.dark,
      theme: ThemeData.dark().copyWith(
        primaryIconTheme: IconThemeData(
          color: Colors.white,
        ),
      ),
      home: HomeView(),
    );
  }
}
