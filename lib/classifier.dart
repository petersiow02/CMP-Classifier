// classifier.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class Classifier {
  Interpreter? _interpreter;
  List<String> _labels = [];
  final int _inputSize = 224; // Model's expected input size

  Classifier();

  // Initialize the interpreter and load labels
  Future<void> initialize() async {
    try {
      // Load the TensorFlow Lite model
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');
      print("Interpreter loaded successfully.");

      // Load labels
      String labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData.split('\n').map((label) => label.trim()).toList();
      _labels.removeWhere((label) => label.isEmpty); // Remove any empty labels
      print("Labels loaded successfully. Total labels: ${_labels.length}");
    } catch (e) {
      print("Error during Classifier initialization: $e");
      rethrow; // Propagate the error to handle it in the UI
    }
  }

  // Getter to expose labels
  List<String> get labelsList => _labels;

  // Classify the given image
  Future<Map<String, dynamic>> classifyImage(File image) async {
    if (!isInitialized) {
      throw Exception("Classifier is not initialized.");
    }

    // Preprocess the image
    img.Image? imageInput = img.decodeImage(image.readAsBytesSync());
    if (imageInput == null) {
      throw Exception("Unable to decode image.");
    }

    // Resize the image to the required input size
    img.Image resizedImage = img.copyResize(imageInput, width: _inputSize, height: _inputSize);
    print("Image resized to $_inputSize x $_inputSize.");

    // Normalize the image and create a 4D input tensor
    List<List<List<List<double>>>> input = List.generate(
      1, // Batch size
      (batch) => List.generate(
        _inputSize, // Height
        (y) => List.generate(
          _inputSize, // Width
          (x) => [
            resizedImage.getPixel(x, y).r / 255.0, // Red
            resizedImage.getPixel(x, y).g / 255.0, // Green
            resizedImage.getPixel(x, y).b / 255.0, // Blue
          ],
        ),
      ),
    );
    print("Image data normalized and input tensor created.");

    // Prepare output buffer
    // Assuming output shape is [1, 21]
    List<List<double>> output = List.generate(
      1,
      (_) => List.filled(_labels.length, 0.0),
    );

    try {
      print("Running model inference...");
      // Run inference
      _interpreter!.run(input, output);
      print("Model inference completed.");
    } catch (e) {
      print("Error during model inference: $e");
      throw Exception("Failed to run model inference.");
    }

    // Process output to find the label with the highest probability
    double maxProb = -1.0;
    int predictedId = -1;
    for (int i = 0; i < _labels.length; i++) {
      if (output[0][i] > maxProb) {
        maxProb = output[0][i];
        predictedId = i;
      }
    }

    if (predictedId == -1) {
      throw Exception("Failed to get prediction.");
    }

    String predictedLabel = _labels[predictedId];
    double accuracy = maxProb;

    print("Prediction: ID=$predictedId, Label=$predictedLabel, Accuracy=$accuracy");

    return {
      'id': predictedId,
      'label': predictedLabel,
      'accuracy': accuracy,
    };
  }

  // Check if the classifier is initialized
  bool get isInitialized => _interpreter != null && _labels.isNotEmpty;

  void close() {
    _interpreter?.close();
  }
}
