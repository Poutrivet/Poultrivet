import 'dart:io';
import 'package:flutter/material.dart';

class ScanResultPage extends StatelessWidget {
  final File image;

  const ScanResultPage({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Analysis Result"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            /// IMAGE PREVIEW
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(image, height: 250),
            ),

            const SizedBox(height: 20),

            /// RESULT CARD (placeholder for now)
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.health_and_safety,
                        size: 40, color: Colors.green),
                    SizedBox(height: 10),
                    Text(
                      "Analyzing...",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Please wait while we process the image",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}