import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class TFLiteService {
  late Interpreter interpreter;
  List<String> labels = [];

  Future<void> loadModel() async {
    try {
      interpreter =
          await Interpreter.fromAsset("assets/model/model.tflite");

      final labelData =
          await rootBundle.loadString("assets/model/labels.txt");

      labels = labelData
          .split('\n')
          .where((label) => label.trim().isNotEmpty)
          .toList();

      print("Model + labels loaded");

    } catch (e) {
      print("Load error: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> runModel(File imageFile) async {
    try {
      /// READ IMAGE
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception("Image decoding failed");
      }

      /// RESIZE
      img.Image resized =
          img.copyResize(image, width: 224, height: 224);

      /// NORMALIZE INPUT
      var input = List.generate(
        1,
        (_) => List.generate(
          224,
          (y) => List.generate(
            224,
            (x) {
              var pixel = resized.getPixel(x, y);
              return [
                pixel.r / 255.0,
                pixel.g / 255.0,
                pixel.b / 255.0
              ];
            },
          ),
        ),
      );

      /// OUTPUT
      var output =
          List.generate(1, (_) => List.filled(labels.length, 0.0));

      interpreter.run(input, output);

      /// FIND BEST RESULT
      double maxScore = 0;
      int maxIndex = 0;

      for (int i = 0; i < labels.length; i++) {
        if (output[0][i] > maxScore) {
          maxScore = output[0][i];
          maxIndex = i;
        }
      }

      print("Prediction: ${labels[maxIndex]} ($maxScore)");

      return {
        "label": labels[maxIndex],
        "confidence": maxScore
      };

    } catch (e) {
      print("Inference error: $e");

      return {
        "label": "Error",
        "confidence": 0.0
      };
    }
  }
}
