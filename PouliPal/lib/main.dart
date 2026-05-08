import 'package:flutter/material.dart';
import 'ui/chat_screen.dart';

void main() {
  runApp(const PouliPalApp());
}

class PouliPalApp extends StatelessWidget {
  const PouliPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PouliPal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      home: ChatScreen(),
    );
  }
}
